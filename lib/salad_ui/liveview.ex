defmodule SaladUI.LiveView do
  @moduledoc """
  Helper functions for integrating SaladUI components with Phoenix LiveView.

  SaladUI components communicate with LiveView in two directions:

  ## Component events (client → server)

  Interactive components expose `on-*` attributes such as `on-open`, `on-close`,
  `on-value-changed`, and `on-select`. These attributes map component lifecycle or
  interaction events to LiveView handlers.

  Event attributes accept either:

  - a server event name string, pushed with `pushEventTo/3`
  - a `%Phoenix.LiveView.JS{}` command, executed on the component root

  ```heex
  <.sheet
    id="profile-sheet"
    on-open="sheet_opened"
    on-close={JS.push("sheet_closed")}
  >
    ...
  </.sheet>
  ```

  ```elixir
  def handle_event("sheet_opened", params, socket) do
    # params include component metadata such as componentId and component
    {:noreply, socket}
  end

  def handle_event("sheet_closed", _params, socket) do
    {:noreply, socket}
  end
  ```

  Components emit their documented client events when state changes or user
  interactions occur. Common dialog-like events are `open` and `close`.

  ## Server commands (server → client)

  Use `send_command/4` inside LiveView callbacks to control a component by id.
  Commands map to component state-machine transitions or component-specific commands.
  Common commands are `"open"`, `"close"`, and `"toggle"`.

  ```elixir
  def handle_event("open_profile", _params, socket) do
    socket = SaladUI.LiveView.send_command(socket, "profile-sheet", "open")
    {:noreply, socket}
  end

  def handle_event("close_profile", _params, socket) do
    socket = SaladUI.LiveView.send_command(socket, "profile-sheet", "close")
    {:noreply, socket}
  end
  ```

  `send_command/4` pushes the LiveView event `"saladui:command"` to the browser.
  SaladUI's hook receives it, matches `target` against the component root id, and calls
  the component's `handleCommand(command, params)`.

  ## Client-side commands

  Use `SaladUI.JS.dispatch_command/3` when a LiveView JS command should control a
  component directly in the browser.

  ```heex
  <.button phx-click={%JS{} |> SaladUI.JS.dispatch_command("open", to: "#profile-sheet")}>
    Open
  </.button>
  ```

  This dispatches a DOM event named `"salad_ui:command"` on the target element.

  ## Commands from plain JavaScript

  Hooks and other scripts can run the same commands with `SaladUI.command/3`
  from the JS package. It takes the component's root element or a selector,
  the command and optional params, dispatches the same `"salad_ui:command"`
  event, and returns `false` when nothing matches:

  ```javascript
  import SaladUI from "salad_ui";

  SaladUI.command("#emoji-popover", "close");
  SaladUI.command(document.getElementById("bold"), "toggle");
  SaladUI.command("#layout", "collapse", { panel: "side-pane" });
  ```
  """

  @doc """
  Send a command from a LiveView process to a SaladUI component.

  ## Parameters

  - `socket` - LiveView socket.
  - `component_id` - ID of the target component root.
  - `command` - Command or state-machine transition name, such as `"open"`,
    `"close"`, or `"toggle"`.
  - `params` - Optional command payload. Defaults to `%{}`.

  ## Example

  ```elixir
  socket = SaladUI.LiveView.send_command(socket, "dialog", "open")
  ```

  With params:

  ```elixir
  socket = SaladUI.LiveView.send_command(socket, "chart", "update", %{series: data})
  ```

  A shared menu (see "Shared menus" in `SaladUI.DropdownMenu`) opens at an
  `anchor` (a CSS selector) for a `context`:

  ```elixir
  socket =
    SaladUI.LiveView.send_command(socket, "msg-more", "open", %{
      anchor: "#messages-42 [data-salad-for]",
      context: %{id: 42}
    })
  ```
  """
  def send_command(socket, component_id, command, params \\ %{}) do
    Phoenix.LiveView.push_event(socket, "saladui:command", %{
      command: command,
      params: params,
      target: component_id
    })
  end
end

defmodule SaladUI.JS do
  @moduledoc """
  Helper functions for controlling SaladUI components from `Phoenix.LiveView.JS`.
  """

  alias Phoenix.LiveView.JS

  @doc """
  Dispatch a command to a SaladUI component using a LiveView JS command.

  This is useful when client-side UI actions should control another SaladUI
  component without a server round trip.

  ## Parameters

  - `js` - `%Phoenix.LiveView.JS{}` pipeline. Defaults to `%JS{}`.
  - `command_name` - Command or state-machine transition name.
  - `opts` - Options passed to `JS.dispatch/3`. Use `:to` to target a component
    selector and `:detail` for command params. Client commands default to
    `bubbles: false` so nested SaladUI components do not receive the same command.

  ## How it works

  This dispatches a `"salad_ui:command"` DOM custom event. The target SaladUI
  component receives it and calls `handleCommand(command, params)`, same as server
  commands sent by `SaladUI.LiveView.send_command/4`.

  ## Example

  ```heex
  <.button phx-click={%JS{} |> SaladUI.JS.dispatch_command("open", to: "#dialog")}>
    Open dialog
  </.button>
  ```

  With params:

  ```heex
  <.button
    phx-click={
      %JS{}
      |> SaladUI.JS.dispatch_command("update", to: "#chart", detail: %{series: @series})
    }
  >
    Update chart
  </.button>
  ```
  """
  def dispatch_command(command_name) do
    dispatch_command(%JS{}, command_name, [])
  end

  def dispatch_command(command_name, opts) when is_list(opts) do
    dispatch_command(%JS{}, command_name, opts)
  end

  def dispatch_command(%JS{} = js, command_name, opts \\ []) do
    details = %{
      command: command_name,
      params: Keyword.get(opts, :detail, %{}) || %{}
    }

    opts =
      opts
      |> Keyword.put(:detail, details)
      |> Keyword.put_new(:bubbles, false)

    JS.dispatch(js, "salad_ui:command", opts)
  end

  @doc """
  A placeholder for the context of the row a shared menu is open for, in
  the params (`detail`) of `dispatch_command/3` run from one of its items.

  With no key it stands for the whole context map, with a key for one of
  its values (`nil` when the context has no such key). The browser fills it
  in before the target component gets the command, so a JS command can act
  on the row without app JavaScript:

      <.dropdown_menu_item phx-click={
        SaladUI.JS.dispatch_command("open",
          to: "#emoji-picker",
          detail: %{
            anchor: SaladUI.JS.trigger(),
            event: "react",
            values: %{id: SaladUI.JS.context(:id)}
          }
        )
      }>
        Add reaction…
      </.dropdown_menu_item>

  Run from a detached trigger itself (an element with `context`), it stands
  for that trigger's context. Anywhere else it is `nil`. `JS.push/2` needs no
  placeholder: it already sends the item's `phx-value-*`, which hold the
  context while the menu is open (see "Shared menus" in
  `SaladUI.DropdownMenu`).
  """
  def context, do: %{"__salad__" => "context"}

  def context(key) when is_atom(key) or is_binary(key), do: %{"__salad__" => "context", "key" => to_string(key)}

  @doc """
  A placeholder for the trigger element a shared menu is open for (the ⋮
  button, or the row of a context menu), in the params of
  `dispatch_command/3` run from one of its items: e.g. the `anchor` to open
  another component at. See `context/1`.

  With a `selector`, it stands for an element of the trigger instead: the
  trigger itself when it matches, else the first element inside it that
  does, else (nothing matches) the trigger. A context menu's trigger is the
  whole row, which takes no focus; a selector picks the row's own button to
  anchor another popup at and to return focus to, while the same command
  run from a dropdown on that button still gets the button:

      <.context_menu_item phx-click={
        SaladUI.JS.dispatch_command("open",
          to: "#emoji-picker",
          detail: %{
            anchor: SaladUI.JS.trigger("[data-salad-for~='msg-more']"),
            return_focus: SaladUI.JS.trigger("[data-salad-for~='msg-more']"),
            values: %{id: SaladUI.JS.context(:id)}
          }
        )
      }>
        More reactions…
      </.context_menu_item>
  """
  def trigger, do: %{"__salad__" => "trigger"}

  def trigger(selector) when is_binary(selector), do: %{"__salad__" => "trigger", "selector" => selector}

  @doc """
  Copies text to the clipboard (`navigator.clipboard.writeText`), with no app
  JavaScript.

  ## Options

    * `:text` - the text to copy: a string, or a `context/1` placeholder.
    * `:from` - a CSS selector for the element whose text is copied (its
      `innerText`, or `value` for an input or textarea), searched in
      `:within`.
    * `:within` - a CSS selector matched with `closest()` from the row a
      shared menu's item acts for (the menu's trigger), else from the element
      that runs the command. Without it, `:from` is searched in the document,
      and without either the element itself is copied.
    * `:attr` - copy the value of this attribute of that element, as is,
      instead of its text. `innerText` is the text as rendered, which loses
      the source of formatted content (code spans, file cards, mentions):
      render the source into an attribute and copy that.
    * `:on_copied` - what to run once the text is on the clipboard: an event
      name (pushed like `JS.push/2`, from the element that ran the command)
      or a `%JS{}` command, e.g. to toast "Copied".

  From a shared menu, copy the text of the row the menu is open for:

      <.dropdown_menu_item phx-click={
        SaladUI.JS.copy(within: "[data-row]", from: "[data-message-text]")
      }>
        Copy text
      </.dropdown_menu_item>

  Copy the row's source text instead, and toast once it is copied:

      <%!-- in the row: <div data-message-text data-source={@message.body}> --%>
      <.dropdown_menu_item phx-click={
        SaladUI.JS.copy(
          within: "[data-row]",
          from: "[data-message-text]",
          attr: "data-source",
          on_copied: "copied"
        )
      }>
        Copy text
      </.dropdown_menu_item>

      def handle_event("copied", _params, socket),
        do: {:noreply, SaladUI.Toast.toast(socket, "Copied")}

  Anywhere else, e.g. a copy button next to a field:

      <button phx-click={SaladUI.JS.copy(from: "#invite-link")}>Copy link</button>

  It dispatches a bubbling `salad_ui:copy` event that SaladUI's JS handles.
  Once the browser has written the clipboard, the element that ran the
  command dispatches a bubbling `salad_ui:copied` event
  (`detail: %{text: text}`) and `:on_copied` runs. When there is nothing to
  copy, no clipboard, or the browser refuses (an insecure origin, no user
  gesture), it dispatches `salad_ui:copy-failed`
  (`detail: %{text: text, error: reason}`) instead. A command chained after
  `copy/2` runs right away, whether or not the copy works.
  """
  def copy(opts) when is_list(opts), do: copy(%JS{}, opts)

  def copy(%JS{} = js, opts \\ []) do
    detail =
      opts
      |> Keyword.take([:text, :from, :within, :attr])
      |> Map.new()
      |> put_on_copied(Keyword.get(opts, :on_copied))

    JS.dispatch(js, "salad_ui:copy", detail: detail)
  end

  defp put_on_copied(detail, nil), do: detail
  defp put_on_copied(detail, event) when is_binary(event), do: put_on_copied(detail, JS.push(event))
  defp put_on_copied(detail, %JS{ops: ops}), do: Map.put(detail, :on_copied, ops)
end

if !Code.ensure_loaded?(Jason.Encoder.Phoenix.LiveView.JS) do
  defimpl Jason.Encoder, for: Phoenix.LiveView.JS do
    def encode(value, opts) do
      Jason.Encode.list(value.ops, opts)
    end
  end
end
