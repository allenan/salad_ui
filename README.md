<p align="center">
    <a href="https://salad-storybook.fly.dev/" alt="SaladUI Logo">
    <img src="https://github.com/bluzky/salad_ui/blob/main/docs/images/SaladUI_logo.png?raw=true" height="120"/></a>
</p>
<h4 align="center">
    A collection of Live View components inspired by shadcn
</h4>

<div align="center">
    <a href="https://salad-storybook.fly.dev/">Demo</a> |
    <a href="https://hexdocs.pm/salad_ui/readme.html">Documentation</a> |
    <a href="https://ko-fi.com/bluzky">Support project</a>
</div>
<br></br>

<div align="center">
<img src="https://github.com/bluzky/salad_ui/actions/workflows/tests.yml/badge.svg" alt="Tests">
<a href="https://hex.pm/packages/salad_ui"><img src="https://img.shields.io/hexpm/v/salad_ui.svg" alt="Module Version"></a>
<a href="https://hexdocs.pm/salad_ui/"><img src="https://img.shields.io/badge/hex-docs-lightgreen.svg" alt="Hex Docs"></a>
<a href="https://hex.pm/packages/salad_ui"><img src="https://img.shields.io/hexpm/dt/salad_ui.svg" alt="Total Download"></a>
<a href="https://github.com/bluzky/salad_ui/commits/main"><img src="https://img.shields.io/github/last-commit/bluzky/salad_ui.svg" alt="Last Updated"></a>
</div>

![Demo admin](./docs/images/demo.gif)

## [Demo storybook v1](https://salad-storybook.fly.dev/)

<a href='https://ko-fi.com/F1F1CEZ91' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi2.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

## Examples

- [**Salad Chat**](examples/salad_chat/README.md): a Slack-style team chat built
  entirely from SaladUI components: sidebar, threads in a resizable pane,
  reactions, code blocks, attachments, a streaming AI assistant, a ⌘K switcher,
  dialogs, sheets and toasts. No database; run it with
  `cd examples/salad_chat && mix setup && mix phx.server`.

## Installation

1. Add `salad_ui` to your `mix.exs`

```elixir
def deps do
  [
    {:salad_ui, "~> 1.0.0-beta.3"},
  ]
end
```

2. Choose your installation method:

### Method 1: Quick Setup (Using as Library)

For a quick start with minimal configuration:

```bash
mix salad.setup
```

This sets up SaladUI to use components directly from the library. You can start using components immediately:

```elixir
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view
  import SaladUI.Button
  import SaladUI.Dialog

  def render(_) do
    ~H"""
    <.button>Click me</.button>
    <.dialog id="my-dialog">
      <.dialog_content>
        <p>Hello world!</p>
      </.dialog_content>
    </.dialog>
    """
  end
end
```

### Method 2: Local Installation (Customizable)

For full customization with local component files:

```bash
# Default installation
mix salad.install

# With custom prefix and color scheme
mix salad.install --prefix MyUI --color-scheme slate
```

This copies all component files to your project under `lib/my_app_web/components/ui/` where you can customize them:

```elixir
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view
  import MyAppWeb.Components.UI.Button
  import MyAppWeb.Components.UI.Dialog

  def render(_) do
    ~H"""
    <.button>Click me</.button>
    <.dialog id="my-dialog">
      <.dialog_content>
        <p>Hello world!</p>
      </.dialog_content>
    </.dialog>
    """
  end
end
```

### Method 3: Add Only the Components You Need

Like `npx shadcn add`: copy selected components plus everything they depend on
(other components, helpers and JavaScript), and add more later.

```bash
mix salad.add button dialog dropdown-menu
mix salad.add sidebar --prefix MyAppWeb.UI --color-scheme slate

# later: the existing prefix is reused, existing files are kept
mix salad.add data-table
```

Then `use MyAppWeb.UI` (or the default `MyAppUi`) wherever you render components.
Run `mix salad.add` with no arguments to list the components, and pass
`--overwrite` to replace files you already have.

## What Each Method Does

### `mix salad.setup`
- ✅ Sets up Tailwind CSS and color schemes
- ✅ Configures JavaScript hooks and components
- ✅ Ready to use immediately
- ❌ Components cannot be customized
- ❌ Uses external package dependencies

### `mix salad.install`
- ✅ Sets up Tailwind CSS and color schemes
- ✅ Copies all component source code locally
- ✅ Copies all JavaScript files locally
- ✅ Full customization possible
- ✅ No external runtime dependencies
- ✅ Custom module prefixes

### `mix salad.add <component...>`
- ✅ Same setup and options as `mix salad.install`
- ✅ Copies only the selected components and their dependencies
- ✅ Imports only the JavaScript those components need
- ✅ Safe to re-run: adds new imports, keeps files you've changed

## More configuration

1. Custom error translate function

```elixir
config :salad_ui, :error_translator_function, {MyAppWeb.CoreComponents, :translate_error}
```

2. Typeset for rendered markdown and chat content (opt-in)

SaladUI ships shadcn's [typeset](https://ui.shadcn.com/docs/typeset) stylesheet. Import it after
Tailwind and SaladUI's CSS, then wrap rendered markdown in a `typeset` container:

```css
/* assets/css/app.css */
@import "../../deps/salad_ui/priv/static/assets/typeset.css";
```

```heex
<div class="typeset">{raw(@html)}</div>
```

Tune it with `--typeset-size`, `--typeset-leading` and `--typeset-flow` (for example
`class="typeset [--typeset-flow:1em]"`). Components such as `code_block` keep their own
styles inside it, and `not-typeset` opts a subtree out. To customise it, copy the file next to
`app.css` instead.

3. Scroll fade utilities

`salad_ui.css` (copied by the installers) includes shadcn's `scroll-fade` utilities: add
`scroll-fade` / `scroll-fade-y` to a vertical scroller, `scroll-fade-x` to a horizontal one, or
an edge utility (`scroll-fade-t`, `-b`, `-l`, `-r`, `-s`, `-e`). Size them with
`scroll-fade-<n>` / `scroll-fade-{t,b,s,e}-<n>` and turn them off with `scroll-fade-none`.

4. Emoji picker dataset

`emoji_picker` (with `drop_zone`, an extra for chat-style apps; shadcn has neither) loads its
dataset, `components/emoji_picker/data.json` (~53 KB, Unicode License V3, see `DATA_LICENSE.txt`
beside it), with a dynamic `import()` the first time a picker opens. To keep it out of the main
bundle, build with code splitting and load `app.js` as a module:

```elixir
# config/config.exs
args: ~w(js/app.js --bundle --splitting --format=esm --target=es2022 --outdir=../priv/static/assets/js ...)
```

```heex
<script defer phx-track-static type="module" src={~p"/assets/js/app.js"}></script>
```

Without splitting esbuild inlines the dataset into `app.js`; the picker still works. Keep Tailwind
from scanning it (emoji names such as "ring" become utilities); the installers add this:

```css
@source not "../../deps/salad_ui/assets/salad_ui/components/emoji_picker";
@source not "../js/ui/components/emoji_picker"; /* mix salad.install / salad.add */
```


## 🛠️ Development

Here is how to start develop SaladUI on local machine.

1. Clone this repo
2. Go into storybook folder
3. Start storybook

```
cd storybook
mix phx.server
```

## Unit Testing

All v1 component are not covered by UnitTest. Currently I'm working on an important project so I don't have much time for this. If you're interested in this project, please help to add Unit Test if possible. 🙏

## List of components

| Component      | v0   | v1   |
|----------------|------|------|
| Accordion      | ✅    | ✅    |
| Alert          | ✅    | ✅     |
| Alert Dialog   | ✅    | ✅    |
| Avatar         | ✅    | ✅     |
| Badge          | ✅    | ✅     |
| Breadcrumb     | ✅    | ✅     |
| Button         | ✅    | ✅     |
| Card           | ✅    | ✅     |
| Carousel       | ❌    |      |
| Checkbox       | ✅    | ✅     |
| Collapsible    | ✅    | ✅    |
| Combobox       | ❌    |      |
| Command        | ❌    | ✅ [@ilyabayel](https://github.com/ilyabayel)     |
| Context Menu   | ❌    |      |
| Dialog         | ✅    | ✅     |
| Drawer         | ❌    |      |
| Dropdown Menu  | ✅    | ✅     |
| Field          | ❌    | ✅     |
| Form (legacy; use Field) | ✅    | ✅     |
| Hover Card     | ✅    | ✅      |
| Input          | ✅    | ✅     |
| Input OTP      | ❌    |      |
| Label          | ✅    | ✅      |
| Native Select  | ❌    | ✅     |
| Pagination     | ✅    | ✅     |
| Popover        | ✅    | ✅     |
| Progress       | ✅    | ✅    |
| Radio Group    | ✅    | ✅     |
| Scroll Area    | ✅    | ✅    |
| Select         | ✅    | ✅     |
| Separator      | ✅    | ✅     |
| Sheet          | ✅    | ✅     |
| Skeleton       | ✅    | ✅     |
| Slider         | ✅    | ✅     |
| Switch         | ✅    | ✅   |
| Table          | ✅    | ✅    |
| Tabs           | ✅    | ✅     |
| Textarea       | ✅    | ✅     |
| Tooltip        | ✅    | ✅    |

## 🌟 Contributors

<p align="center">
    <a href="https://github.com/bluzky/salad_ui/graphs/contributors">
        <img src="https://contrib.rocks/image?repo=bluzky/salad_ui&max=300&columns=14" width="600"/></a>
</p>

## 😘 Credits

This project could not be available without these awesome works:

- `tailwind css` an awesome css utility project
- `turboprop` I borrow code from here for merging tailwinds classes
- `shadcn/ui` which this project is inspired from
- `Phoenix Framework` of course
