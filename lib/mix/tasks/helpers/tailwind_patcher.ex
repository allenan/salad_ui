defmodule SaladUI.Patcher.TailwindPatcher do
  @moduledoc false

  @theme_block """
  @theme inline {
    --radius-sm: calc(var(--radius) * 0.6);
    --radius-md: calc(var(--radius) * 0.8);
    --radius-lg: var(--radius);
    --radius-xl: calc(var(--radius) * 1.4);
    --radius-2xl: calc(var(--radius) * 1.8);
    --radius-3xl: calc(var(--radius) * 2.2);
    --radius-4xl: calc(var(--radius) * 2.6);
    --color-accent: var(--accent);
    --color-accent-foreground: var(--accent-foreground);
    --color-background: var(--background);
    --color-border: var(--border);
    --color-card: var(--card);
    --color-card-foreground: var(--card-foreground);
    --color-destructive: var(--destructive);
    --color-destructive-foreground: var(--destructive-foreground);
    --color-foreground: var(--foreground);
    --color-input: var(--input);
    --color-muted: var(--muted);
    --color-muted-foreground: var(--muted-foreground);
    --color-popover: var(--popover);
    --color-popover-foreground: var(--popover-foreground);
    --color-primary: var(--primary);
    --color-primary-foreground: var(--primary-foreground);
    --color-ring: var(--ring);
    --color-secondary: var(--secondary);
    --color-secondary-foreground: var(--secondary-foreground);
    --color-chart-1: var(--chart-1);
    --color-chart-2: var(--chart-2);
    --color-chart-3: var(--chart-3);
    --color-chart-4: var(--chart-4);
    --color-chart-5: var(--chart-5);
    --color-sidebar: var(--sidebar, var(--sidebar-background));
    --color-sidebar-foreground: var(--sidebar-foreground);
    --color-sidebar-primary: var(--sidebar-primary);
    --color-sidebar-primary-foreground: var(--sidebar-primary-foreground);
    --color-sidebar-accent: var(--sidebar-accent);
    --color-sidebar-accent-foreground: var(--sidebar-accent-foreground);
    --color-sidebar-border: var(--sidebar-border);
    --color-sidebar-ring: var(--sidebar-ring);
  }
  """

  # shadcn's theme CSS names the sidebar background `--sidebar`; SaladUI
  # color schemes used to call it `--sidebar-background`. The theme reads
  # `--sidebar` first and falls back to the old name, and `patch/2` upgrades
  # an existing theme block that still reads only the old name.
  @legacy_sidebar_token "--color-sidebar: var(--sidebar-background);"
  @sidebar_token "--color-sidebar: var(--sidebar, var(--sidebar-background));"

  # `assets/salad_ui` is scanned separately from `lib` because the toast
  # component builds its card/viewport classes at runtime in JS (its DOM is
  # entirely client-constructed) rather than embedding them in HEEx like
  # every other component — without this source, Tailwind never sees those
  # class strings and the toast ships with no styling or transitions.
  # Ties `dark:` to an explicit class/attribute instead of the OS-level
  # prefers-color-scheme media query, matching how the color tokens switch.
  # Covers both the shadcn convention (`.dark`) and Phoenix 1.8's generated
  # theme toggle (`data-theme="dark"`).
  @dark_variant ~s{@custom-variant dark (&:where(.dark, .dark *, [data-theme=dark], [data-theme=dark] *));}

  @directives [
    ~s(@source "../js";),
    ~s(@source "../../lib";),
    ~s(@source "../../deps/salad_ui/lib";),
    ~s(@source "../../deps/salad_ui/assets/salad_ui";),
    ~s(@plugin "@tailwindcss/typography";),
    ~s(@import "../vendor/tw-animate.css";)
  ]

  def patch(css_path, opts \\ []) do
    new_content =
      css_path
      |> File.read!()
      |> update_content(opts)

    File.write!(css_path, new_content)
  end

  @doc """
  Injects a color scheme (contents of `priv/static/assets/colors/<scheme>.css`)
  into `css_path` inside `@layer base`, together with shadcn's base border /
  outline defaults. Idempotent: does nothing if a scheme is already present.
  """
  def patch_color_scheme(css_path, scheme_css) do
    content = File.read!(css_path)

    if String.contains?(content, "--sidebar-ring:") do
      :ok
    else
      File.write!(css_path, append_block(content, color_scheme_block(scheme_css)))
    end
  end

  @doc false
  def color_scheme_block(scheme_css) do
    # Dark tokens apply for `.dark` (shadcn) and `data-theme="dark"` (Phoenix 1.8).
    scheme_css = String.replace(scheme_css, ~r/^\.dark\s*\{/m, ~s(.dark,\n[data-theme="dark"] {))

    """
    @layer base {
    #{String.trim(scheme_css)}

      * {
        @apply border-border outline-ring/50;
      }
    }
    """
  end

  defp update_content(content, _opts) do
    content
    |> replace_v3_imports()
    |> ensure_tailwind_import()
    |> ensure_theme()
    |> upgrade_sidebar_token()
    |> ensure_dark_variant()
    |> ensure_directives()
  end

  defp replace_v3_imports(content) do
    Regex.replace(
      ~r/@import\s+["']tailwindcss\/(base|components|utilities)["'];\n?/,
      content,
      ""
    )
  end

  # Phoenix 1.8 generates `@import "tailwindcss" source(none);`, so match any
  # import of the bare "tailwindcss" entrypoint, with or without modifiers.
  defp ensure_tailwind_import(content) do
    if Regex.match?(~r/@import\s+["']tailwindcss["'][^;]*;/, content) do
      content
    else
      ~s(@import "tailwindcss";) <> "\n" <> content
    end
  end

  defp ensure_theme(content) do
    if String.contains?(content, "--color-background:") do
      content
    else
      append_block(content, @theme_block)
    end
  end

  defp upgrade_sidebar_token(content) do
    String.replace(content, @legacy_sidebar_token, @sidebar_token)
  end

  # Replace any existing `dark` variant (Phoenix 1.8 ships a data-theme-only
  # one) rather than adding a second, conflicting definition.
  defp ensure_dark_variant(content) do
    existing = ~r/@custom-variant\s+dark\s*\([^;]*\);/

    if Regex.match?(existing, content) do
      Regex.replace(existing, content, @dark_variant, global: false)
    else
      append_block(content, @dark_variant)
    end
  end

  defp ensure_directives(content) do
    Enum.reduce(@directives, content, fn directive, acc ->
      if String.contains?(acc, directive), do: acc, else: append_block(acc, directive)
    end)
  end

  defp append_block(content, block) do
    content = String.trim_trailing(content)
    block = String.trim(block)

    content <> "\n\n" <> block <> "\n"
  end
end
