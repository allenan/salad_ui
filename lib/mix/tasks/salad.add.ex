defmodule Mix.Tasks.Salad.Add do
  @shortdoc "Copies selected SaladUI components and their dependencies into your app"
  @moduledoc """
  Copies selected SaladUI components into your app, together with every
  component and JavaScript module they depend on — the counterpart of
  `npx shadcn add`. `mix salad.install` copies everything; `mix salad.add`
  copies only what you ask for, so you can start small and add more later.

  ## Usage

      mix salad.add button
      mix salad.add dialog dropdown-menu sidebar
      mix salad.add data_table --prefix MyAppWeb.UI
      mix salad.add select --color-scheme slate
      mix salad.add dialog --overwrite

  Names are the component file names (`alert_dialog`) and also accept
  kebab-case (`alert-dialog`) or CamelCase (`AlertDialog`). Run with no
  arguments to list them.

  ## Options

    * `--prefix` (or `-p`) - module prefix for the copied components
      (default: `<App>Ui`, e.g. `MyAppUi`). Without it, the prefix of an
      earlier `salad.add`/`salad.install` is reused.
    * `--color-scheme` (or `-c`) - color scheme for the CSS tokens on first
      setup (default: `gray`). See `mix salad.setup` for the list.
    * `--overwrite` (or `-o`) - replace files that already exist. By default
      existing files are kept, since they may hold local changes.

  ## What it does

  1. Runs the same base setup as `mix salad.install` (TwMerge cache, color
     scheme, `salad_ui.css`, Tailwind directives, tw-animate). Safe to repeat.
  2. Resolves dependencies: every `SaladUI.*` module a component uses (e.g.
     `sidebar` pulls in `tooltip`, `input`, `separator`,
     `skeleton`), always including `helpers`.
  3. Copies those modules into `lib/`, rewriting `SaladUI` to the prefix.
     Like `mix salad.install`, files land where Igniter keeps each module
     (`MyAppUi.Button` in `lib/my_app_ui/button.ex`, `MyAppWeb.UI.Button` in
     `lib/my_app_web/ui/button.ex`). Creates the prefix module
     (`use MyAppUi`) importing them, or adds the new imports to it.
     Modules that already exist are kept.
  4. Copies the JavaScript the components need (their hook implementations,
     shared modules like `menu.js`, and only the core modules those import)
     to `assets/js/ui/`, and imports the hook implementations plus
     `SaladUIHook` in `assets/js/app.js`.

  Then add `use MyAppUi` to `html_helpers` in `lib/my_app_web.ex` (or to the
  modules that render components).

  The dependency map is derived from the SaladUI sources, so it covers every
  component without a hand-maintained table.
  """
  use Igniter.Mix.Task

  alias SaladUI.Mix.Tasks.ComponentRegistry
  alias SaladUI.Mix.Tasks.LocalInstaller
  alias SaladUI.Patcher.JSPatcher

  @app_js "assets/js/app.js"
  @js_hooks "SaladUI: SaladUI.SaladUIHook"

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :salad_ui,
      example: "mix salad.add dialog dropdown-menu --prefix MyAppWeb.UI",
      positional: [components: [rest: true, optional: true]],
      schema: [prefix: :string, color_scheme: :string, overwrite: :boolean],
      aliases: [p: :prefix, c: :color_scheme, o: :overwrite]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    opts = igniter.args.options
    registry = ComponentRegistry.load(LocalInstaller.source_root!())

    case plan(registry, igniter.args.positional[:components] || []) do
      {:ok, plan} ->
        igniter
        |> LocalInstaller.setup_base_config(opts[:color_scheme] || "gray", opts[:overwrite] || false)
        |> add_components(registry, plan, opts)

      {:error, message} ->
        Igniter.add_issue(igniter, message)
    end
  end

  @doc false
  # Resolves names to a copy plan, or a user-facing error message.
  def plan(registry, []) do
    {:error,
     """
     No components given. Usage: mix salad.add <component...>

     Available components:
     #{format_names(ComponentRegistry.component_names(registry))}
     """}
  end

  def plan(registry, names) do
    case ComponentRegistry.resolve(registry, names) do
      {:ok, plan} ->
        {:ok, plan}

      {:error, {:unknown, unknown}} ->
        {:error,
         """
         Unknown component(s): #{Enum.join(unknown, ", ")}

         Available components:
         #{format_names(ComponentRegistry.component_names(registry))}
         """}
    end
  end

  defp format_names(names), do: names |> Enum.chunk_every(8) |> Enum.map_join("\n", &Enum.join(&1, ", "))

  @doc false
  # Everything after the base CSS/Tailwind setup (which edits files on disk
  # directly); kept separate so it can run against an in-memory test project.
  def add_components(igniter, registry, plan, opts) do
    lib = lib_files(igniter)
    prefix = opts[:prefix] || existing_prefix(lib) || LocalInstaller.default_prefix(igniter)
    overwrite? = opts[:overwrite] || false
    modules = module_paths(lib)

    {igniter, ex_skipped} = copy_modules(igniter, registry, plan.ex_files, prefix, lib, modules, overwrite?)
    {igniter, js_skipped} = copy_js(igniter, registry, plan.js_files, overwrite?)

    igniter
    |> update_ui_module(registry.root, plan, prefix, modules)
    |> patch_app_js(plan)
    |> notify(plan, prefix, ex_skipped ++ js_skipped)
  end

  # `lib/**/*.ex` as `path => content`, including changes already queued in
  # the igniter. (Read directly rather than via Igniter's module lookup, whose
  # full-project scan doesn't run against in-memory test projects.)
  defp lib_files(igniter) do
    lib_ex? = &(String.starts_with?(&1, "lib/") and String.ends_with?(&1, ".ex"))

    on_disk =
      if igniter.assigns[:test_mode?] do
        Map.filter(igniter.assigns[:test_files], fn {path, _} -> lib_ex?.(path) end)
      else
        "lib/**/*.ex" |> Path.wildcard() |> Map.new(&{&1, File.read!(&1)})
      end

    igniter.rewrite
    |> Rewrite.sources()
    |> Enum.filter(&lib_ex?.(&1.path))
    |> Enum.reduce(on_disk, &Map.put(&2, &1.path, Rewrite.Source.get(&1, :content)))
    |> Map.drop(igniter.rms)
  end

  # Module name (as written in `defmodule`) => path of the file defining it.
  defp module_paths(lib) do
    for {path, content} <- lib,
        [module] <- Regex.scan(~r/^\s*defmodule\s+([\w.]+)\s+do\b/m, content, capture: :all_but_first),
        into: %{},
        do: {module, path}
  end

  # The prefix of an earlier add/install: the module whose `component/0`
  # quote imports its own `.Helpers` (the copied lib/salad_ui.ex).
  @root_module ~r/defmodule\s+([\w.]+)\s+do\b.*?def component do\s+quote do\s+use Phoenix\.Component\s+import \1\.Helpers\b/s

  defp existing_prefix(lib) do
    lib
    |> Enum.sort()
    |> Enum.find_value(fn {_path, content} ->
      case Regex.run(@root_module, content) do
        [_, prefix] -> prefix
        nil -> nil
      end
    end)
  end

  # Where `module` lives, or where Igniter would put it (it moves new files
  # there anyway, as it does for salad.install): `MyAppUi.Button` ->
  # `lib/my_app_ui/button.ex`.
  defp module_path(igniter, modules, module) do
    case Map.fetch(modules, module) do
      {:ok, path} -> {:existing, path}
      :error -> {:new, Igniter.Project.Module.proper_location(igniter, Module.concat([module]))}
    end
  end

  # A module that already exists anywhere is kept (or overwritten in place).
  # Returns the igniter and the kept files that differ from SaladUI's version
  # (local edits, or an older SaladUI); identical ones aren't worth a mention.
  defp copy_modules(igniter, registry, files, prefix, lib, modules, overwrite?) do
    Enum.reduce(files, {igniter, []}, fn file, {igniter, kept} ->
      [main | _] = registry.ex[file].modules

      content =
        [registry.root, "lib/salad_ui", file]
        |> Path.join()
        |> File.read!()
        |> LocalInstaller.transform_component_content(prefix)

      case module_path(igniter, modules, String.replace_prefix(main, "SaladUI", prefix)) do
        {:existing, path} when not overwrite? ->
          {igniter, if(same_code?(lib[path], content), do: kept, else: [path | kept])}

        {_, path} ->
          {LocalInstaller.put_file(igniter, path, content, overwrite?), kept}
      end
    end)
  end

  defp copy_js(igniter, registry, files, overwrite?) do
    Enum.reduce(files, {igniter, []}, fn file, {igniter, kept} ->
      target = Path.join(LocalInstaller.js_dir(), file)
      content = File.read!(Path.join([registry.root, "assets/salad_ui", file]))

      if Igniter.exists?(igniter, target) and not overwrite? do
        {igniter, if(current_content(igniter, target) == content, do: kept, else: [target | kept])}
      else
        {LocalInstaller.put_file(igniter, target, content, overwrite?), kept}
      end
    end)
  end

  # Elixir files are compared as code, since Igniter formats what it writes.
  defp same_code?(existing, content) do
    strip = &Macro.prewalk(&1, fn node -> Macro.update_meta(node, fn _ -> [] end) end)

    with {:ok, a} <- Code.string_to_quoted(existing || ""),
         {:ok, b} <- Code.string_to_quoted(content) do
      strip.(a) == strip.(b)
    else
      _ -> false
    end
  end

  defp current_content(igniter, path) do
    cond do
      Rewrite.has_source?(igniter.rewrite, path) ->
        igniter.rewrite |> Rewrite.source!(path) |> Rewrite.Source.get(:content)

      igniter.assigns[:test_mode?] ->
        igniter.assigns[:test_files][path]

      true ->
        File.read!(path)
    end
  end

  # The root module is lib/salad_ui.ex with `__using__` importing only the
  # copied modules. On later runs the new imports are appended to it.
  @using_block ~r/(defmacro __using__\(_\) do\s*\n\s*quote do\n)(.*?)([ \t]*end\n[ \t]*end)/s
  @import_chunk ~r/^[ \t]*import SaladUI\.([\w.]+)(?:,\n(?:[ \t]{8,}[^\n]*\n)+|\n)/m

  defp update_ui_module(igniter, root, plan, prefix, modules) do
    template = File.read!(Path.join(root, "lib/salad_ui.ex"))
    [_, _, imports, _] = Regex.run(@using_block, template)

    chunks =
      for [chunk, module] <- Regex.scan(@import_chunk, imports),
          "SaladUI.#{module}" in plan.modules,
          do: {module, chunk}

    content =
      template
      |> String.replace(@using_block, fn _ ->
        "defmacro __using__(_) do\n    quote do\n" <> Enum.map_join(chunks, &elem(&1, 1)) <> "    end\n  end"
      end)
      |> LocalInstaller.transform_component_content(prefix)

    {_, path} = module_path(igniter, modules, prefix)

    Igniter.create_or_update_file(igniter, path, content, &add_imports(&1, chunks, prefix))
  end

  defp add_imports(source, chunks, prefix) do
    existing = Rewrite.Source.get(source, :content)
    missing = Enum.reject(chunks, fn {module, _} -> imports?(existing, prefix, module) end)
    added = missing |> Enum.map_join(&elem(&1, 1)) |> LocalInstaller.transform_component_content(prefix)

    cond do
      missing == [] ->
        source

      Regex.match?(@using_block, existing) ->
        append = fn _, head, body, tail -> head <> body <> added <> tail end
        Rewrite.Source.update(source, :content, Regex.replace(@using_block, existing, append, global: false))

      true ->
        {:warning,
         "Could not find `__using__` in #{source.path}; import these modules yourself: " <>
           Enum.map_join(missing, ", ", fn {module, _} -> "#{prefix}.#{module}" end)}
    end
  end

  defp imports?(content, prefix, module) do
    Regex.match?(~r/import\s+#{Regex.escape("#{prefix}.#{module}")}(?![\w.])/, content)
  end

  defp patch_app_js(igniter, %{js_entries: []}), do: igniter

  defp patch_app_js(igniter, plan) do
    js_import =
      Enum.map_join(["index.js" | plan.js_entries], fn
        "index.js" -> ~s(import SaladUI from "./ui/index.js";\n)
        entry -> ~s(import "./ui/#{entry}";\n)
      end)

    if Igniter.exists?(igniter, @app_js) do
      Igniter.update_file(igniter, @app_js, &patch_js_source(&1, js_import))
    else
      Igniter.add_warning(igniter, "#{@app_js} not found; import these yourself:\n#{js_import}")
    end
  end

  defp patch_js_source(source, js_import) do
    content = Rewrite.Source.get(source, :content)

    if String.contains?(content, ~s(from "salad_ui")) do
      {:warning,
       "#{@app_js} imports SaladUI from the salad_ui package (mix salad.setup), so it was " <>
         "left unchanged. Switch it to the local copies:\n#{js_import}"}
    else
      Rewrite.Source.update(source, :content, JSPatcher.patch_js(content, js_import, @js_hooks))
    end
  end

  defp notify(igniter, plan, prefix, skipped) do
    igniter
    |> Igniter.add_notice(
      "SaladUI: added #{Enum.join(plan.components, ", ")}. Use them with `use #{prefix}` " <>
        "(e.g. in html_helpers in your web module)."
    )
    |> then(fn igniter ->
      case skipped do
        [] ->
          igniter

        _ ->
          Igniter.add_notice(
            igniter,
            "Kept existing files that differ from SaladUI's version (pass --overwrite to replace):\n" <>
              Enum.map_join(Enum.reverse(skipped), "\n", &"  * #{&1}")
          )
      end
    end)
    |> then(fn igniter ->
      case plan.packages do
        [] ->
          igniter

        packages ->
          Igniter.add_notice(
            igniter,
            "The copied JavaScript imports npm packages: #{Enum.join(packages, ", ")}. " <>
              "Install them in assets/ (e.g. `npm install #{Enum.join(packages, " ")} --prefix assets`)."
          )
      end
    end)
  end
end
