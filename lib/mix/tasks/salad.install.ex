if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Salad.Install do
    @moduledoc """
    Install SaladUI components and assets with customizable module prefix and color scheme.

    Copies every component. To copy only some (plus what they depend on), use
    `mix salad.add`.

    ## Usage

        mix salad.install
        mix salad.install --prefix MyUIWeb.Components.UI
        mix salad.install --color-scheme slate
        mix salad.install --prefix CustomComponents --color-scheme blue
    """
    use Igniter.Mix.Task

    alias SaladUI.Mix.Tasks.LocalInstaller

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      # Parse command-line arguments
      {opts, _args} =
        OptionParser.parse!(igniter.args.argv,
          strict: [prefix: :string, color_scheme: :string, yes: :boolean],
          aliases: [p: :prefix, c: :color_scheme, y: :yes]
        )

      prefix = opts[:prefix] || LocalInstaller.default_prefix(igniter)
      color_scheme = opts[:color_scheme] || "gray"
      source_root = LocalInstaller.source_root!()

      igniter
      |> LocalInstaller.setup_base_config(color_scheme)
      |> copy_javascript_files(source_root)
      |> copy_component_files(source_root, prefix)
      |> patch_app_js_with_local_imports()
    end

    # Copy all JavaScript files to assets/js/ui/, with the data they load
    # (the emoji picker's data.json and its DATA_LICENSE.txt).
    defp copy_javascript_files(igniter, source_root) do
      source_dir = Path.join(source_root, "assets/salad_ui")

      source_dir
      |> Path.join("**/*.{js,json,txt}")
      |> Path.wildcard()
      |> Enum.reduce(igniter, fn source_file, acc_igniter ->
        relative_path = Path.relative_to(source_file, source_dir)
        target_file = Path.join(LocalInstaller.js_dir(), relative_path)

        Igniter.create_new_file(acc_igniter, target_file, File.read!(source_file))
      end)
    end

    # Copy all component files to lib/<app>_web/components/ui/
    defp copy_component_files(igniter, source_root, prefix) do
      source_dir = Path.join(source_root, "lib/salad_ui")
      target_dir = LocalInstaller.components_dir(igniter)

      igniter =
        source_dir
        |> Path.join("**/*.ex")
        |> Path.wildcard()
        |> Enum.reduce(igniter, fn source_file, acc_igniter ->
          target_file = Path.join(target_dir, Path.basename(source_file))

          content =
            source_file
            |> File.read!()
            |> LocalInstaller.transform_component_content(prefix)

          Igniter.create_new_file(acc_igniter, target_file, content)
        end)

      # copy root index file
      content =
        source_root
        |> Path.join("lib/salad_ui.ex")
        |> File.read!()
        |> LocalInstaller.transform_component_content(prefix)

      Igniter.create_new_file(igniter, Path.join(target_dir, "ui.ex"), content)
    end

    # Patch app.js with local imports instead of external package imports
    defp patch_app_js_with_local_imports(igniter) do
      app_js_path = "./assets/js/app.js"

      js_import = """
      import SaladUI from "./ui/index.js";
      import "./ui/components/dialog.js";
      import "./ui/components/drawer.js";
      import "./ui/components/select.js";
      import "./ui/components/combobox.js";
      import "./ui/components/command.js";
      import "./ui/components/tabs.js";
      import "./ui/components/carousel.js";
      import "./ui/components/radio_group.js";
      import "./ui/components/popover.js";
      import "./ui/components/hover-card.js";
      import "./ui/components/collapsible.js";
      import "./ui/components/tooltip.js";
      import "./ui/components/accordion.js";
      import "./ui/components/slider.js";
      import "./ui/components/resizable.js";
      import "./ui/components/input_otp.js";
      import "./ui/components/checkbox.js";
      import "./ui/components/switch.js";
      import "./ui/components/dropdown_menu.js";
      import "./ui/components/context_menu.js";
      import "./ui/components/menubar.js";
      import "./ui/components/navigation_menu.js";
      import "./ui/components/toast.js";
      import "./ui/components/toast-flash.js";
      import "./ui/components/input_group.js";
      import "./ui/components/code_block.js";
      import "./ui/components/calendar.js";
      import "./ui/components/questionnaire.js";
      import "./ui/components/message_scroller.js";
      import "./ui/components/toggle.js";
      import "./ui/components/toggle_group.js";
      import "./ui/components/sidebar.js";
      import "./ui/components/emoji_picker.js";
      import "./ui/components/drop_zone.js";
      """

      js_hooks = "SaladUI: SaladUI.SaladUIHook"

      js_content =
        app_js_path
        |> File.read!()
        |> SaladUI.Patcher.JSPatcher.patch_js(js_import, js_hooks)

      File.write!(app_js_path, js_content)

      igniter
    end
  end
else
  defmodule Mix.Tasks.Salad.Install do
    @shortdoc "Copies all SaladUI components into a Phoenix app | Install `igniter` to use"
    @moduledoc """
    Copies all SaladUI components into a Phoenix app.

    This task needs the `igniter` package, which SaladUI lists as an optional
    dependency. Add `{:igniter, "~> 0.6", only: [:dev, :test]}` to your deps
    (or run `mix igniter.install salad_ui`) and try again.
    """
    use Mix.Task

    @impl Mix.Task
    def run(_argv), do: SaladUI.Mix.Tasks.IgniterMissing.run("salad.install")
  end
end
