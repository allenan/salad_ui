defmodule Storybook.Examples.ComboboxServer do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Button
  import SaladUI.Combobox
  import SaladUI.Field

  def doc do
    """
    Server-side filtering: `filter={false}` leaves the items to the server. The
    query input is named `query` and debounced, so the form's `phx-change`
    receives it and the server streams the matching items into the list
    (`phx-update="stream"`, reset on every search). The selection is a
    form field: submitting without picking a language shows the field error,
    and the picked value is submitted with the form.

    After a pick the input shows the language while the server still holds the
    last query, so `on-open` resets the results: its payload carries the query
    the list opened with (`""` unless typing opened it), and reopening lists
    every language again.
    """
  end

  @languages ~w(Elixir Erlang Gleam Go Haskell Java JavaScript Kotlin OCaml Python Ruby Rust Scala Swift TypeScript Zig)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       query: "",
       form: to_form(%{"language" => nil}, as: :project),
       submitted: nil
     )
     |> stream(:languages, entries(@languages))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm space-y-6 py-8">
      <.form
        for={@form}
        id="combobox-server-form"
        phx-change="search"
        phx-submit="save"
        class="space-y-4"
      >
        <.field field={@form[:language]}>
          <.field_label for="project_language-input">Language</.field_label>
          <.combobox
            id="project_language"
            field={@form[:language]}
            filter={false}
            auto-highlight
            on-open="search_opened"
          >
            <.combobox_input
              id="project_language-input"
              name="query"
              value={@query}
              phx-debounce="200"
              placeholder="Search languages"
              show-clear
            />
            <.combobox_content>
              <.combobox_empty>No languages match "{@query}".</.combobox_empty>
              <.combobox_list id="project_language-list" phx-update="stream">
                <.combobox_item
                  :for={{dom_id, language} <- @streams.languages}
                  id={dom_id}
                  value={language.name}
                >
                  {language.name}
                </.combobox_item>
              </.combobox_list>
            </.combobox_content>
          </.combobox>
          <.field_error field={@form[:language]} />
        </.field>
        <.button type="submit">Save</.button>
      </.form>
      <p :if={@submitted} id="combobox-server-result" class="text-sm text-muted-foreground">
        Saved: {@submitted}
      </p>
    </div>
    """
  end

  @impl true
  def handle_event("search", params, socket) do
    query = params |> Map.get("query", socket.assigns.query) |> String.trim()
    project = Map.get(params, "project", %{})

    {:noreply, socket |> search(query) |> assign(form: to_form(project, as: :project))}
  end

  def handle_event("search_opened", %{"query" => query}, socket) do
    {:noreply, search(socket, String.trim(query))}
  end

  def handle_event("save", params, socket) do
    project = Map.get(params, "project", %{})

    case project["language"] do
      language when language in [nil, ""] ->
        {:noreply, assign(socket, form: to_form(project, as: :project, errors: [language: {"can't be blank", []}]))}

      language ->
        {:noreply, assign(socket, submitted: language, form: to_form(project, as: :project))}
    end
  end

  defp search(socket, query) do
    if query == socket.assigns.query do
      socket
    else
      socket
      |> stream(:languages, entries(filter(query)), reset: true)
      |> assign(query: query)
    end
  end

  defp entries(languages), do: Enum.map(languages, &%{id: String.downcase(&1), name: &1})

  defp filter(""), do: @languages

  defp filter(query) do
    query = String.downcase(query)
    Enum.filter(@languages, &String.contains?(String.downcase(&1), query))
  end
end
