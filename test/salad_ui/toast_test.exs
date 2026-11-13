defmodule SaladUI.ToastTest do
  use ComponentCase

  import SaladUI.Toast

  alias Phoenix.LiveView.Socket
  alias Phoenix.LiveView.Utils

  defp last_command(%Socket{} = socket) do
    [[event, payload]] = Utils.get_push_events(socket)
    {event, payload}
  end

  describe "toaster/1" do
    test "renders the root, viewport, and default options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" />
        """)

      assert html =~ ~s(id="toaster")
      assert html =~ ~s(data-component="toast")
      assert html =~ ~s(data-part="root")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-part="viewport")
      assert html =~ ~s(data-position="bottom-right")
      # Sonner's structure: a named <section> is the landmark and the polite
      # live region; the <ol> carries no role (axe aria-allowed-role).
      assert html =~ ~r/<section[^>]*id="toaster"/
      assert html =~ ~s(aria-label="Notifications Alt+T")
      assert html =~ ~s(aria-live="polite")
      assert html =~ ~s(aria-relevant="additions text")
      assert html =~ ~s(aria-atomic="false")
      refute html =~ "role="

      assert html =~ ~s(position&quot;:&quot;bottom-right)
      assert html =~ ~s(visibleToasts&quot;:3)
      assert html =~ ~s(gap&quot;:14)
      assert html =~ ~s(hotkey&quot;:&quot;Alt+T)
    end

    test "duration, close-button and hotkey are passed to JS" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" duration={8000} close-button hotkey="Shift+N" />
        """)

      assert html =~ ~s(duration&quot;:8000)
      assert html =~ ~s(closeButton&quot;:true)
      assert html =~ ~s(aria-label="Notifications Shift+N")

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" duration={:infinity} hotkey={nil} />
        """)

      assert html =~ ~s(duration&quot;:&quot;infinity)
      assert html =~ ~s(closeButton&quot;:false)
      assert html =~ ~s(aria-label="Notifications")
    end

    test "bottom-right viewport anchors to the bottom-right offset vars" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" position="bottom-right" />
        """)

      assert html =~ "bottom-[var(--offset-b)]"
      assert html =~ "right-[var(--offset-r)]"
      assert html =~ "--offset-t: 24px"
      assert html =~ "--offset-r: 24px"
      assert html =~ "--offset-b: 24px"
      assert html =~ "--offset-l: 24px"
      assert html =~ "--mobile-offset-t: 16px"
      assert html =~ "--toast-width: 356px"
      assert html =~ "--toast-gap: 14px"
    end

    test "top-left position flips the viewport to flex-col-reverse and left-anchored" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" position="top-left" />
        """)

      assert html =~ "flex-col-reverse"
      assert html =~ "top-[var(--offset-t)]"
      assert html =~ "left-[var(--offset-l)]"
      assert html =~ ~s(data-position="top-left")
    end

    test "top-center / bottom-center anchor to the horizontal midpoint" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" position="top-center" />
        """)

      assert html =~ "left-1/2"
      assert html =~ "-translate-x-1/2"
    end

    test "a single integer offset fans out to all four sides" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" offset={40} mobile-offset={8} />
        """)

      for side <- ~w(t r b l) do
        assert html =~ "--offset-#{side}: 40px"
        assert html =~ "--mobile-offset-#{side}: 8px"
      end
    end

    test "a per-side offset map only overrides the given sides" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" offset={%{top: 10, right: 20}} />
        """)

      assert html =~ "--offset-t: 10px"
      assert html =~ "--offset-r: 20px"
      assert html =~ "--offset-b: 0px"
      assert html =~ "--offset-l: 0px"
    end

    test "a string-keyed offset map (e.g. sourced from params/JSON) is honored the same as atom keys" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" offset={%{"top" => 10, "right" => 20}} />
        """)

      assert html =~ "--offset-t: 10px"
      assert html =~ "--offset-r: 20px"
      assert html =~ "--offset-b: 0px"
      assert html =~ "--offset-l: 0px"
    end

    test "width and gap flow into the style vars and JSON options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" width={420} gap={8} visible-toasts={5} />
        """)

      assert html =~ "--toast-width: 420px"
      assert html =~ "--toast-gap: 8px"
      assert html =~ ~s(gap&quot;:8)
      assert html =~ ~s(visibleToasts&quot;:5)
    end

    test "boolean options are forwarded into data-options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" expand={true} />
        """)

      assert html =~ ~s(expand&quot;:true)
    end

    test "colors forwards a per-variant icon color map into data-options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" colors={%{success: "text-emerald-600", error: "text-rose-600"}} />
        """)

      assert html =~ ~s(colors&quot;:{)
      assert html =~ ~s(&quot;success&quot;:&quot;text-emerald-600&quot;)
      assert html =~ ~s(&quot;error&quot;:&quot;text-rose-600&quot;)
    end

    test "template slots render as hidden <template> parts keyed by name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster">
          <:template name="new-follower">
            <p>Someone followed you</p>
          </:template>
        </.toaster>
        """)

      assert html =~ ~s(<template data-part="toast-template" data-name="new-follower")
      assert html =~ "Someone followed you"
    end

    test "flash renders the bridge as a sibling node, not nested inside the toaster" do
      assigns = %{flash: %{info: "Welcome back"}}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" flash={@flash} />
        """)

      assert html =~ ~s(id="toaster-flash-bridge")
      assert html =~ ~s(data-component="toast-flash")
      assert html =~ ~s(data-toaster="toaster")
      assert html =~ "Welcome back"
    end

    test "omitting flash renders no bridge at all" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toaster id="toaster" />
        """)

      refute html =~ "toast-flash"
    end
  end

  describe "toast_flash/1" do
    test "builds one entry per flash key" do
      assigns = %{flash: %{info: "Saved!", error: "Broke", warning: "Heads up"}}

      html =
        rendered_to_string(~H"""
        <.toast_flash id="bridge" flash={@flash} toaster="toaster" />
        """)

      assert html =~ "Saved!"
      assert html =~ "Broke"
      assert html =~ "Heads up"
    end

    test "empty flash values are skipped" do
      assigns = %{flash: %{info: "", error: nil}}

      html =
        rendered_to_string(~H"""
        <.toast_flash id="bridge" flash={@flash} toaster="toaster" />
        """)

      assert html =~ ~s(data-entries="[]")
    end

    test "string-keyed flash entries (the shape Phoenix's own @flash assign uses) work too" do
      assigns = %{flash: %{"info" => "Saved!"}}

      html =
        rendered_to_string(~H"""
        <.toast_flash id="bridge" flash={@flash} toaster="toaster" />
        """)

      assert html =~ "Saved!"
    end
  end

  describe "toast/2,3,4" do
    test "toast/2 targets the default toaster with a generated id and default variant" do
      {event, payload} = last_command(toast(%Socket{}, "Saved!"))

      assert event == "saladui:command"
      assert payload.target == "toaster"
      assert payload.command == "add"
      assert payload.params.title == "Saved!"
      assert payload.params.variant == "default"
      assert is_binary(payload.params.id)
    end

    test "toast/3 merges opts and stringifies :infinity durations" do
      {_event, payload} =
        last_command(toast(%Socket{}, "Saved!", description: "Changes are live", duration: :infinity))

      assert payload.params.description == "Changes are live"
      assert payload.params.duration == "infinity"
    end

    test "an explicit :id opt is respected instead of generating a new one" do
      {_event, payload} = last_command(toast(%Socket{}, "Saved!", id: "my-id"))

      assert payload.params.id == "my-id"
    end

    test "numeric durations pass through untouched" do
      {_event, payload} = last_command(toast(%Socket{}, "Saved!", duration: 2000))

      assert payload.params.duration == 2000
    end

    test "omitting :duration leaves it out of params entirely" do
      {_event, payload} = last_command(toast(%Socket{}, "Saved!"))

      refute Map.has_key?(payload.params, :duration)
    end

    test "toast/2 with a keyword list (no title) builds a template-style payload" do
      {_event, payload} = last_command(toast(%Socket{}, template: "new-follower", variant: "default"))

      assert payload.params.template == "new-follower"
      refute Map.has_key?(payload.params, :title)
    end

    test "toast/4 targets an explicit toaster id" do
      {_event, payload} = last_command(toast(%Socket{}, "other-toaster", "Hi", []))

      assert payload.target == "other-toaster"
      assert payload.params.title == "Hi"
    end
  end

  describe "put_toast/3,4" do
    test "on a Conn, falls back to Phoenix.Controller.put_flash/3" do
      conn = %Plug.Conn{} |> Plug.Test.init_test_session(%{}) |> Phoenix.Controller.fetch_flash([])

      conn = put_toast(conn, :info, "Welcome!")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Welcome!"
    end

    test "on a Socket, behaves like toast/3 with variant set to the flash kind" do
      {_event, payload} = last_command(put_toast(%Socket{}, :error, "Broke"))

      assert payload.params.variant == "error"
      assert payload.params.title == "Broke"
    end
  end

  describe "toast_success/error/warning/info" do
    test "each sets the matching variant" do
      for {fun, variant} <- [
            {&toast_success/2, "success"},
            {&toast_error/2, "error"},
            {&toast_warning/2, "warning"},
            {&toast_info/2, "info"},
            {&toast_loading/2, "loading"}
          ] do
        {_event, payload} = last_command(fun.(%Socket{}, "msg"))
        assert payload.params.variant == variant
      end
    end

    test "per-toast position and toaster opts" do
      {_event, payload} = last_command(toast_success(%Socket{}, "msg", position: "top-center", toaster: "other"))

      assert payload.target == "other"
      assert payload.params.position == "top-center"
      refute Map.has_key?(payload.params, :toaster)
    end
  end

  describe "toast_loading/3" do
    test "adds a loading toast with no duration of its own (the client keeps it sticky)" do
      {_event, payload} = last_command(toast_loading(%Socket{}, "Loading...", description: "Hang on"))

      assert payload.command == "add"
      assert payload.params.variant == "loading"
      assert payload.params.title == "Loading..."
      assert payload.params.description == "Hang on"
      refute Map.has_key?(payload.params, :duration)
    end

    test "keeps the loading variant for a template-based toast" do
      {_event, payload} = last_command(toast_loading(%Socket{}, template: "upload", toaster: "uploads"))

      assert payload.target == "uploads"
      assert payload.params.variant == "loading"
      assert payload.params.template == "upload"
      refute Map.has_key?(payload.params, :title)
      refute Map.has_key?(payload.params, :toaster)
    end
  end

  describe "toast_promise/3" do
    test "with an id, adds a loading toast under that id and leaves assigns alone" do
      socket = toast_promise(%Socket{}, "create-event", loading: "Loading...", position: "top-right")
      {_event, payload} = last_command(socket)

      assert payload.command == "add"
      assert payload.target == "toaster"
      assert payload.params.id == "create-event"
      assert payload.params.variant == "loading"
      assert payload.params.title == "Loading..."
      assert payload.params.position == "top-right"
      refute Map.has_key?(payload.params, :loading)
      refute Map.has_key?(socket.assigns, :toast_id)
    end

    test "with opts and no :id, generates one and assigns it as :toast_id" do
      socket = toast_promise(%Socket{}, loading: "Saving...")
      {_event, payload} = last_command(socket)

      assert is_binary(socket.assigns.toast_id)
      assert payload.params.id == socket.assigns.toast_id
      assert payload.params.variant == "loading"
    end

    test "with opts and an :id, uses it" do
      {_event, payload} = last_command(toast_promise(%Socket{}, id: "save", loading: "Saving...", toaster: "t2"))

      assert payload.params.id == "save"
      assert payload.target == "t2"
    end

    test "raises without a :loading message" do
      assert_raise ArgumentError, ~r/:loading/, fn -> toast_promise(%Socket{}, "x", []) end
    end
  end

  describe "toast_resolve/4" do
    test "{:ok, value} updates the same id to success, calling a success function with the value" do
      {_event, payload} =
        last_command(
          toast_resolve(%Socket{}, "create-event", {:ok, %{name: "Event"}},
            success: fn data -> "#{data.name} has been created" end,
            error: "Error"
          )
        )

      assert payload.command == "update"
      assert payload.params == %{id: "create-event", variant: "success", title: "Event has been created"}
    end

    test "{:ok, {:ok, value}} unwraps the value" do
      {_event, payload} =
        last_command(toast_resolve(%Socket{}, "x", {:ok, {:ok, 3}}, success: &"#{&1} saved"))

      assert payload.params.title == "3 saved"
    end

    test "{:exit, reason}, {:ok, {:error, reason}} and {:ok, :error} resolve to error" do
      for result <- [{:exit, :boom}, {:ok, {:error, :boom}}, {:ok, :error}] do
        {_event, payload} =
          last_command(toast_resolve(%Socket{}, "x", result, success: "Done", error: "Error"))

        assert payload.command == "update"
        assert payload.params.variant == "error"
        assert payload.params.title == "Error"
      end

      {_event, payload} =
        last_command(toast_resolve(%Socket{}, "x", {:ok, {:error, :timeout}}, error: &"Failed: #{&1}"))

      assert payload.params.title == "Failed: timeout"
    end

    test "a function may return toast_update/3 opts, and extra opts pass through" do
      {_event, payload} =
        last_command(
          toast_resolve(%Socket{}, "x", {:ok, 1},
            success: fn _ -> [message: "Saved", description: "All good"] end,
            duration: 2000,
            toaster: "t2"
          )
        )

      assert payload.target == "t2"
      assert payload.params == %{id: "x", variant: "success", title: "Saved", description: "All good", duration: 2000}
    end

    test "with no message for the settled state, dismisses the toast" do
      {_event, payload} = last_command(toast_resolve(%Socket{}, "x", {:ok, 1}, error: "Error"))

      assert payload.command == "dismiss"
      assert payload.params == %{id: "x"}
    end
  end

  describe "toast_update/3" do
    test "targets the default toaster's update command, keyed by id" do
      {event, payload} = last_command(toast_update(%Socket{}, "export-1", variant: "success", title: "Done"))

      assert event == "saladui:command"
      assert payload.command == "update"
      assert payload.target == "toaster"
      assert payload.params.id == "export-1"
      assert payload.params.variant == "success"
      assert payload.params.title == "Done"
    end

    test ":message sets the title, and omitting :variant keeps the toast's current one" do
      {_event, payload} = last_command(toast_update(%Socket{}, "upload", message: "Uploading 60%"))

      assert payload.params == %{id: "upload", title: "Uploading 60%"}
    end

    test "stringifies the variant and honors toaster:" do
      {_event, payload} = last_command(toast_update(%Socket{}, "x", variant: :error, message: "Error", toaster: "t2"))

      assert payload.target == "t2"
      assert payload.params == %{id: "x", variant: "error", title: "Error"}
    end
  end

  describe "toast_dismiss/3" do
    test "with no args dismisses everything on the default toaster" do
      {_event, payload} = last_command(toast_dismiss(%Socket{}))

      assert payload.target == "toaster"
      assert payload.command == "dismiss"
      assert payload.params == %{}
    end

    test "with an id dismisses just that toast" do
      {_event, payload} = last_command(toast_dismiss(%Socket{}, "toaster", "toast-1"))

      assert payload.params == %{id: "toast-1"}
    end

    test "accepts a custom toaster id" do
      {_event, payload} = last_command(toast_dismiss(%Socket{}, "other-toaster"))

      assert payload.target == "other-toaster"
    end
  end
end
