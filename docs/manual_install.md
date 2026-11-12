# Manual installation

`mix salad.setup` does everything below for you. Follow these steps only if you
want to wire SaladUI into a Phoenix app by hand. They assume Tailwind CSS v4
(Phoenix 1.8 ships it) and the oklch theme tokens shadcn/ui uses today.

## 1. Add the dependency

```elixir
# mix.exs
def deps do
  [
    {:salad_ui, "~> 1.0"}
  ]
end
```

Then add `TwMerge.Cache` to your application's supervision tree, before your
endpoint:

```elixir
# lib/my_app/application.ex
children = [
  # ...
  TwMerge.Cache,
  MyAppWeb.Endpoint
]
```

## 2. Configure Tailwind in `assets/css/app.css`

Download [`tw-animate.css`](https://raw.githubusercontent.com/Wombosvideo/tw-animate-css/refs/heads/main/src/tw-animate.css)
into `assets/vendor/tw-animate.css`, then make sure `app.css` has these
directives. Keep anything Phoenix generated that isn't listed here.

```css
@import "tailwindcss";
@import "../vendor/tw-animate.css";

@source "../js";
@source "../../lib";
@source "../../deps/salad_ui/lib";
@source "../../deps/salad_ui/assets/salad_ui";

@plugin "@tailwindcss/typography";

/* `dark:` follows the `.dark` class (shadcn) or Phoenix 1.8's
   `data-theme="dark"` toggle, not the OS preference. */
@custom-variant dark (&:where(.dark, .dark *, [data-theme=dark], [data-theme=dark] *));
```

`deps/salad_ui/assets/salad_ui` is scanned because some components (toast)
build their classes in JavaScript.

If Phoenix generated `@import "tailwindcss" source(none);` keep that line
instead of the plain import, and replace its `@custom-variant dark ...` line
with the one above rather than adding a second.

## 3. Add the theme tokens

Pick a theme at [ui.shadcn.com/themes](https://ui.shadcn.com/themes), click
**Copy code**, and paste the `:root` and `.dark` blocks into `app.css`. This is
shadcn's default `neutral` theme:

```css
:root {
  --radius: 0.625rem;
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --card: oklch(1 0 0);
  --card-foreground: oklch(0.145 0 0);
  --popover: oklch(1 0 0);
  --popover-foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  --secondary: oklch(0.97 0 0);
  --secondary-foreground: oklch(0.205 0 0);
  --muted: oklch(0.97 0 0);
  --muted-foreground: oklch(0.556 0 0);
  --accent: oklch(0.97 0 0);
  --accent-foreground: oklch(0.205 0 0);
  --destructive: oklch(0.577 0.245 27.325);
  --border: oklch(0.922 0 0);
  --input: oklch(0.922 0 0);
  --ring: oklch(0.708 0 0);
  --chart-1: oklch(0.646 0.222 41.116);
  --chart-2: oklch(0.6 0.118 184.704);
  --chart-3: oklch(0.398 0.07 227.392);
  --chart-4: oklch(0.828 0.189 84.429);
  --chart-5: oklch(0.769 0.188 70.08);
  --sidebar: oklch(0.985 0 0);
  --sidebar-foreground: oklch(0.145 0 0);
  --sidebar-primary: oklch(0.205 0 0);
  --sidebar-primary-foreground: oklch(0.985 0 0);
  --sidebar-accent: oklch(0.97 0 0);
  --sidebar-accent-foreground: oklch(0.205 0 0);
  --sidebar-border: oklch(0.922 0 0);
  --sidebar-ring: oklch(0.708 0 0);
}

.dark,
[data-theme="dark"] {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --card: oklch(0.205 0 0);
  --card-foreground: oklch(0.985 0 0);
  --popover: oklch(0.205 0 0);
  --popover-foreground: oklch(0.985 0 0);
  --primary: oklch(0.922 0 0);
  --primary-foreground: oklch(0.205 0 0);
  --secondary: oklch(0.269 0 0);
  --secondary-foreground: oklch(0.985 0 0);
  --muted: oklch(0.269 0 0);
  --muted-foreground: oklch(0.708 0 0);
  --accent: oklch(0.269 0 0);
  --accent-foreground: oklch(0.985 0 0);
  --destructive: oklch(0.704 0.191 22.216);
  --border: oklch(1 0 0 / 10%);
  --input: oklch(1 0 0 / 15%);
  --ring: oklch(0.556 0 0);
  --chart-1: oklch(0.488 0.243 264.376);
  --chart-2: oklch(0.696 0.17 162.48);
  --chart-3: oklch(0.769 0.188 70.08);
  --chart-4: oklch(0.627 0.265 303.9);
  --chart-5: oklch(0.645 0.246 16.439);
  --sidebar: oklch(0.205 0 0);
  --sidebar-foreground: oklch(0.985 0 0);
  --sidebar-primary: oklch(0.488 0.243 264.376);
  --sidebar-primary-foreground: oklch(0.985 0 0);
  --sidebar-accent: oklch(0.269 0 0);
  --sidebar-accent-foreground: oklch(0.985 0 0);
  --sidebar-border: oklch(1 0 0 / 10%);
  --sidebar-ring: oklch(0.556 0 0);
}
```

SaladUI's own color schemes (the ones `mix salad.setup --color-scheme` uses)
live in `deps/salad_ui/priv/static/assets/colors/<name>.css` if you'd rather
paste one of those.

The `[data-theme="dark"]` selector is only needed if you use Phoenix 1.8's
theme toggle. With shadcn's `.dark` class alone, `.dark {` is enough.

## 4. Expose the tokens to Tailwind

Map each token to a Tailwind color with `@theme inline`. The values are already
complete colors, so reference them with a bare `var(--x)`. Don't wrap them in
`hsl(...)`: `hsl(oklch(...))` is invalid CSS and the color silently drops out.

```css
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

@layer base {
  * {
    @apply border-border outline-ring/50;
  }

  body {
    @apply bg-background text-foreground;
  }
}
```

The `@layer base` rule matters: Tailwind v4's preflight makes borders
`currentColor`, so without it every bare `border` renders in the text color.

`--color-sidebar` reads shadcn's `--sidebar` and falls back to
`--sidebar-background`, the name older SaladUI color schemes used, so a theme
written either way works.

## 5. Load the JavaScript

SaladUI's interactive components are driven by one LiveView hook. In
`assets/js/app.js`, import SaladUI plus the components you use, and register
the hook:

```javascript
import SaladUI from "salad_ui";
import "salad_ui/components/dialog";
import "salad_ui/components/dropdown_menu";
// ...one import per interactive component you use

let liveSocket = new LiveSocket("/live", Socket, {
  // ...
  hooks: { SaladUI: SaladUI.SaladUIHook },
});
```

Phoenix's default esbuild config sets `NODE_PATH` to include `deps`, which is
how `import "salad_ui"` resolves.

## 6. Use the components

```elixir
# lib/my_app_web.ex, inside html_helpers/0
import SaladUI.Button
import SaladUI.Dialog
```

### Control a component from the server

Use `SaladUI.LiveView.send_command/4` to send a state transition to a
component, for example to close an open sheet:

```elixir
@impl true
def handle_event("update", params, socket) do
  # your logic
  socket = SaladUI.LiveView.send_command(socket, "my-sheet", "close")
  {:noreply, socket}
end
```
