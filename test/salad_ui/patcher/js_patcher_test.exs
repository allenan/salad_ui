defmodule SaladUI.Patcher.JSPatcherTest do
  use ExUnit.Case

  alias SaladUI.Patcher.JSPatcher

  describe "patch_js/3" do
    test "adds imports after the last import and registers hooks" do
      js_content = """
      import {Socket} from \"phoenix\";
      import {LiveSocket} from \"phoenix_live_view\";

      let liveSocket = new LiveSocket(\"/live\", Socket, {params: {_csrf_token: csrfToken}})
      """

      import_content = "import SaladUI from \"salad_ui\";\n"
      hooks = "SaladUI: SaladUI.SaladUIHook"

      patched_content = JSPatcher.patch_js(js_content, import_content, hooks)

      assert patched_content =~ ~s(import {LiveSocket} from "phoenix_live_view";\nimport SaladUI from "salad_ui";)
      assert patched_content =~ "hooks: { SaladUI: SaladUI.SaladUIHook }"
    end

    test "adds hooks to existing hooks object without duplicating existing hook" do
      js_content = """
      import {LiveSocket} from \"phoenix_live_view\";

      let liveSocket = new LiveSocket(\"/live\", Socket, {
        hooks: {Existing: ExistingHook}
      })
      """

      patched_content = JSPatcher.patch_js(js_content, "", "SaladUI: SaladUI.SaladUIHook")
      repatched_content = JSPatcher.patch_js(patched_content, "", "SaladUI: SaladUI.SaladUIHook")

      assert patched_content =~ "Existing: ExistingHook"
      assert patched_content =~ "SaladUI: SaladUI.SaladUIHook"
      assert repatched_content == patched_content
    end

    # Verbatim from phoenix 1.8 installer/templates/phx_assets/app.js
    @phoenix_1_8_app_js """
    import "phoenix_html"
    import {Socket} from "phoenix"
    import {LiveSocket} from "phoenix_live_view"
    import {hooks as colocatedHooks} from "phoenix-colocated/my_app"
    import topbar from "../vendor/topbar"

    const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
    const liveSocket = new LiveSocket("/live", Socket, {
      longPollFallbackMs: 2500,
      params: {_csrf_token: csrfToken},
      hooks: {...colocatedHooks},
    })

    liveSocket.connect()
    """

    test "patches a Phoenix 1.8 app.js (const liveSocket, spread hooks, trailing commas)" do
      patched =
        JSPatcher.patch_js(@phoenix_1_8_app_js, "import SaladUI from \"salad_ui\";\n", "SaladUI: SaladUI.SaladUIHook")

      assert patched =~ ~s(import SaladUI from "salad_ui";)
      assert patched =~ ~r/hooks: \{\.\.\.colocatedHooks,\s*SaladUI: SaladUI\.SaladUIHook\}/
      refute patched =~ ~r/,\s*,/
      assert JSPatcher.patch_js(patched, "", "SaladUI: SaladUI.SaladUIHook") == patched
    end

    test "re-running with the same imports is a no-op" do
      imports = ~s(import SaladUI from "salad_ui";\nimport "salad_ui/components/dialog";\n)
      hooks = "SaladUI: SaladUI.SaladUIHook"

      once = JSPatcher.patch_js(@phoenix_1_8_app_js, imports, hooks)

      assert JSPatcher.patch_js(once, imports, hooks) == once
      assert once |> String.split("salad_ui/components/dialog") |> length() == 2
    end

    test "adds a hooks object to a const liveSocket with a trailing comma and no hooks" do
      js_content = """
      const liveSocket = new LiveSocket('/live', Socket, {
        params: {_csrf_token: csrfToken},
      })
      """

      patched = JSPatcher.patch_js(js_content, "", "SaladUI: SaladUI.SaladUIHook")

      assert patched =~ "hooks: { SaladUI: SaladUI.SaladUIHook }"
      refute patched =~ ~r/,\s*,/
    end
  end
end
