defmodule SaladUI.Questionnaire do
  @moduledoc """
  Implementation of the questionnaire component from https://ui.shadcn.com/docs/components/radix/questionnaire

  A multi-step form that shows one question at a time, with single-choice,
  multiple-choice, freeform and skippable questions, progress, validation,
  answer shortcuts and keyboard navigation. The root renders a native `<form>`:
  every item is a `<fieldset>` whose answers are native radios, checkboxes and
  text inputs, so answers arrive in `phx-submit` (or a controller `POST`) params.

  ## Example

      @items [
        %{
          name: "direction",
          required: true,
          prompt: "What should we prototype next?",
          description: "Choose a direction or write your own.",
          choices: [
            %{value: "delegation", label: "Delegation", description: "Show how work moves to a specialist."},
            %{value: "questions", label: "Question prompts", description: "Show choices while the interface waits."},
            %{value: "both", label: "Both together"}
          ],
          input: %{label: "Another answer", placeholder: "Type another answer…"}
        },
        %{
          name: "detail",
          prompt: "How much detail should it include?",
          description: "Skip this if you are not sure yet.",
          choices: [%{value: "focused", label: "Focused"}, %{value: "complete", label: "Complete flow"}]
        }
      ]

      <.questionnaire :let={q} id="prototype" items={@items} state={@questionnaire} phx-submit="questionnaire">
        <.questionnaire_progress questionnaire={q} />
        <.questionnaire_item :for={question <- @items} :let={item} questionnaire={q} name={question.name}>
          <.questionnaire_title>{question.prompt}</.questionnaire_title>
          <.questionnaire_description>{question.description}</.questionnaire_description>
          <.questionnaire_choices>
            <.questionnaire_choice :for={choice <- question.choices} item={item} value={choice.value}>
              <span class="font-medium">{choice.label}</span>
              <.questionnaire_choice_description :if={choice[:description]}>
                {choice.description}
              </.questionnaire_choice_description>
            </.questionnaire_choice>
            <.questionnaire_input
              :if={question[:input]}
              item={item}
              aria-label={question.input.label}
              placeholder={question.input.placeholder}
            />
          </.questionnaire_choices>
          <.questionnaire_error item={item} />
        </.questionnaire_item>
        <.questionnaire_actions>
          <.questionnaire_previous />
          <.questionnaire_skip />
          <.questionnaire_next />
          <.questionnaire_submit />
        </.questionnaire_actions>
      </.questionnaire>

  The root yields its state (`q`) through `:let`; pass it to
  `questionnaire_progress/1` and `questionnaire_item/1`. Each item yields its
  own state (`item`) for its choices, freeform input and error.

  ## Server-driven steps (works without JavaScript)

  Pass `items` and `item` (or a `SaladUI.Questionnaire.State` as `state`) and the
  server owns the step: the active item, progress, which actions show, checked
  answers, skipped items and errors are all rendered on the server. Previous,
  Skip, Next and Submit are submit buttons that post `_questionnaire[action]`
  with every answer, so a single handler drives the flow:

      def handle_event("questionnaire", params, socket) do
        state = SaladUI.Questionnaire.State.update(@items, params)

        if state.submitted do
          {:noreply, socket |> put_flash(:info, "Saved") |> assign(questionnaire: SaladUI.Questionnaire.State.new(@items))}
        else
          {:noreply, assign(socket, questionnaire: state)}
        end
      end

  The same `State.update/2` call works in a controller action for a plain
  `<form action={~p"/survey"} method="post">` with JavaScript disabled. With the
  hook mounted, the active item is validated in the browser first (no round
  trip for a missing answer) and the keyboard shortcuts submit the matching
  action.

  ## Client-driven steps

  Without `item`/`state` (optionally with `default_item`), the hook moves
  between items in the browser and only the final Submit reaches the server.
  `on-item-change` reports navigation.

  ## Answers

  An item's answers are submitted under `name[]`: a single-choice item posts
  one value, a `multiple` item every checked value, and a freeform input its
  text. `SaladUI.Questionnaire.State.answers/2` (or `state.answers`) turns them
  into `%{"direction" => "delegation", "signals" => ["progress", "risks"]}`.
  Skipped items post no answer; their names are in `_questionnaire[skipped][]`.

  ## Keyboard

  * `Tab` / `Shift+Tab` - move between answers and visible actions.
  * `ArrowUp` / `ArrowDown` - previous / next answer.
  * `ArrowLeft` / `ArrowRight` - previous / next item (outside radios and text
    fields; next only once the item is answered or skipped).
  * `Enter` - continue from a selected answer or a filled freeform input.
  * `Cmd/Ctrl+Enter` - validate and continue, or submit on the last item.
  * With `shortcuts="letters"` (`A`-`Z`) or `"numbers"` (`1`-`9`), the key selects that answer.

  ## Component events

  * `:on-item-change` - Fired with `%{"item" => name}` when the hook moves to another item (client-driven).
  * `:on-status-change` - Fired with `%{"item" => name, "status" => status}` when an item becomes
    `"answered"`, `"skipped"` or `"unanswered"`.

  ## Server commands

  `SaladUI.LiveView.send_command/4` accepts `"next"`, `"previous"`, `"skip"`,
  `"submit"`, `"reset"` and `"goto"` (`%{item: name}`, client-driven only).
  """
  use SaladUI, :component

  alias SaladUI.Questionnaire.State

  @shortcut_keys %{
    "letters" => Enum.map(?A..?Z, &<<&1>>),
    "numbers" => Enum.map(1..9, &Integer.to_string/1)
  }

  @doc """
  The questionnaire root: a native `<form>`.

  Yields its state through `:let` - pass it as `questionnaire` to
  `questionnaire_progress/1` and `questionnaire_item/1`.

  ## Component events

  * `:on-item-change` - Fired when the hook moves to another item.
  * `:on-status-change` - Fired when an item's status changes.
  """
  attr :id, :string, required: true

  attr :items, :list,
    default: [],
    doc:
      "Item definitions (maps with `:name`, `:required`, `:multiple`, `:disabled`, `:choices`) for server-rendered order, progress, actions and shortcuts"

  attr :state, :map,
    default: nil,
    doc: "A `SaladUI.Questionnaire.State`; sets `item`, `answers`, `skipped` and `errors` at once"

  attr :item, :string,
    default: nil,
    doc: "Active item. Setting it makes the step server-driven: navigation submits to the server"

  attr :default_item, :string, default: nil, doc: "Initially active item when client-driven (default: first enabled)"
  attr :answers, :map, default: %{}, doc: "Answers keyed by item name: a string, or a list for `multiple` items"
  attr :skipped, :list, default: [], doc: "Names of items recorded as skipped"
  attr :errors, :map, default: %{}, doc: "Invalid items: name => `true` or a message"

  attr :shortcuts, :string,
    default: nil,
    values: [nil, "letters", "numbers"],
    doc: "Assign `A`-`Z` or `1`-`9` to each enabled fixed choice"

  attr :class, :string, default: nil
  attr :"on-item-change", :any, default: nil, doc: "Handler for item change events"
  attr :"on-status-change", :any, default: nil, doc: "Handler for item status change events"
  attr :rest, :global, include: ~w(action method enctype target autocomplete accept-charset csrf_token)
  slot :inner_block, required: true

  def questionnaire(assigns) do
    assigns = apply_state(assigns)
    q = root_context(assigns)

    assigns =
      assigns
      |> assign(:q, q)
      |> assign(:event_map, json(event_mappings(assigns)))
      |> assign(:options, json(%{item: q.item, serverDriven: q.server_driven, shortcuts: q.shortcuts}))

    ~H"""
    <.form
      for={%{}}
      id={@id}
      novalidate
      data-slot="questionnaire"
      data-component="questionnaire"
      data-part="root"
      data-state="idle"
      data-options={@options}
      data-event-mappings={@event_map}
      data-current={@q.current}
      data-total={@q.total}
      data-first={@q.first}
      data-last={@q.last}
      data-required={@q.required}
      data-status={@q.status}
      data-shortcuts={@q.shortcuts}
      phx-hook="SaladUI"
      class={classes(["group/questionnaire flex w-full min-w-0 flex-col gap-4", @class])}
      {@rest}
    >
      <button
        type="submit"
        name={action_param()}
        value="continue"
        data-part="default-action"
        tabindex="-1"
        aria-hidden="true"
        class="sr-only"
      >
        Continue
      </button>
      <input type="hidden" name={"#{State.param()}[item]"} value={@q.item} data-part="active-input" />
      <input
        :for={name <- @q.skipped}
        type="hidden"
        name={"#{State.param()}[skipped][]"}
        value={name}
        data-part="skipped-input"
      />
      {render_slot(@inner_block, @q)}
    </.form>
    """
  end

  @doc """
  Shows `Question {current} of {total}` as a named progressbar.

  For custom content, use `:let={p}` (`p.current`, `p.total`, `p.first`,
  `p.last`). When the hook navigates in the browser it rewrites the text of
  descendants marked `data-progress-current` / `data-progress-total`, and sets
  `data-complete` on `data-progress-step={n}` elements up to the current step.
  """
  attr :questionnaire, :map, default: nil, doc: "The root's `:let` state"
  attr :"aria-label", :string, default: "Questionnaire progress"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def questionnaire_progress(assigns) do
    q = assigns.questionnaire || %{}
    total = Map.get(q, :total, 0)
    current = Map.get(q, :current, 0)

    progress = %{current: current, total: total, first: Map.get(q, :first, false), last: Map.get(q, :last, false)}
    label = if total > 0, do: "Question #{current} of #{total}"

    assigns = assign(assigns, progress: progress, label: label)

    ~H"""
    <div
      data-slot="questionnaire-progress"
      data-part="progress"
      role="progressbar"
      aria-label={assigns[:"aria-label"]}
      aria-live="polite"
      aria-valuemin={@progress.total > 0 && 1}
      aria-valuemax={@progress.total > 0 && @progress.total}
      aria-valuenow={@progress.total > 0 && @progress.current}
      aria-valuetext={@label}
      data-current={@progress.current}
      data-total={@progress.total}
      data-first={@progress.first}
      data-last={@progress.last}
      data-default-label={@inner_block == []}
      class={
        classes([
          "min-h-[1lh] w-fit min-w-[14ch] text-xs font-medium text-muted-foreground tabular-nums",
          @class
        ])
      }
      {@rest}
    >
      <%= if @inner_block == [] do %>
        {@label}
      <% else %>
        {render_slot(@inner_block, @progress)}
      <% end %>
    </div>
    """
  end

  @doc """
  One questionnaire step, rendered as a `<fieldset>`.

  `required`, `multiple` and `disabled` default to the matching entry in the
  root's `items`. Yields the item's state through `:let` for
  `questionnaire_choice/1`, `questionnaire_input/1` and `questionnaire_error/1`.

  Inactive items are `hidden` and `inert`; a disabled item is a disabled
  fieldset, so its answers are not submitted.
  """
  attr :name, :string, required: true, doc: "Item name; also the form field name of its answers"
  attr :questionnaire, :map, default: nil, doc: "The root's `:let` state"
  attr :required, :boolean, default: nil, doc: "An answer is required; Skip is hidden"
  attr :multiple, :boolean, default: nil, doc: "Fixed choices are checkboxes"
  attr :disabled, :boolean, default: nil, doc: "Leave the item out of progress, navigation, validation and submission"
  attr :invalid, :boolean, default: false, doc: "Mark the item invalid (e.g. from an external validator)"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def questionnaire_item(assigns) do
    assigns = assign(assigns, :ctx, item_context(assigns))

    ~H"""
    <fieldset
      id={@ctx.id}
      data-slot="questionnaire-item"
      data-part="item"
      data-name={@name}
      data-active={@ctx.active == true}
      data-status={@ctx.status}
      data-required={@ctx.required}
      data-multiple={@ctx.multiple}
      data-disabled={@ctx.disabled}
      data-invalid={@ctx.invalid}
      hidden={@ctx.active == false}
      inert={@ctx.active == false}
      disabled={@ctx.disabled}
      tabindex="-1"
      aria-invalid={@ctx.invalid && "true"}
      class={classes(["flex min-w-0 flex-col gap-4 border-0 p-0 outline-none", @class])}
      {@rest}
    >
      {render_slot(@inner_block, @ctx)}
    </fieldset>
    """
  end

  @doc """
  The item's question. Renders the fieldset's `<legend>` by default.

  When the title has to live elsewhere (a card or dialog header), render it with
  `as="div"` (or any element) and an `id`, and pass that id to the item's
  `aria-labelledby`.
  """
  attr :as, :string, default: "legend", doc: "Element to render"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def questionnaire_title(assigns) do
    ~H"""
    <.dynamic
      tag={@as}
      data-slot="questionnaire-title"
      data-part="title"
      class={
        classes([
          "text-base leading-snug font-medium text-pretty [&:not(:has(~[data-slot=questionnaire-description]))]:mb-4",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  Supporting text, connected to the item with `aria-describedby`.
  """
  attr :item, :map, default: nil, doc: "The item's `:let` state (gives the description a stable id)"
  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def questionnaire_description(assigns) do
    assigns = assign(assigns, :id, assigns.id || (assigns.item && assigns.item.id && "#{assigns.item.id}-description"))

    ~H"""
    <p
      id={@id}
      data-slot="questionnaire-description"
      data-part="description"
      class={classes(["text-sm text-pretty text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Layout container for an item's fixed choices and freeform input.
  """
  attr :item, :map, default: nil, doc: "The item's `:let` state (sets `data-shortcuts`)"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def questionnaire_choices(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-choices"
      data-part="choices"
      data-shortcuts={@item && @item.shortcut_mode}
      class={classes(["group/questionnaire-choices grid min-w-0 gap-2", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A fixed answer: a native radio (or a checkbox in a `multiple` item) wrapped
  in its `<label>`, with an indicator and an optional shortcut hint.

  It is checked when `value` is among the item's answers, unless `checked` is
  given. The checked look comes from CSS `:has(:checked)`, so it is correct
  before (and without) JavaScript.
  """
  attr :item, :map, required: true, doc: "The item's `:let` state"
  attr :value, :string, required: true, doc: "Submitted answer value"
  attr :checked, :boolean, default: nil, doc: "Checked state (default: whether `value` is among the item's answers)"
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def questionnaire_choice(assigns) do
    item = assigns.item
    type = if item.multiple, do: "checkbox", else: "radio"
    disabled = item.disabled == true or assigns.disabled

    checked =
      item.status != "skipped" and
        if(is_nil(assigns.checked), do: assigns.value in item.values, else: assigns.checked)

    shortcut = if disabled, do: nil, else: Map.get(item.shortcuts, assigns.value)

    keyshortcuts =
      [shortcut, checked and not disabled and "Enter"]
      |> Enum.filter(&is_binary/1)
      |> Enum.join(" ")

    assigns =
      assign(assigns,
        type: type,
        checked: checked,
        disabled: disabled,
        shortcut: shortcut,
        keyshortcuts: if(keyshortcuts == "", do: nil, else: keyshortcuts)
      )

    ~H"""
    <label
      data-slot="questionnaire-choice"
      data-part="choice"
      data-type={@type}
      data-checked={@checked}
      data-unchecked={!@checked}
      data-disabled={@disabled}
      data-invalid={@item.invalid}
      data-shortcut={@shortcut}
      class={
        classes([
          "group/questionnaire-choice relative flex min-h-11 cursor-pointer items-start gap-2.5 rounded-lg border border-input bg-transparent px-3 py-2.5 text-start text-sm transition-colors outline-none select-none hover:bg-muted/50 dark:bg-input/20",
          "has-[>input:checked]:border-primary/40 has-[>input:checked]:bg-muted dark:has-[>input:checked]:bg-muted",
          "has-[>input:focus-visible]:border-ring has-[>input:focus-visible]:ring-3 has-[>input:focus-visible]:ring-ring/50 data-invalid:border-destructive",
          "data-disabled:pointer-events-none data-disabled:cursor-not-allowed data-disabled:opacity-50",
          @class
        ])
      }
      {@rest}
    >
      <input
        type={@type}
        data-slot="questionnaire-choice-input"
        data-part="choice-input"
        name={@item.input_name}
        value={@value}
        checked={@checked}
        disabled={@disabled}
        aria-invalid={@item.invalid && "true"}
        aria-keyshortcuts={@keyshortcuts}
        class="absolute inset-0 z-10 size-full cursor-pointer opacity-0"
      />
      <span
        aria-hidden="true"
        data-slot="questionnaire-choice-indicator"
        class={[
          "pointer-events-none relative flex size-4 shrink-0 translate-y-[--spacing(0.45)] items-center justify-center rounded-[4px] border border-input group-has-data-[slot=questionnaire-choice-description]/questionnaire-choice:translate-y-0.5 group-data-[type=radio]/questionnaire-choice:rounded-full dark:bg-input/30",
          "group-has-[>input:checked]/questionnaire-choice:border-primary group-has-[>input:checked]/questionnaire-choice:bg-primary group-has-[>input:checked]/questionnaire-choice:text-primary-foreground dark:group-has-[>input:checked]/questionnaire-choice:bg-primary"
        ]}
      >
        <span
          :if={@type == "radio"}
          data-slot="questionnaire-choice-indicator-dot"
          class="hidden size-2 rounded-full bg-primary-foreground group-has-[>input:checked]/questionnaire-choice:block"
        />
        <svg
          :if={@type == "checkbox"}
          data-slot="questionnaire-choice-indicator-check"
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="hidden size-3.5 group-has-[>input:checked]/questionnaire-choice:block"
        >
          <path d="M20 6 9 17l-5-5" />
        </svg>
      </span>
      <span
        data-slot="questionnaire-choice-label"
        data-part="choice-label"
        class="flex min-w-0 flex-1 flex-col gap-0.5 leading-snug"
      >
        {render_slot(@inner_block)}
      </span>
      <span
        data-slot="questionnaire-choice-shortcut"
        data-part="choice-shortcut"
        aria-hidden="true"
        hidden={is_nil(@shortcut)}
        class="pointer-events-none ms-auto hidden size-5 shrink-0 translate-y-[--spacing(0.45)] items-center justify-center rounded-md border border-input bg-background font-mono text-[0.625rem] leading-none font-medium text-muted-foreground group-has-data-[slot=questionnaire-choice-description]/questionnaire-choice:translate-y-0.5 group-data-[shortcut]/questionnaire-choice:inline-flex"
      >
        {@shortcut}
      </span>
    </label>
    """
  end

  @doc """
  Secondary text inside a `questionnaire_choice/1`.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def questionnaire_choice_description(assigns) do
    ~H"""
    <span
      data-slot="questionnaire-choice-description"
      class={classes(["text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  A freeform answer, submitted under the item's name.

  In a single-answer item, typing clears the fixed choice and picking a fixed
  choice takes the typed text out of the submission (it stays visible). Without
  JavaScript both are posted and `SaladUI.Questionnaire.State` keeps the typed
  text.

  Always give it an accessible name (`aria-label`, `aria-labelledby` or a
  `<label for>`); a placeholder is not a label.
  """
  attr :item, :map, required: true, doc: "The item's `:let` state"

  attr :type, :string,
    default: "text",
    values: ~w(text email number password search tel url date datetime-local month time week)

  attr :value, :string,
    default: nil,
    doc: "Value (default: the item's answer when it is not one of the item's `choices`)"

  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil

  attr :rest, :global,
    include: ~w(placeholder autocomplete autofocus maxlength minlength pattern inputmode min max step readonly)

  def questionnaire_input(assigns) do
    item = assigns.item
    value = assigns.value || freeform_value(item)
    disabled = item.disabled == true or assigns.disabled
    filled = is_binary(value) and String.trim(value) != ""

    assigns = assign(assigns, value: value, disabled: disabled, filled: filled)

    ~H"""
    <div
      data-slot="questionnaire-input-wrapper"
      class="group/questionnaire-input relative w-full min-w-0"
    >
      <input
        type={@type}
        data-slot="questionnaire-input"
        data-part="input"
        data-name={@item.input_name}
        name={@item.input_name}
        value={@value}
        disabled={@disabled}
        data-filled={@filled}
        data-empty={!@filled}
        data-disabled={@disabled}
        data-invalid={@item.invalid}
        aria-invalid={@item.invalid && "true"}
        class={
          classes([
            "h-8 min-h-11 w-full min-w-0 rounded-lg border border-input bg-transparent px-2.5 py-1 text-base transition-[color,box-shadow,background-color] outline-none selection:bg-primary selection:text-primary-foreground placeholder:text-muted-foreground sm:min-h-0 md:text-sm dark:bg-input/30",
            "focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50",
            "aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40",
            "disabled:pointer-events-none disabled:cursor-not-allowed disabled:bg-input/50 disabled:opacity-50 dark:disabled:bg-input/80",
            @class
          ])
        }
        {@rest}
      />
    </div>
    """
  end

  @doc """
  The validation message, hidden until the item is invalid.

  Shows, in order: the slot content, the message from the root's `errors`, or
  "Choose an answer to continue." (required) / "Choose an answer or skip this
  question." (optional).
  """
  attr :item, :map, required: true, doc: "The item's `:let` state"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def questionnaire_error(assigns) do
    item = assigns.item

    message =
      item.error ||
        if item.required,
          do: "Choose an answer to continue.",
          else: "Choose an answer or skip this question."

    assigns = assign(assigns, message: message)

    ~H"""
    <p
      id={@item.id && "#{@item.id}-error"}
      data-slot="questionnaire-error"
      data-part="error"
      data-invalid={@item.invalid}
      hidden={!@item.invalid}
      role={@item.invalid && "alert"}
      class={classes(["mt-2 text-sm text-destructive", @class])}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        {@message}
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </p>
    """
  end

  @doc """
  Lays out Previous, Skip and Next/Submit on one row (Previous at the start).
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def questionnaire_actions(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-actions"
      class={
        classes([
          "grid min-h-11 w-full grid-cols-[minmax(0,1fr)_auto_auto] items-center gap-2 sm:min-h-8",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Moves to the previous item. Hidden on the first item.
  """
  attr :variant, :string, default: "outline", values: ~w(default destructive outline secondary ghost link)
  attr :size, :string, default: "default", values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg)
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def questionnaire_previous(assigns) do
    assigns
    |> assign(
      action: "previous",
      label: "Previous",
      layout: "col-start-1 row-start-1 min-h-11 justify-self-start sm:min-h-0 group-data-first/questionnaire:hidden"
    )
    |> navigation_button()
  end

  @doc """
  Records the active optional item as skipped and moves on (submits on the
  last item). Hidden while the active item is required.
  """
  attr :variant, :string, default: "outline", values: ~w(default destructive outline secondary ghost link)
  attr :size, :string, default: "default", values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg)
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def questionnaire_skip(assigns) do
    assigns
    |> assign(
      action: "skip",
      label: "Skip",
      layout: "col-start-2 row-start-1 min-h-11 justify-self-end sm:min-h-0 group-data-required/questionnaire:hidden"
    )
    |> navigation_button()
  end

  @doc """
  Validates the active item and moves to the next one. Hidden on the last item.
  """
  attr :variant, :string, default: "default", values: ~w(default destructive outline secondary ghost link)
  attr :size, :string, default: "default", values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg)
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def questionnaire_next(assigns) do
    assigns
    |> assign(
      action: "next",
      label: "Next",
      layout: "col-start-3 row-start-1 min-h-11 justify-self-end sm:min-h-0 group-data-last/questionnaire:hidden"
    )
    |> navigation_button()
  end

  @doc """
  Validates every item and submits the form. Shown on the last item only.
  """
  attr :variant, :string, default: "default", values: ~w(default destructive outline secondary ghost link)
  attr :size, :string, default: "default", values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg)
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def questionnaire_submit(assigns) do
    assigns
    |> assign(
      action: "submit",
      label: "Submit",
      layout: "col-start-3 row-start-1 min-h-11 justify-self-end sm:min-h-0 not-group-data-last/questionnaire:hidden"
    )
    |> navigation_button()
  end

  defp navigation_button(assigns) do
    ~H"""
    <button
      type="submit"
      name={action_param()}
      value={@action}
      data-slot={"questionnaire-#{@action}"}
      data-part={@action}
      data-size={@size}
      data-variant={@variant}
      disabled={@disabled}
      data-disabled={@disabled}
      class={classes([button_variant(%{variant: @variant, size: @size}), @layout, @class])}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        {@label}
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </button>
    """
  end

  defp action_param, do: "#{State.param()}[action]"

  # -- State -----------------------------------------------------------------

  defp apply_state(%{state: nil} = assigns), do: assigns

  defp apply_state(%{state: state} = assigns) do
    assign(assigns,
      item: fetch(state, :item),
      answers: fetch(state, :answers) || %{},
      skipped: fetch(state, :skipped) || [],
      errors: fetch(state, :errors) || %{}
    )
  end

  defp root_context(assigns) do
    items = State.normalize_items(assigns.items)
    names = for item <- items, not item.disabled, do: item.name
    active = active_item(names, assigns.item || assigns.default_item)
    index = Enum.find_index(names, &(&1 == active))
    total = length(names)
    answers = stringify_keys(assigns.answers)
    skipped = Enum.map(assigns.skipped || [], &to_string/1)
    definition = Enum.find(items, &(&1.name == active))

    %{
      id: assigns.id,
      items: Map.new(items, &{&1.name, &1}),
      item: active,
      server_driven: not is_nil(assigns.item),
      current: (index || -1) + 1,
      total: total,
      first: index == 0,
      last: index == total - 1,
      required: definition && definition.required,
      status: active && status(active, answers, skipped),
      shortcuts: assigns.shortcuts,
      answers: answers,
      skipped: skipped,
      errors: stringify_keys(assigns.errors)
    }
  end

  defp item_context(assigns) do
    q = assigns.questionnaire || %{}
    name = assigns.name
    definition = Map.get(Map.get(q, :items, %{}), name, %{})

    required = pick(assigns.required, definition[:required])
    multiple = pick(assigns.multiple, definition[:multiple])
    disabled = pick(assigns.disabled, definition[:disabled])
    answers = Map.get(q, :answers, %{})
    skipped = Map.get(q, :skipped, [])
    errors = Map.get(q, :errors, %{})
    mode = Map.get(q, :shortcuts)

    values = answer_values(answers, name)
    choices = definition[:choices]

    %{
      name: name,
      input_name: "#{name}[]",
      id: q[:id] && "#{q.id}-#{dom_id(name)}",
      required: required,
      multiple: multiple,
      disabled: disabled,
      active: item_active(disabled, Map.get(q, :item), name),
      invalid: not disabled and (assigns.invalid or Map.has_key?(errors, name)),
      status: status(name, if(values == [], do: %{}, else: %{name => values}), skipped),
      values: values,
      choices: choices && Enum.map(choices, & &1.value),
      shortcut_mode: mode,
      shortcuts: shortcuts(choices, mode),
      error: if(is_binary(errors[name]), do: errors[name])
    }
  end

  defp active_item([], requested), do: requested
  defp active_item(names, requested), do: if(requested in names, do: requested, else: List.first(names))

  defp item_active(true, _active, _name), do: false
  defp item_active(_disabled, nil, _name), do: nil
  defp item_active(_disabled, active, name), do: active == name

  defp answer_values(answers, name) do
    answers
    |> Map.get(name)
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(String.trim(&1) == ""))
  end

  defp status(name, answers, skipped) do
    cond do
      name in skipped -> "skipped"
      Map.has_key?(answers, name) -> "answered"
      true -> "unanswered"
    end
  end

  defp shortcuts(nil, _mode), do: %{}
  defp shortcuts(_choices, nil), do: %{}

  defp shortcuts(choices, mode) do
    choices
    |> Enum.reject(& &1.disabled)
    |> Enum.zip(@shortcut_keys[mode])
    |> Map.new(fn {choice, key} -> {choice.value, key} end)
  end

  defp freeform_value(item) do
    Enum.find(item.values, fn value -> is_nil(item.choices) or value not in item.choices end)
  end

  defp pick(nil, nil), do: false
  defp pick(nil, value), do: value == true
  defp pick(value, _definition), do: value == true

  defp dom_id(name), do: String.replace(name, ~r/[^A-Za-z0-9_-]/, "-")

  defp fetch(map, key), do: Map.get(map, key, Map.get(map, Atom.to_string(key)))

  defp stringify_keys(map) when is_map(map), do: Map.new(map, fn {key, value} -> {to_string(key), value} end)
  defp stringify_keys(_), do: %{}
end
