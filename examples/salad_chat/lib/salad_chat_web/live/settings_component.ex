defmodule SaladChatWeb.SettingsComponent do
  @moduledoc """
  The settings dialog: profile, notifications and appearance, in tabs. The
  form is a plain map (`to_form/2`), validated on change without a changeset.
  """
  use SaladChatWeb, :live_component

  import SaladChatWeb.People

  alias SaladChat.Chat
  alias SaladChat.Chat.Timezones

  @limits %{"name" => 40, "title" => 60, "status_text" => 80, "bio" => 160}

  @impl true
  def update(%{me: me} = assigns, socket) do
    socket = assign(socket, assigns)

    socket =
      if socket.assigns[:loaded_for] != me,
        do: socket |> assign(:loaded_for, me) |> assign_form(params_for(me), []),
        else: socket

    {:ok, socket}
  end

  defp params_for(me) do
    %{
      "name" => me.name,
      "title" => me.title,
      "status" => me.status,
      "status_text" => me.status_text || "",
      "bio" => me.bio,
      "timezone" => me.timezone,
      "theme" => me.prefs.theme,
      "font_size" => to_string(me.prefs.font_size),
      "notify_desktop" => to_string(me.prefs.notify_desktop),
      "notify_mentions" => to_string(me.prefs.notify_mentions),
      "notify_sounds" => to_string(me.prefs.notify_sounds),
      "email_digest" => to_string(me.prefs.email_digest)
    }
  end

  defp assign_form(socket, params, errors) do
    socket
    |> assign(:params, params)
    |> assign(:form, to_form(params, as: :profile, errors: errors))
  end

  @doc "Validates profile params. Returns a keyword list of `{message, opts}` errors."
  def validate(params) do
    required =
      if String.trim(params["name"] || "") == "", do: [name: {"can't be blank", []}], else: []

    lengths =
      for {key, max} <- @limits,
          String.length(params[key] || "") > max,
          do:
            {String.to_existing_atom(key),
             {"should be at most %{count} characters", [count: max]}}

    timezone =
      if params["timezone"] in Timezones.keys(),
        do: [],
        else: [timezone: {"pick a timezone from the list", []}]

    required ++ lengths ++ timezone
  end

  @impl true
  def handle_event("validate", %{"profile" => params}, socket) do
    params = Map.merge(socket.assigns.params, params)

    socket =
      if params["theme"] != socket.assigns.params["theme"],
        do: push_event(socket, "set-theme", %{theme: params["theme"]}),
        else: socket

    {:noreply, assign_form(socket, params, validate(params))}
  end

  def handle_event("save", %{"profile" => params}, socket) do
    params = Map.merge(socket.assigns.params, params)

    case validate(params) do
      [] ->
        me = socket.assigns.me

        {:ok, _} =
          Chat.update_user(me.handle, %{
            name: String.trim(params["name"]),
            title: String.trim(params["title"]),
            bio: String.trim(params["bio"]),
            status: params["status"],
            status_text: blank_to_nil(params["status_text"]),
            timezone: params["timezone"]
          })

        {:ok, user} =
          Chat.update_prefs(me.handle, %{
            theme: params["theme"],
            font_size:
              params["font_size"]
              |> to_string()
              |> Integer.parse()
              |> elem(0)
              |> max(12)
              |> min(18),
            notify_desktop: params["notify_desktop"] == "true",
            notify_mentions: params["notify_mentions"] == "true",
            notify_sounds: params["notify_sounds"] == "true",
            email_digest: params["email_digest"] == "true"
          })

        send(self(), {:settings_saved, user})
        {:noreply, SaladUI.LiveView.send_command(socket, "settings-dialog", "close")}

      errors ->
        {:noreply, assign_form(socket, params, errors)}
    end
  end

  def handle_event("reset", _, socket) do
    socket = assign_form(socket, params_for(socket.assigns.me), [])
    {:noreply, push_event(socket, "set-theme", %{theme: socket.assigns.me.prefs.theme})}
  end

  defp blank_to_nil(value) do
    case String.trim(value || "") do
      "" -> nil
      v -> v
    end
  end

  defp font_size(params),
    do: params["font_size"] |> to_string() |> Integer.parse() |> then(fn {n, _} -> n end)

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :font_size, font_size(assigns.params))

    ~H"""
    <div>
      <.dialog id="settings-dialog" on-close={JS.push("reset", target: @myself)}>
        <.dialog_content class="max-h-[90svh] overflow-y-auto sm:max-w-xl">
          <.dialog_header>
            <.dialog_title>Preferences</.dialog_title>
            <.dialog_description>
              Changes apply to {@me.name} only and reset when the server restarts.
            </.dialog_description>
          </.dialog_header>

          <.form
            for={@form}
            id="settings-form"
            phx-change="validate"
            phx-submit="save"
            phx-target={@myself}
            class="flex flex-col gap-6"
          >
            <.tabs id="settings-tabs" default="profile">
              <.tabs_list class="w-full">
                <.tabs_trigger value="profile" class="flex-1">
                  <.icon name="hero-user" /> Profile
                </.tabs_trigger>
                <.tabs_trigger value="notifications" class="flex-1">
                  <.icon name="hero-bell" /> Notifications
                </.tabs_trigger>
                <.tabs_trigger value="appearance" class="flex-1">
                  <.icon name="hero-paint-brush" /> Appearance
                </.tabs_trigger>
              </.tabs_list>

              <.tabs_content value="profile" class="pt-4">
                <.field_group>
                  <div class="flex items-center gap-4">
                    <.user_avatar user={@me} size="lg" class="size-14" />
                    <div class="text-sm text-muted-foreground">
                      <p class="font-medium text-foreground">@{@me.handle}</p>
                      <p>Avatars come from the seed data in this demo.</p>
                    </div>
                  </div>
                  <div class="grid gap-4 sm:grid-cols-2">
                    <.field field={@form[:name]}>
                      <.field_label field={@form[:name]}>Display name</.field_label>
                      <.input field={@form[:name]} autocomplete="off" />
                      <.field_error field={@form[:name]} />
                    </.field>
                    <.field field={@form[:title]}>
                      <.field_label field={@form[:title]}>Title</.field_label>
                      <.input field={@form[:title]} autocomplete="off" />
                      <.field_error field={@form[:title]} />
                    </.field>
                  </div>
                  <div class="grid gap-4 sm:grid-cols-2">
                    <.field field={@form[:status]}>
                      <.field_label>Status</.field_label>
                      <.select id="settings-status" field={@form[:status]}>
                        <.select_trigger class="w-full">
                          <.select_value placeholder="Pick a status" />
                        </.select_trigger>
                        <.select_content>
                          <.select_item :for={{value, label, dot} <- statuses()} value={value}>
                            <span class={["size-2 rounded-full", dot]} /> {label}
                          </.select_item>
                        </.select_content>
                      </.select>
                    </.field>
                    <.field field={@form[:timezone]}>
                      <.field_label field={@form[:timezone]}>Timezone</.field_label>
                      <.native_select field={@form[:timezone]} options={Timezones.options()} />
                      <.field_error field={@form[:timezone]} />
                    </.field>
                  </div>
                  <.field field={@form[:status_text]}>
                    <.field_label field={@form[:status_text]}>What are you up to?</.field_label>
                    <.input
                      field={@form[:status_text]}
                      placeholder="e.g. Heads down on the composer"
                      autocomplete="off"
                    />
                    <.field_error field={@form[:status_text]} />
                  </.field>
                  <.field field={@form[:bio]}>
                    <.field_label field={@form[:bio]}>Bio</.field_label>
                    <.textarea field={@form[:bio]} rows="3" />
                    <.field_description>
                      {String.length(@params["bio"] || "")}/160 characters
                    </.field_description>
                    <.field_error field={@form[:bio]} />
                  </.field>
                </.field_group>
              </.tabs_content>

              <.tabs_content value="notifications" class="pt-4">
                <.field_set>
                  <.field_legend variant="label">Notify me about</.field_legend>
                  <.field_group class="gap-4">
                    <.notify_switch
                      form={@form}
                      key={:notify_mentions}
                      title="Mentions and DMs"
                      desc="Show a toast when someone @mentions you or sends a DM."
                    />
                    <.notify_switch
                      form={@form}
                      key={:notify_desktop}
                      title="Desktop notifications"
                      desc="Pretend to send desktop notifications. It's a demo."
                    />
                    <.notify_switch
                      form={@form}
                      key={:notify_sounds}
                      title="Sounds"
                      desc="A gentle pop for new messages."
                    />
                    <.field_separator />
                    <.notify_switch
                      form={@form}
                      key={:email_digest}
                      title="Weekly email digest"
                      desc="A summary of what you missed, every Monday."
                    />
                  </.field_group>
                </.field_set>
              </.tabs_content>

              <.tabs_content value="appearance" class="pt-4">
                <.field_group>
                  <.field_set>
                    <.field_legend variant="label">Theme</.field_legend>
                    <.radio_group
                      id="settings-theme"
                      field={@form[:theme]}
                      class="grid grid-cols-3 gap-3"
                    >
                      <.field_label
                        :for={
                          {value, label, icon} <- [
                            {"light", "Light", "hero-sun"},
                            {"dark", "Dark", "hero-moon"},
                            {"system", "System", "hero-computer-desktop"}
                          ]
                        }
                        for={"theme-#{value}"}
                      >
                        <.field orientation="horizontal" class="items-center">
                          <.radio_group_item id={"theme-#{value}"} value={value} />
                          <.field_content>
                            <.field_title><.icon name={icon} class="size-4" /> {label}</.field_title>
                          </.field_content>
                        </.field>
                      </.field_label>
                    </.radio_group>
                  </.field_set>
                  <.field>
                    <div class="flex items-center justify-between">
                      <.field_title>Message font size</.field_title>
                      <span class="text-sm tabular-nums text-muted-foreground">{@font_size}px</span>
                    </div>
                    <.slider
                      id="settings-font-size"
                      name={@form[:font_size].name}
                      value={@font_size}
                      min={12}
                      max={18}
                      step={1}
                      aria-label="Message font size"
                    />
                    <p
                      class="rounded-md border bg-muted/40 px-3 py-2"
                      style={"font-size: #{@font_size}px"}
                    >
                      The quick brown fox jumps over the lazy dog. 🌱
                    </p>
                  </.field>
                </.field_group>
              </.tabs_content>
            </.tabs>

            <.dialog_footer>
              <.dialog_close>
                <.button type="button" variant="outline">Cancel</.button>
              </.dialog_close>
              <.button type="submit" phx-disable-with="Saving…">Save changes</.button>
            </.dialog_footer>
          </.form>
        </.dialog_content>
      </.dialog>
    </div>
    """
  end

  attr :form, :any, required: true
  attr :key, :atom, required: true
  attr :title, :string, required: true
  attr :desc, :string, required: true

  defp notify_switch(assigns) do
    ~H"""
    <.field orientation="horizontal">
      <.field_content>
        <.field_label for={"pref-#{@key}-input"}>{@title}</.field_label>
        <.field_description>{@desc}</.field_description>
      </.field_content>
      <.switch id={"pref-#{@key}"} field={@form[@key]} />
    </.field>
    """
  end
end
