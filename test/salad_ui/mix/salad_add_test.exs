defmodule Mix.Tasks.Salad.AddTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  alias Mix.Tasks.Salad.Add
  alias SaladUI.Mix.Tasks.ComponentRegistry

  # Igniter keeps a module at the path matching its name.
  @web_ui "lib/demo_web/ui"
  @ui "lib/demo_ui"

  @app_js """
  import "phoenix_html";
  import {Socket} from "phoenix";
  import {LiveSocket} from "phoenix_live_view";

  let liveSocket = new LiveSocket("/live", Socket, {
    longPollFallbackMs: 2500,
    params: {_csrf_token: csrfToken}
  })
  """

  setup_all do
    %{registry: ComponentRegistry.load(File.cwd!())}
  end

  defp project(files \\ %{}) do
    test_project(app_name: :demo, files: Map.merge(%{"assets/js/app.js" => @app_js}, files))
  end

  # Runs everything but the base CSS/Tailwind setup, which edits files on disk
  # and is covered by the installer e2e script.
  defp add(igniter, registry, names, opts \\ []) do
    {:ok, plan} = Add.plan(registry, names)
    Add.add_components(igniter, registry, plan, opts)
  end

  defp content(igniter, path) do
    igniter.rewrite |> Rewrite.source!(path) |> Rewrite.Source.get(:content)
  end

  describe "copying components" do
    test "copies the component, its dependencies and helpers under the prefix", %{registry: registry} do
      igniter = add(project(), registry, ["dropdown-menu", "sidebar"], prefix: "DemoWeb.UI")

      for file <- ~w(dropdown_menu sidebar input separator skeleton helpers) do
        assert_creates(igniter, "#{@web_ui}/#{file}.ex")
      end

      assert_creates(igniter, "lib/demo_web/ui.ex")
      refute_creates(igniter, "#{@web_ui}/dialog.ex")
      refute_creates(igniter, "#{@web_ui}/select.ex")

      sidebar = content(igniter, "#{@web_ui}/sidebar.ex")
      assert sidebar =~ "defmodule DemoWeb.UI.Sidebar do"
      assert sidebar =~ "use DemoWeb.UI, :component"
      assert sidebar =~ "import DemoWeb.UI.Skeleton"
      refute sidebar =~ "SaladUI."
    end

    test "keeps nested modules under their parent", %{registry: registry} do
      igniter = add(project(), registry, ["questionnaire"])

      assert_creates(igniter, "#{@ui}/questionnaire/state.ex")
      assert content(igniter, "#{@ui}/questionnaire/state.ex") =~ "defmodule DemoUi.Questionnaire.State do"
    end

    test "defaults the prefix to <App>Ui", %{registry: registry} do
      igniter = add(project(), registry, ["button"])

      assert content(igniter, "#{@ui}/button.ex") =~ "defmodule DemoUi.Button do"
      assert content(igniter, "lib/demo_ui.ex") =~ "defmodule DemoUi do"
    end

    test "ui.ex imports only the copied modules", %{registry: registry} do
      igniter = add(project(), registry, ["dropdown_menu"], prefix: "DemoWeb.UI")
      ui = content(igniter, "lib/demo_web/ui.ex")

      assert ui =~ "defmodule DemoWeb.UI do"
      assert ui =~ "import DemoWeb.UI.DropdownMenu"
      assert ui =~ "import DemoWeb.UI.Helpers"
      refute ui =~ "import DemoWeb.UI.Sidebar"
      refute ui =~ "SaladUI."
      assert {:ok, _} = Code.string_to_quoted(ui)
    end

    test "keeps the data_table import's only: option", %{registry: registry} do
      ui = project() |> add(registry, ["data_table"]) |> content("lib/demo_ui.ex")

      assert ui =~ ~r/import DemoUi.DataTable,\s+only: \[data_table_column_header: 1/
    end
  end

  describe "JavaScript" do
    test "copies entries, their imports and the core they use", %{registry: registry} do
      igniter = add(project(), registry, ["dropdown_menu"])

      for file <- ~w(index.js components/dropdown_menu.js components/menu.js core/component.js core/hook.js) do
        assert_creates(igniter, "assets/js/ui/#{file}")
      end

      refute_creates(igniter, "assets/js/ui/components/dialog.js")
      assert content(igniter, "assets/js/ui/index.js") == File.read!("assets/salad_ui/index.js")
    end

    test "imports the hook implementations and registers SaladUIHook in app.js", %{registry: registry} do
      app_js = project() |> add(registry, ["drawer"]) |> content("assets/js/app.js")

      assert app_js =~ ~s(import SaladUI from "./ui/index.js";)
      assert app_js =~ ~s(import "./ui/components/drawer.js";)
      # dialog.js is pulled in by drawer.js itself
      refute app_js =~ ~s(import "./ui/components/dialog.js";)
      assert app_js =~ "hooks: { SaladUI: SaladUI.SaladUIHook }"
    end

    test "leaves JS alone for components without client behaviour", %{registry: registry} do
      igniter = add(project(), registry, ["button", "card"])

      refute_creates(igniter, "assets/js/ui/index.js")
      assert_unchanged(igniter, "assets/js/app.js")
    end

    test "does not mix local imports into a salad.setup app.js", %{registry: registry} do
      app_js = ~s(import SaladUI from "salad_ui";\n) <> @app_js

      %{"assets/js/app.js" => app_js}
      |> project()
      |> add(registry, ["dialog"])
      |> assert_unchanged("assets/js/app.js")
      |> assert_has_warning(&(&1 =~ "imports SaladUI from the salad_ui package"))
    end

    test "points out npm packages the copied JS needs", %{registry: registry} do
      project()
      |> add(registry, ["chart"])
      |> assert_has_notice(&(&1 =~ "npm packages: chart.js"))
    end
  end

  describe "running again" do
    test "adds new components next to earlier ones and reuses their prefix", %{registry: registry} do
      igniter =
        project()
        |> add(registry, ["dropdown_menu"], prefix: "DemoWeb.UI")
        |> apply_igniter!()
        |> add(registry, ["tabs"])

      assert_creates(igniter, "#{@web_ui}/tabs.ex")
      assert content(igniter, "#{@web_ui}/tabs.ex") =~ "defmodule DemoWeb.UI.Tabs do"

      ui = content(igniter, "lib/demo_web/ui.ex")
      assert ui =~ "import DemoWeb.UI.DropdownMenu"
      assert ui =~ "import DemoWeb.UI.Tabs"
      [_, using] = String.split(ui, "defmacro __using__(_)")
      assert length(Regex.scan(~r/import DemoWeb.UI.Helpers\b/, using)) == 1
      assert {:ok, _} = Code.string_to_quoted(ui)

      app_js = content(igniter, "assets/js/app.js")
      assert app_js =~ ~s(import "./ui/components/dropdown_menu.js";)
      assert app_js =~ ~s(import "./ui/components/tabs.js";)
      assert length(Regex.scan(~r/SaladUI\.SaladUIHook/, app_js)) == 1

      # helpers.ex etc. were kept, but they match SaladUI's version
      refute Enum.any?(igniter.notices, &(&1 =~ "Kept existing files"))
    end

    test "is a no-op for components that are already there", %{registry: registry} do
      project()
      |> add(registry, ["dialog"])
      |> apply_igniter!()
      |> add(registry, ["dialog"])
      |> assert_unchanged()
    end

    test "keeps local edits unless --overwrite", %{registry: registry} do
      custom = "defmodule DemoUi.Button do\n  # customized\nend\n"
      igniter = project(%{"lib/demo_web/components/ui/button.ex" => custom})

      igniter
      |> add(registry, ["button"])
      |> assert_unchanged("lib/demo_web/components/ui/button.ex")
      |> refute_creates("lib/demo_ui/button.ex")
      |> assert_has_notice(&(&1 =~ "Kept existing files" and &1 =~ "lib/demo_web/components/ui/button.ex"))

      overwritten =
        igniter |> add(registry, ["button"], overwrite: true) |> content("lib/demo_web/components/ui/button.ex")

      assert overwritten =~ "def button(assigns)"
    end
  end

  describe "arguments" do
    test "lists the components when none are given", %{registry: registry} do
      assert {:error, message} = Add.plan(registry, [])
      assert message =~ "Usage: mix salad.add <component...>"
      assert message =~ "dropdown_menu"
    end

    test "rejects unknown components", %{registry: registry} do
      assert {:error, message} = Add.plan(registry, ["dialog", "nope"])
      assert message =~ "Unknown component(s): nope"
    end

    test "the task reports bad names as an issue" do
      project()
      |> Igniter.compose_task("salad.add", ["nope"])
      |> assert_has_issue(&(&1 =~ "Unknown component(s): nope"))
    end
  end
end
