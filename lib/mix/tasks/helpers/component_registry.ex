defmodule SaladUI.Mix.Tasks.ComponentRegistry do
  @moduledoc false
  # The dependency map behind `mix salad.add`.
  #
  # It is derived from the library source rather than hand-maintained, so a new
  # component (or a new cross-component reference) is picked up without anyone
  # remembering to update a table:
  #
  #   * Elixir deps: every `SaladUI.*` module a component file references in
  #     code or HEEx (docs are stripped first), resolved to the file that
  #     defines it, transitively. `helpers.ex` and `class_merge.ex` are always
  #     included because `use SaladUI, :component` imports the helpers and its
  #     `classes/1` calls `SaladUI.ClassMerge`.
  #   * JS entries: every `data-component` name a selected Elixir file emits,
  #     resolved to the `assets/salad_ui` file that calls
  #     `SaladUI.register("<name>", ...)`.
  #   * JS deps: relative `import`s followed transitively from `index.js` and
  #     the entries (so only the core modules actually used are copied). Bare
  #     specifiers (e.g. `chart.js/auto`) are reported as npm packages.

  defstruct root: nil, ex: %{}, modules: %{}, js: %{}, registrations: %{}

  @type t :: %__MODULE__{}

  @lib_dir "lib/salad_ui"
  @js_dir "assets/salad_ui"
  @always_ex ["class_merge.ex", "helpers.ex"]
  # shadcn names that map onto a differently named SaladUI component.
  @aliases %{"sonner" => "toast"}

  @module_ref ~r/\bSaladUI(?:\.[A-Z]\w*)+/
  @module_def ~r/\bdefmodule\s+(SaladUI(?:\.[A-Z]\w*)+)/
  # `data-component="x"`, `"data-component": "x"` and
  # `data-component={cond && "x"}`; not `[data-component]` selectors.
  @data_component ~r/data-component"?\s*[:=]\s*\{?[^\n"]*?"([a-z][a-z0-9-]*)"/
  @js_import ~r/^\s*import\s+(?:[^'";]*?\s+from\s+)?["']([^"']+)["']/m
  @js_register ~r/SaladUI\.register\(\s*["']([^"']+)["']/

  @doc "Scans the SaladUI source tree at `root` (the package directory)."
  @spec load(Path.t()) :: t()
  def load(root) do
    lib = Path.join(root, @lib_dir)
    js = Path.join(root, @js_dir)

    ex =
      lib
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Map.new(fn path -> {Path.relative_to(path, lib), scan_ex(File.read!(path))} end)

    modules =
      for {file, %{modules: mods}} <- ex, mod <- mods, into: %{}, do: {mod, file}

    js_files =
      js
      |> Path.join("**/*.js")
      |> Path.wildcard()
      |> Map.new(fn path ->
        rel = Path.relative_to(path, js)
        {rel, scan_js(rel, File.read!(path))}
      end)

    registrations =
      for {file, %{registers: names}} <- js_files, name <- names, into: %{}, do: {name, file}

    %__MODULE__{root: root, ex: ex, modules: modules, js: js_files, registrations: registrations}
  end

  @doc "Names accepted by `mix salad.add` (top-level component files)."
  @spec component_names(t()) :: [String.t()]
  def component_names(%__MODULE__{ex: ex}) do
    ex
    |> Map.keys()
    |> Enum.reject(&String.contains?(&1, "/"))
    |> Enum.map(&Path.rootname/1)
    |> Enum.sort()
  end

  @doc """
  Normalizes a user-supplied name (`alert-dialog`, `AlertDialog`,
  `alert_dialog.ex`, shadcn's `sonner`) to a component file stem.
  """
  @spec normalize_name(String.t()) :: String.t()
  def normalize_name(name) do
    stem =
      name
      |> String.trim()
      |> Path.basename(".ex")
      |> Macro.underscore()
      |> String.replace("-", "_")

    Map.get(@aliases, stem, stem)
  end

  @doc """
  Resolves components (by name) to everything that has to be copied.

  Returns `{:ok, plan}` where `plan` has:

    * `:ex_files` - files relative to `lib/salad_ui`
    * `:modules` - modules defined by those files
    * `:js_entries` - JS files to import from `app.js` (relative to `assets/salad_ui`)
    * `:js_files` - every JS file to copy, including `index.js` and core modules
    * `:packages` - npm packages the copied JS imports
  """
  @spec resolve(t(), [String.t()]) :: {:ok, map()} | {:error, {:unknown, [String.t()]}}
  def resolve(%__MODULE__{} = registry, names) do
    stems = names |> Enum.map(&normalize_name/1) |> Enum.uniq()
    available = component_names(registry)

    case Enum.reject(stems, &(&1 in available)) do
      [] -> {:ok, plan(registry, stems)}
      unknown -> {:error, {:unknown, unknown}}
    end
  end

  @doc """
  Module references that don't resolve to any file, as `{file, module}`.
  Should always be empty; a non-empty list means `salad.add` would copy a
  component without something it needs.
  """
  @spec unresolved_refs(t()) :: [{String.t(), String.t()}]
  def unresolved_refs(%__MODULE__{ex: ex} = registry) do
    for {file, %{refs: refs}} <- ex, ref <- refs, is_nil(module_file(registry, ref)), do: {file, ref}
  end

  @doc "`data-component` names with no registered JS, as `{file, name}`."
  @spec unregistered_components(t()) :: [{String.t(), String.t()}]
  def unregistered_components(%__MODULE__{ex: ex, registrations: regs}) do
    for {file, %{components: names}} <- ex,
        name <- names,
        not Map.has_key?(regs, name),
        do: {file, name}
  end

  @doc "Relative JS imports that don't resolve to a file, as `{file, import}`."
  @spec unresolved_js_imports(t()) :: [{String.t(), String.t()}]
  def unresolved_js_imports(%__MODULE__{js: js}) do
    for {file, %{imports: imports}} <- js, import <- imports, not Map.has_key?(js, import), do: {file, import}
  end

  defp plan(registry, stems) do
    ex_files = ex_closure(registry, Enum.map(stems, &(&1 <> ".ex")) ++ @always_ex)

    js_entries =
      ex_files
      |> Enum.flat_map(&registry.ex[&1].components)
      |> Enum.map(&registry.registrations[&1])
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    js_files = if js_entries == [], do: [], else: js_closure(registry, ["index.js" | js_entries])

    %{
      components: stems,
      ex_files: ex_files,
      modules: ex_files |> Enum.flat_map(&registry.ex[&1].modules) |> Enum.sort(),
      js_entries: js_entries,
      js_files: js_files,
      packages: js_files |> Enum.flat_map(&registry.js[&1].packages) |> Enum.uniq() |> Enum.sort()
    }
  end

  defp ex_closure(registry, start) do
    closure(start, fn file ->
      registry.ex[file].refs |> Enum.map(&module_file(registry, &1)) |> Enum.reject(&is_nil/1)
    end)
  end

  defp js_closure(registry, start) do
    closure(start, fn file -> Enum.filter(registry.js[file].imports, &Map.has_key?(registry.js, &1)) end)
  end

  defp closure(start, deps_fun) do
    start |> do_closure(MapSet.new(), deps_fun) |> Enum.sort()
  end

  defp do_closure([], seen, _deps_fun), do: seen

  defp do_closure([file | rest], seen, deps_fun) do
    if MapSet.member?(seen, file) do
      do_closure(rest, seen, deps_fun)
    else
      do_closure(deps_fun.(file) ++ rest, MapSet.put(seen, file), deps_fun)
    end
  end

  # Longest defined prefix wins, so `SaladUI.Calendar.LiveComponent` (nested
  # in calendar.ex) resolves to calendar.ex.
  defp module_file(%__MODULE__{modules: modules}, module) do
    module
    |> String.split(".")
    |> prefixes()
    |> Enum.find_value(&Map.get(modules, &1))
  end

  defp prefixes(parts) do
    for n <- length(parts)..2//-1, do: parts |> Enum.take(n) |> Enum.join(".")
  end

  defp scan_ex(source) do
    code =
      source
      |> Code.string_to_quoted!(columns: false)
      |> strip_docs()
      |> Macro.to_string()

    modules = @module_def |> Regex.scan(code, capture: :all_but_first) |> List.flatten() |> Enum.uniq()

    refs =
      @module_ref
      |> Regex.scan(code)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.reject(&(&1 in modules))

    components =
      @data_component |> Regex.scan(code, capture: :all_but_first) |> List.flatten() |> Enum.uniq()

    %{modules: modules, refs: refs, components: components}
  end

  # Docs mention other modules ("see `SaladUI.LiveView`") without depending on them.
  defp strip_docs(ast) do
    Macro.prewalk(ast, fn
      {:@, meta, [{attr, _, _}]} when attr in [:moduledoc, :doc, :typedoc] -> {:__block__, meta, []}
      {:doc, doc} when is_binary(doc) -> {:doc, nil}
      other -> other
    end)
  end

  defp scan_js(rel, source) do
    specs = @js_import |> Regex.scan(source, capture: :all_but_first) |> List.flatten()
    {relative, packages} = Enum.split_with(specs, &String.starts_with?(&1, "."))
    dir = Path.dirname(rel)

    %{
      imports: relative |> Enum.map(&normalize_js_path(dir, &1)) |> Enum.uniq(),
      packages: packages |> Enum.map(&package_name/1) |> Enum.uniq(),
      registers: @js_register |> Regex.scan(source, capture: :all_but_first) |> List.flatten()
    }
  end

  defp normalize_js_path(dir, spec) do
    dir
    |> Path.join(spec)
    |> Path.split()
    |> Enum.reduce([], fn
      ".", acc -> acc
      "..", [_ | acc] -> acc
      part, acc -> [part | acc]
    end)
    |> Enum.reverse()
    |> Path.join()
  end

  defp package_name("@" <> _ = spec), do: spec |> String.split("/") |> Enum.take(2) |> Enum.join("/")
  defp package_name(spec), do: spec |> String.split("/") |> hd()
end
