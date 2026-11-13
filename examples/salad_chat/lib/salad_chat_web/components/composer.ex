defmodule SaladChatWeb.Composer do
  @moduledoc """
  The message composer: an input group around a textarea, with attachment
  upload, an emoji popover, slash command suggestions, keyboard hints and the
  typing indicator.
  """
  use SaladChatWeb, :html

  import SaladChatWeb.MessageComponents, only: [emoji_grid: 1, typing_indicator: 1]

  @commands [
    {"/shrug", "[message]", "Append ¯\\_(ツ)_/¯ to your message"},
    {"/me", "<action>", "Say something in the third person"},
    {"/topic", "<text>", "Set the channel topic"},
    {"/sprout", "<question>", "Ask Sprout here, in this conversation"},
    {"/theme", "light | dark | system", "Switch the color theme"}
  ]

  def commands, do: @commands

  @doc "Slash commands matching what the user typed (`/` shows them all)."
  def matching_commands("/" <> rest = body) do
    if String.contains?(body, [" ", "\n"]),
      do: [],
      else: Enum.filter(@commands, fn {name, _, _} -> String.starts_with?(name, "/" <> rest) end)
  end

  def matching_commands(_), do: []

  attr :id, :string, required: true
  attr :form, :any, required: true
  attr :placeholder, :string, default: "Message"
  attr :event, :string, default: "send"
  attr :upload, :any, default: nil, doc: "an upload config (@uploads.name) to enable attachments"
  attr :slash, :list, default: []
  attr :typing, :list, default: []
  attr :class, :string, default: nil

  def composer(assigns) do
    ~H"""
    <div class={["relative px-3 pb-1 sm:px-4", @class]}>
      <div
        :if={@slash != []}
        class="absolute inset-x-3 bottom-full z-20 mb-1 overflow-hidden rounded-lg border bg-popover shadow-lg sm:inset-x-4"
      >
        <.command id={"#{@id}-commands"} class="max-h-64">
          <.command_list>
            <.command_group heading="Commands">
              <.command_item
                :for={{name, args, desc} <- @slash}
                phx-click={
                  JS.dispatch("salad-chat:set-text",
                    to: "##{@id}-input",
                    detail: %{text: name <> " "}
                  )
                }
              >
                <.icon name="hero-command-line" />
                <span class="font-mono font-medium">{name}</span>
                <span class="font-mono text-xs text-muted-foreground">{args}</span>
                <span class="ml-auto hidden truncate text-xs text-muted-foreground sm:block">{desc}</span>
              </.command_item>
            </.command_group>
          </.command_list>
        </.command>
      </div>

      <.form
        for={@form}
        id={"#{@id}-form"}
        phx-submit={@event}
        phx-change="composer_change"
        class="w-full"
      >
        <input type="hidden" name="composer" value={@id} />
        <.input_group
          id={"#{@id}-group"}
          class="rounded-xl bg-background shadow-xs has-[textarea:focus]:ring-[3px]"
          phx-drop-target={@upload && @upload.ref}
        >
          <.input_group_textarea
            id={"#{@id}-input"}
            field={@form[:body]}
            placeholder={@placeholder}
            phx-hook="Composer"
            phx-debounce="150"
            rows="1"
            autocomplete="off"
            aria-label={@placeholder}
            class="chat-text max-h-48 min-h-11 py-3"
          />
          <.input_group_addon :if={@upload && @upload.entries != []} align="block-start">
            <.attachment_group class="w-full pb-1">
              <.attachment_upload_entry
                :for={entry <- @upload.entries}
                entry={entry}
                upload={@upload}
                on_cancel="cancel_upload"
                size="sm"
                class="w-56"
              />
            </.attachment_group>
          </.input_group_addon>
          <.input_group_addon align="block-end" class="gap-1">
            <.tooltip :if={@upload}>
              <.tooltip_trigger>
                <label
                  for={@upload.ref}
                  class={[
                    button_variant(%{variant: "ghost", size: "icon-sm"}),
                    "cursor-pointer rounded-full"
                  ]}
                  aria-label="Attach files"
                >
                  <.icon name="hero-paper-clip" />
                  <.live_file_input upload={@upload} class="sr-only" />
                </label>
              </.tooltip_trigger>
              <.tooltip_content>Attach files</.tooltip_content>
            </.tooltip>
            <.popover id={"#{@id}-emoji"}>
              <.popover_trigger
                as={&input_group_button/1}
                size="icon-sm"
                class="rounded-full"
                aria-label="Insert emoji"
              >
                <.icon name="hero-face-smile" />
              </.popover_trigger>
              <.popover_content side="top" align="start" class="w-64 p-2">
                <.emoji_grid on_pick={
                  fn e ->
                    JS.dispatch("salad-chat:insert", to: "##{@id}-input", detail: %{text: e})
                  end
                } />
              </.popover_content>
            </.popover>
            <.tooltip>
              <.tooltip_trigger>
                <.input_group_button
                  size="icon-sm"
                  class="rounded-full"
                  aria-label="Slash commands"
                  phx-click={
                    JS.dispatch("salad-chat:set-text", to: "##{@id}-input", detail: %{text: "/"})
                  }
                >
                  <.icon name="hero-command-line" />
                </.input_group_button>
              </.tooltip_trigger>
              <.tooltip_content>
                Commands
                <.kbd>/</.kbd>
              </.tooltip_content>
            </.tooltip>
            <.input_group_text class="ml-auto hidden gap-1 text-xs sm:flex">
              <.kbd>Enter</.kbd>
              to send <span class="mx-0.5">·</span>
              <.kbd_group>
                <.kbd>Shift</.kbd><.kbd>Enter</.kbd>
              </.kbd_group>
              for newline
            </.input_group_text>
            <.input_group_button
              type="submit"
              variant="default"
              size="icon-sm"
              class="ml-auto rounded-full sm:ml-1"
              aria-label="Send"
            >
              <.icon name="hero-paper-airplane-solid" />
            </.input_group_button>
          </.input_group_addon>
        </.input_group>
      </.form>
      <.typing_indicator names={@typing} />
    </div>
    """
  end
end
