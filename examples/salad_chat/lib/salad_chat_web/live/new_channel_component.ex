defmodule SaladChatWeb.NewChannelComponent do
  @moduledoc "The \"Create a channel\" dialog: name, description, privacy and members."
  use SaladChatWeb, :live_component

  import SaladChatWeb.People

  alias SaladChat.Chat
  alias SaladChatWeb.Paths

  @empty %{"name" => "", "description" => "", "private" => "false", "members" => %{}}

  @impl true
  def mount(socket), do: {:ok, assign_form(socket, @empty, [])}

  @impl true
  def update(assigns, socket), do: {:ok, assign(socket, assigns)}

  defp assign_form(socket, params, errors) do
    socket
    |> assign(:params, params)
    |> assign(:form, to_form(params, as: :channel, errors: errors))
  end

  defp normalize(params) do
    params = Map.merge(@empty, params)
    %{params | "name" => Chat.slugify(params["name"])}
  end

  defp selected(params) do
    for {handle, "true"} <- params["members"] || %{}, do: handle
  end

  @impl true
  def handle_event("validate", %{"channel" => params}, socket) do
    params = normalize(params)
    {:noreply, assign_form(socket, params, Chat.validate_channel(params))}
  end

  def handle_event("create", %{"channel" => params}, socket) do
    params = normalize(params)
    me = socket.assigns.me

    case Chat.create_channel(Map.put(params, "members", selected(params)), me.handle) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> assign_form(@empty, [])
         |> SaladUI.LiveView.send_command("create-channel-dialog", "close")
         |> SaladUI.Toast.toast_success("##{channel.name} is ready",
           description: "#{length(channel.members) - 1} members, including Sprout."
         )
         |> push_patch(to: Paths.channel_path(me.handle, channel.id))}

      {:error, errors} ->
        {:noreply, assign_form(socket, params, errors)}
    end
  end

  def handle_event("reset", _, socket), do: {:noreply, assign_form(socket, @empty, [])}

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(
        :people,
        assigns.users
        |> Map.values()
        |> Enum.reject(&(&1.bot? or &1.handle == assigns.me.handle))
        |> Enum.sort_by(& &1.name)
      )
      |> assign(:chosen, MapSet.new(selected(assigns.params)))

    ~H"""
    <div>
      <.dialog id="create-channel-dialog" on-close={JS.push("reset", target: @myself)}>
        <.dialog_content class="max-h-[90svh] overflow-y-auto sm:max-w-lg">
          <.dialog_header>
            <.dialog_title>Create a channel</.dialog_title>
            <.dialog_description>
              Channels are where conversations happen around a topic.
            </.dialog_description>
          </.dialog_header>
          <.form
            for={@form}
            id="create-channel-form"
            phx-change="validate"
            phx-submit="create"
            phx-target={@myself}
          >
            <.field_group>
              <.field field={@form[:name]}>
                <.field_label for="new-channel-name">Name</.field_label>
                <.input_group id="new-channel-name-group">
                  <.input_group_input
                    id="new-channel-name"
                    name={@form[:name].name}
                    value={@form[:name].value}
                    aria-invalid={@form[:name].errors != [] && "true"}
                    placeholder="e.g. plan-the-offsite"
                    autocomplete="off"
                    phx-debounce="200"
                  />
                  <.input_group_addon>
                    <.icon name={
                      if @params["private"] == "true", do: "hero-lock-closed", else: "hero-hashtag"
                    } />
                  </.input_group_addon>
                </.input_group>
                <.field_description>Lowercase, without spaces. Max 40 characters.</.field_description>
                <.field_error field={@form[:name]} />
              </.field>
              <.field field={@form[:description]}>
                <.field_label field={@form[:description]}>
                  Description <span class="font-normal text-muted-foreground">(optional)</span>
                </.field_label>
                <.textarea
                  field={@form[:description]}
                  rows="2"
                  placeholder="What's this channel about?"
                />
                <.field_error field={@form[:description]} />
              </.field>
              <.field orientation="horizontal">
                <.field_content>
                  <.field_label for="new-channel-private-input">Make private</.field_label>
                  <.field_description>Only invited members can find and read it.</.field_description>
                </.field_content>
                <.switch
                  id="new-channel-private"
                  name={@form[:private].name}
                  value={@params["private"]}
                />
              </.field>
              <.field_set>
                <.field_legend variant="label">Add people</.field_legend>
                <.field_description>
                  {MapSet.size(@chosen)} selected. Sprout joins every channel.
                </.field_description>
                <%!-- TODO(salad-pass-2): use combobox (multi-select with search) for the member picker --%>
                <.scroll_area class="max-h-56 rounded-md border">
                  <.item_group>
                    <.item :for={u <- @people} size="sm" class="rounded-none">
                      <.item_media>
                        <.user_avatar user={u} size="sm" />
                      </.item_media>
                      <.item_content>
                        <.item_title>
                          <label for={"new-channel-member-#{u.handle}"} class="cursor-pointer">
                            {u.name}
                          </label>
                        </.item_title>
                        <.item_description>{u.title}</.item_description>
                      </.item_content>
                      <.item_actions>
                        <.checkbox
                          id={"new-channel-member-#{u.handle}"}
                          name={"channel[members][#{u.handle}]"}
                          value={MapSet.member?(@chosen, u.handle)}
                          aria-label={"Add #{u.name}"}
                        />
                      </.item_actions>
                    </.item>
                  </.item_group>
                </.scroll_area>
              </.field_set>
            </.field_group>
            <.dialog_footer class="mt-6">
              <.dialog_close>
                <.button type="button" variant="outline">Cancel</.button>
              </.dialog_close>
              <.button type="submit" phx-disable-with="Creating…">Create channel</.button>
            </.dialog_footer>
          </.form>
        </.dialog_content>
      </.dialog>
    </div>
    """
  end
end
