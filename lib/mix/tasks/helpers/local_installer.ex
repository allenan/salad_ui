defmodule SaladUI.Mix.Tasks.LocalInstaller do
  @moduledoc false
  # Shared by `mix salad.install` (copy everything) and `mix salad.add` (copy
  # selected components): base CSS/Tailwind setup, module-prefix rewriting and
  # locating the SaladUI sources.

  alias SaladUI.Patcher.TailwindPatcher

  @doc "Directory (relative to the app) that local components are copied into."
  def components_dir(igniter), do: "lib/#{app_name(igniter)}_web/components/ui"

  @doc "Directory (relative to the app) that local JS is copied into."
  def js_dir, do: "assets/js/ui"

  @doc "Default module prefix, e.g. `MyAppUi` for app `:my_app`."
  def default_prefix(igniter), do: Phoenix.Naming.camelize("#{app_name(igniter)}_ui")

  @doc """
  Root of the SaladUI package sources (the directory holding `lib/salad_ui`
  and `assets/salad_ui`): the `:salad_ui` dependency, or this checkout when
  SaladUI isn't a dependency (its own test suite).
  """
  def source_root! do
    dep_root() || own_root() || Mix.raise("SaladUI not found in dependencies")
  end

  defp dep_root do
    case Enum.find(Mix.Dep.load_and_cache(), &(&1.app == :salad_ui)) do
      %Mix.Dep{opts: opts} -> opts[:path] || Path.join([File.cwd!(), "deps", "salad_ui"])
      nil -> nil
    end
  end

  defp own_root do
    root = Path.expand("../../../..", __DIR__)
    if File.exists?(Path.join(root, "lib/salad_ui.ex")), do: root
  end

  @doc "Rewrites `SaladUI` module references in copied source to `prefix`."
  def transform_component_content(content, prefix) do
    content
    |> String.replace("defmodule SaladUI", "defmodule #{prefix}")
    |> String.replace("use SaladUI, :component", "use #{prefix}, :component")
    |> String.replace("import SaladUI.", "import #{prefix}.")
    |> String.replace("alias SaladUI.", "alias #{prefix}.")
    |> replace_component_calls_with_prefix(prefix)
  end

  defp replace_component_calls_with_prefix(content, "SaladUI"), do: content
  defp replace_component_calls_with_prefix(content, prefix), do: String.replace(content, "SaladUI.", prefix <> ".")

  @doc """
  TwMerge cache, color scheme, salad_ui.css, Tailwind directives and
  tw-animate. Idempotent: copied files that already exist are kept unless
  `overwrite?` is set.
  """
  def setup_base_config(igniter, color_scheme, overwrite? \\ false) do
    igniter
    |> patch_tw_merge()
    |> patch_css_color_scheme(color_scheme)
    |> put_file("assets/css/salad_ui.css", File.read!(assets_path("salad_ui.css")), overwrite?)
    |> patch_css_import_salad_ui()
    |> patch_tailwind_config()
    |> put_file("assets/tailwind.colors.json", File.read!(assets_path("tailwind.colors.json")), overwrite?)
    |> SaladUI.Mix.Tasks.TwAnimateInstaller.install()
  end

  @doc """
  Creates `path` with `content`. An existing file is left alone (it may hold
  local customizations) unless `overwrite?` is set.
  """
  def put_file(igniter, path, content, overwrite?) do
    cond do
      not Igniter.exists?(igniter, path) -> Igniter.create_new_file(igniter, path, content)
      overwrite? -> Igniter.create_new_file(igniter, path, content, on_exists: :overwrite)
      true -> igniter
    end
  end

  defp patch_tw_merge(igniter) do
    Igniter.Project.Application.add_new_child(igniter, TwMerge.Cache)
  end

  defp patch_css_color_scheme(igniter, color_scheme) do
    css_file = "./assets/css/app.css"
    IO.puts("Patching #{css_file}")

    scheme_css = "colors/#{color_scheme}.css" |> assets_path() |> File.read!()
    TailwindPatcher.patch_color_scheme(css_file, scheme_css)

    igniter
  end

  defp patch_css_import_salad_ui(igniter) do
    css_file = "./assets/css/app.css"
    content = File.read!(css_file)
    import_snippet = "@import \"./salad_ui.css\";\n"

    IO.puts("Patching #{css_file}")
    IO.puts("Add:  #{import_snippet}")

    if !String.contains?(content, import_snippet) do
      imports = Regex.scan(~r/(@import.*?;\n)/, content)

      updated_content =
        case imports do
          [] ->
            import_snippet <> "\n" <> content

          _ ->
            # Insert after the last @import
            last_import = imports |> List.last() |> List.first()
            [before_last_import, after_last_import] = String.split(content, last_import, parts: 2)
            before_last_import <> last_import <> import_snippet <> after_last_import
        end

      File.write(css_file, updated_content)
    end

    igniter
  end

  defp patch_tailwind_config(igniter) do
    TailwindPatcher.patch("./assets/css/app.css")
    igniter
  end

  defp assets_path(file), do: Path.join([:code.priv_dir(:salad_ui), "static/assets", file])

  defp app_name(igniter), do: Igniter.Project.Application.app_name(igniter)
end
