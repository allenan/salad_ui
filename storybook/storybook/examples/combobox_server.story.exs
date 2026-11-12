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
    receives it and the server renders the matching items. The selection is a
    form field: submitting without picking a language shows the field error,
    and the picked value is submitted with the form.
    """
  end

  @languages ~w(Elixir Erlang Gleam Go Haskell Java JavaScript Kotlin OCaml Python Ruby Rust Scala Swift TypeScript Zig)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       query: "",
       languages: @languages,
       form: to_form(%{"language" => nil}, as: :project),
       submitted: nil
     )}
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
          <.combobox id="project_language" field={@form[:language]} filter={false} auto-highlight>
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
              <.combobox_list>
                <.combobox_item :for={language <- @languages} value={language}>
                  {language}
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

    {:noreply,
     assign(socket,
       query: query,
       languages: filter(query),
       form: to_form(project, as: :project)
     )}
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

  defp filter(""), do: @languages

  defp filter(query) do
    query = String.downcase(query)
    Enum.filter(@languages, &String.contains?(String.downcase(&1), query))
  end
end
