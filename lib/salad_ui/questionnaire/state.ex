defmodule SaladUI.Questionnaire.State do
  @moduledoc """
  Server-side step state for `SaladUI.Questionnaire`.

  A questionnaire form always posts everything the server needs to work out the
  next step: every answer (inactive items stay in the DOM, so their inputs are
  submitted too), the active item and skipped items (hidden
  `_questionnaire[item]` / `_questionnaire[skipped][]` inputs), and the action
  that was pressed (`_questionnaire[action]` on the Previous / Skip / Next /
  Submit buttons). `update/2` turns those params into the next state, so the
  same handler serves a LiveView `phx-submit`, a plain controller `POST` with
  JavaScript disabled, and the JavaScript hook's own submissions.

      @items [
        %{name: "direction", required: true, choices: ~w(delegation questions both)},
        %{name: "detail", choices: ~w(focused complete)}
      ]

      def mount(_params, _session, socket) do
        {:ok, assign(socket, questionnaire: SaladUI.Questionnaire.State.new(@items))}
      end

      def handle_event("questionnaire", params, socket) do
        state = SaladUI.Questionnaire.State.update(@items, params)

        if state.submitted do
          # state.answers => %{"direction" => "delegation", "detail" => "focused"}
          {:noreply, save(socket, state.answers)}
        else
          {:noreply, assign(socket, questionnaire: state)}
        end
      end

      <.questionnaire :let={q} id="plan" items={@items} state={@questionnaire} phx-submit="questionnaire">
        ...
      </.questionnaire>

  ## Items

  Each item is a map (or keyword list) with:

  * `:name` (required) - the item's name; also the form field name of its answers.
  * `:required` - an answer is required and the item cannot be skipped.
  * `:multiple` - fixed choices are checkboxes; the answer is a list.
  * `:disabled` - the item is left out of progress, navigation, validation and answers.
  * `:choices` - the fixed choice values (strings, or maps with `:value` and
    `:disabled`), used for server-rendered shortcuts and to tell a freeform
    answer apart from a fixed one.

  Any other keys (a prompt, a description, labels, ...) are ignored here, so the
  same list can drive the template.

  ## Actions

  * `"previous"` - moves to the previous enabled item.
  * `"next"` - validates the active item, then moves to the next one.
  * `"skip"` - records an optional active item as skipped (dropping its answer)
    and moves on; on the last item it submits.
  * `"continue"` - `"next"`, or `"submit"` on the last item (Enter in a text field
    without JavaScript).
  * `"submit"` - validates every enabled item; the first invalid one becomes the
    active item with an error, otherwise `submitted` is `true`.
  * no action (e.g. a `phx-change`) - recomputes answers and status, keeps the
    active item and clears errors.

  A required item is valid once answered; an optional item once answered or
  skipped; a disabled item always.
  """

  @param "_questionnaire"
  @actions ~w(previous next skip continue submit)

  defstruct item: nil, answers: %{}, skipped: [], errors: %{}, submitted: false, action: nil

  @type item_name :: String.t()
  @type t :: %__MODULE__{
          item: item_name() | nil,
          answers: %{optional(item_name()) => String.t() | [String.t()]},
          skipped: [item_name()],
          errors: %{optional(item_name()) => true | String.t()},
          submitted: boolean(),
          action: String.t() | nil
        }

  @doc """
  The params key holding the questionnaire's own fields (`item`, `skipped`, `action`).
  """
  def param, do: @param

  @doc """
  Builds the initial state.

  ## Options

  * `:item` - the active item (default: the first enabled item).
  * `:answers` - saved answers to resume from, keyed by item name.
  * `:skipped` - item names recorded as skipped.
  """
  @spec new(list(), keyword()) :: t()
  def new(items, opts \\ []) do
    items = normalize_items(items)
    names = enabled_names(items)
    answers = stringify_keys(Keyword.get(opts, :answers, %{}))
    item = to_string_or_nil(Keyword.get(opts, :item))

    %__MODULE__{
      item: if(item in names, do: item, else: List.first(names)),
      answers: answers,
      skipped: optional_skipped(items, Keyword.get(opts, :skipped, []), answers)
    }
  end

  @doc """
  Applies submitted form `params` to `items` and returns the next state.

  See the module documentation for the actions.
  """
  @spec update(list(), map()) :: t()
  def update(items, params) when is_map(params) do
    items = normalize_items(items)
    names = enabled_names(items)
    meta = Map.get(params, @param) || %{}
    meta = if is_map(meta), do: meta, else: %{}

    active = to_string_or_nil(meta["item"])
    active = if active in names, do: active, else: List.first(names)

    answers = answers(items, params)
    skipped = optional_skipped(items, List.wrap(meta["skipped"]), answers)
    action = if meta["action"] in @actions, do: meta["action"]

    state = %__MODULE__{item: active, answers: answers, skipped: skipped, action: action}

    run(action, state, items, names)
  end

  @doc """
  Reads the answers out of submitted `params`, keyed by item name.

  A single-answer item yields its last non-blank value (a freeform answer typed
  next to fixed choices wins), a `:multiple` item the list of non-blank values.
  Unanswered and disabled items are left out.
  """
  @spec answers(list(), map()) :: map()
  def answers(items, params) when is_map(params) do
    items
    |> normalize_items()
    |> Enum.reject(& &1.disabled)
    |> Enum.reduce(%{}, fn item, acc ->
      values =
        params
        |> Map.get(item.name)
        |> List.wrap()
        |> Enum.map(&to_string/1)
        |> Enum.reject(&(String.trim(&1) == ""))

      cond do
        values == [] -> acc
        item.multiple -> Map.put(acc, item.name, values)
        true -> Map.put(acc, item.name, List.last(values))
      end
    end)
  end

  @doc """
  The item's status: `"answered"`, `"skipped"` or `"unanswered"`.
  """
  @spec status(t(), item_name()) :: String.t()
  def status(%__MODULE__{} = state, name) do
    cond do
      name in state.skipped -> "skipped"
      Map.has_key?(state.answers, name) -> "answered"
      true -> "unanswered"
    end
  end

  @doc """
  Whether the item (a normalized item map) is valid for the given state.
  """
  def valid?(%{disabled: true}, _state), do: true

  def valid?(item, %__MODULE__{} = state) do
    Map.has_key?(state.answers, item.name) or (not item.required and item.name in state.skipped)
  end

  @doc """
  Normalizes item definitions to maps with `:name`, `:required`, `:multiple`,
  `:disabled` and `:choices` (`nil`, or a list of `%{value: _, disabled: _}`).
  """
  def normalize_items(items) when is_list(items), do: Enum.map(items, &normalize_item/1)
  def normalize_items(_items), do: []

  defp normalize_item(item) do
    get = fn key -> fetch(item, key) end

    %{
      name: to_string(get.(:name)),
      required: get.(:required) == true,
      multiple: get.(:multiple) == true,
      disabled: get.(:disabled) == true,
      choices: normalize_choices(get.(:choices))
    }
  end

  defp normalize_choices(nil), do: nil

  defp normalize_choices(choices) when is_list(choices) do
    Enum.map(choices, fn
      choice when is_binary(choice) or is_atom(choice) or is_number(choice) ->
        %{value: to_string(choice), disabled: false}

      choice ->
        %{value: to_string(fetch(choice, :value)), disabled: fetch(choice, :disabled) == true}
    end)
  end

  defp fetch(item, key) when is_list(item), do: Keyword.get(item, key)
  defp fetch(item, key) when is_map(item), do: Map.get(item, key, Map.get(item, Atom.to_string(key)))

  defp run("previous", state, _items, names) do
    %{state | item: neighbour(names, state.item, -1) || state.item}
  end

  defp run("next", state, items, names) do
    if valid?(item(items, state.item), state) do
      %{state | item: neighbour(names, state.item, 1) || state.item}
    else
      %{state | errors: %{state.item => true}}
    end
  end

  defp run("skip", state, items, names) do
    case item(items, state.item) do
      %{required: false} ->
        state = %{
          state
          | answers: Map.delete(state.answers, state.item),
            skipped: Enum.uniq(state.skipped ++ [state.item])
        }

        if last?(names, state.item), do: run("submit", state, items, names), else: run("next", state, items, names)

      _required ->
        %{state | errors: %{state.item => true}}
    end
  end

  defp run("continue", state, items, names) do
    if last?(names, state.item), do: run("submit", state, items, names), else: run("next", state, items, names)
  end

  defp run("submit", state, items, _names) do
    case Enum.find(items, &(not &1.disabled and not valid?(&1, state))) do
      nil -> %{state | submitted: true}
      invalid -> %{state | item: invalid.name, errors: %{invalid.name => true}}
    end
  end

  defp run(_action, state, _items, _names), do: state

  defp item(items, name), do: Enum.find(items, &(&1.name == name)) || %{name: name, disabled: false, required: false}

  defp neighbour(names, name, offset) do
    case Enum.find_index(names, &(&1 == name)) do
      nil -> nil
      index when index + offset < 0 -> nil
      index -> Enum.at(names, index + offset)
    end
  end

  defp last?(names, name), do: List.last(names) == name

  defp enabled_names(items), do: for(item <- items, not item.disabled, do: item.name)

  defp optional_skipped(items, skipped, answers) do
    skipped = Enum.map(skipped, &to_string/1)

    for item <- items,
        not item.disabled,
        not item.required,
        item.name in skipped,
        not Map.has_key?(answers, item.name),
        do: item.name
  end

  defp stringify_keys(map) when is_map(map), do: Map.new(map, fn {key, value} -> {to_string(key), value} end)
  defp stringify_keys(_), do: %{}

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(value), do: to_string(value)
end
