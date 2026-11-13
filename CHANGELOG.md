# Unreleased

shadcn/ui v4 parity work, pinned at shadcn `dd41d19`. See `docs/shadcn-parity.md`
for status and known gaps. Every new JS-backed component is registered in
`use SaladUI` and in the JS imports of `mix salad.setup` / `mix salad.install`.

**New components**
- Forms: `Field` family (`field_set`, `field_legend`, `field_group`, `field`,
  `field_content`, `field_label`, `field_title`, `field_description`,
  `field_separator`, `field_error`), `NativeSelect` (with optgroups and an `options`
  attr), `InputGroup` (addons, buttons, text, input/textarea controls), `InputOTP`
  (one real input, paste, pattern helpers), `Combobox` (single, or multiple with
  chips; client filtering or server filtering through `phx-change`).
- Layout and display: `Item`, `Empty`, `Kbd`, `Spinner`, `AspectRatio`,
  `Typography`, `ButtonGroup`, `Resizable` (keyboard, persistence via
  `auto-save-id`, `setLayout` command), `Direction` (`direction_provider/1`).
- Overlays and navigation: `Drawer` (drag to dismiss, snap points),
  `NavigationMenu` (shared animated viewport, indicator), `ContextMenu`, `Menubar`,
  `Carousel` (CSS scroll-snap, loop, autoplay; no Embla dependency).
- Dates and data: `Calendar` (server-rendered LiveComponent; single, multiple and
  range modes; dropdown captions; presets; localized names), `DatePicker`,
  `SaladUI.DataTable` (sort, filter, paginate, column visibility and row selection
  helpers with URL params, plus `data_table_column_header`,
  `data_table_view_options` and `data_table_pagination`).
- Chat and AI: `Message`, `Bubble`, `Marker`, `Attachment` (with
  `attachment_upload_entry/1` for `Phoenix.LiveView.UploadEntry`), `Trace`,
  `CodeBlock` (Makeup highlighting, line numbers, diff, ANSI, copy button),
  `MessageScroller` (turn anchoring, follow output, history prepend, works with
  `phx-update="stream"`), `Questionnaire` (with `SaladUI.Questionnaire.State` for
  server-driven and no-JS flows).
- Chat extras (not in shadcn; lifted from a downstream app): `EmojiPicker` (one
  picker for any number of plain opener buttons; search, categories, recents, skin
  tone, keyboard; its Unicode dataset is a lazily `import()`ed chunk) and
  `DropZone` (drag files over a region into a `live_file_input`; `attachFiles/2`
  in JS for pasted files). The installers copy the dataset and add `@source not`
  for it. Apps with their own `emoji_picker/1` or `drop_zone/1` under `use
  SaladUI` must rename it (the example app's is now `reaction_picker/1`).
- `mix salad.add <component...>` copies the named components plus their component,
  helper and JS dependencies. It takes `--prefix`, `--color-scheme` and
  `--overwrite`, and can be re-run.
- Storybook: stories for the shadcn docs examples, an LTR/RTL switch, and five
  shadcn blocks (dashboard-01, sidebar-07, login-03, signup-03, chat-01) with
  copyable source.

**New on existing components**
- `data-slot` on every part of every component, using shadcn's names, so shadcn
  selectors such as `*:data-[slot=select-value]:` work unchanged. New helper
  `SaladUI.Helpers.put_data_slot/2` lets wrappers re-label a child's slot.
- `aria-invalid:` error styling on input, textarea, select trigger, checkbox,
  radio item, switch, toggle, button and badge. `aria-invalid="true"` is set
  automatically when a `FormField` has errors and has been used; an explicit
  `aria-invalid` always wins.
- Button: sizes `xs`, `icon-xs`, `icon-sm`, `icon-lg`; renders an `<a>` when
  given `href`, `navigate` or `patch`.
- Badge: variants `ghost` and `link`; renders an `<a>` when given `href`,
  `navigate` or `patch`.
- Switch: `size="sm"`.
- Card: `card_action`, `size="sm"`, spacing via a `--card-spacing` variable.
- Dialog: `dialog_close`, and `show_close_button` on `dialog_content` and
  `dialog_footer`.
- Alert dialog: `alert_dialog_media`, `size="sm"` on the content.
- Command: `command_separator` (hidden while filtering unless `always_render`).
- Avatar: `size` (sm/default/lg), `avatar_badge`, `avatar_group`,
  `avatar_group_count`.
- Scroll area: `orientation` vertical/horizontal/both with thin themed
  scrollbars.
- Popover: `popover_header`, `popover_title`, `popover_description`, and
  `popover_anchor` (content positions against the anchor when present).
- Tabs: `orientation="vertical"` (Up/Down keys) and `variant="line"` on
  `tabs_list`.
- Select: `select_scroll_up_button` / `select_scroll_down_button` around a
  scrollable viewport. The content is capped to the room left in the window, so
  long lists near an edge stay reachable.
- Slider: a list `value` renders one thumb per value (range and multi-thumb), plus
  `orientation="vertical"`, `dir`, `inverted`, fractional `step` and
  `min-steps-between-thumbs`.
- Dropdown menu: `dropdown_menu_sub` / `_sub_trigger` / `_sub_content`,
  `dropdown_menu_radio_group` / `_radio_item`, and pointer grace when moving into
  a sub-menu.
- Chart: `chart_container/1` takes a shadcn chart config (label, color or
  light/dark theme, icons) as `--color-<key>` variables; `chart/1` draws area, bar,
  line, pie, radar and radial charts from a list of maps; `chart_tooltip/1` and
  `chart_legend/1`. The raw Chart.js API still works.
- Checkbox: `indeterminate` attr (small `checkbox.js` hook).
- Table: `table_head` / `table_cell` accept `colspan`, `rowspan` and `headers`.
- Pagination: `text` attr on previous/next.
- Sidebar: `dir` attr.
- `SaladUI.getDirection(el)` in JS; positioned content, tabs, radio group, slider,
  menus, carousel, resizable, calendar and navigation menu follow `dir="rtl"`.
- `salad_ui.css`: shimmer, `scrollbar-none`/`no-scrollbar` and shadcn's full
  `scroll-fade` utility set (`scroll-fade`, `-x`, `-y`, `-t`, `-b`, `-l`, `-r`,
  `-s`, `-e`, `-none` and size modifiers, RTL-aware).
- `priv/static/assets/typeset.css`: shadcn's typeset prose styles as an opt-in
  stylesheet (see README and `docs/manual_install.md`).
- Dropdown menu (new-york-v4): items take `inset` and `variant` (`destructive`);
  any item takes `close-on-select={false}`; `dropdown_menu_radio_item` takes
  `checked` for the first server render. The content caps its height to the room
  beside the trigger and scrolls.
- `breadcrumb_separator` takes content to replace the chevron; `input` and
  `input_group_input` accept `type="search"`.
- `SaladUI.ClassMerge`: a Tailwind v4-aware wrapper around `tw_merge` used by
  every component's `class` merge (and copied by `mix salad.add`).
- Toggle group (new-york-v4): `type` (single/multiple), `spacing` (0 = connected
  items), `orientation`, `loop`, `on-value-changed`; roving tab stop with arrow
  keys that follow orientation and RTL, Home/End. Toggle: `on-pressed-changed` and
  `toggle`/`on`/`off` commands.
- Toast: a `loading` variant (spinner, never times out, can't be swiped away),
  `toast_loading/3`, `toast_promise/3` + `toast_resolve/4` for `handle_async`
  results, `:message` in `toast_update/3`, a `toaster:` option on every helper,
  and client `toast.loading()` / `toast.promise()`. Icons and card colors follow
  shadcn's Toaster.
- Select: `disabled` on `select/1`; `position="item-aligned"` (shadcn's default;
  popper stays SaladUI's default), `align`, and `side="left"/"right"` on
  `select_content/1`; `:let` yields `%{invalid, disabled}` for the trigger.
- Sidebar: a JS hook on `sidebar_provider`. Below 768px the sidebar becomes an
  offcanvas sheet; Cmd/Ctrl+B toggles it; desktop toggles write the
  `sidebar_state` cookie; `default_open`, controlled `open` with `on-open-change`,
  `on-open-mobile-change`, open/close/toggle commands and the `toggle_sidebar`,
  `open_sidebar` and `close_sidebar` JS helpers. Menu button tooltips show only while collapsed and follow client
  toggles.
- Typeahead (Radix style) in dropdown menu, context menu, menubar and select,
  including the closed select trigger. `data-text-value` overrides an item's text.
- Separator: `decorative` attr. Sheet and command dialog: `show_close_button`.
  Command dialog: `title` and `description` (screen-reader header). Tooltip: arrow.
  Accordion: disabled items render a disabled trigger.
- Theme maps shadcn's `--sidebar`, `chart-1..5` and the `radius-2xl..4xl` scale.

**Behaviour changes**
- Dropdown menus are modal by default, as in Radix: while open, outside clicks
  only close the menu, the page is hidden from assistive tech and page scroll is
  locked. Pass `modal={false}` for the old behaviour.
- Select, context menu and the sidebar's mobile sheet are modal too, as in
  Radix (context menu takes `modal={false}`; select is always modal). Menubar
  stays non-modal, also as in Radix.
- Placement defaults match shadcn/ui: `select_content` is `item-aligned` with
  `align="center"` (pass `position="popper"` for the old placement);
  `dropdown_menu_content` aligns `center`; popover and hover card use a 4px
  `side-offset`; hover card opens on the `bottom` side.
- `tooltip_trigger` takes `as` (shadcn's `asChild`): `as={&button/1}` makes the
  button the trigger, so it groups correctly inside `button_group`.
- `icon` never shrinks in a flex row (`shrink-0`); `trace_icon` sizes heroicon
  spans like `<svg>` icons (16px, centred on the title).
- Resizable panels use `overflow: clip` (with `hidden` as the fallback), so
  focusing an input inside one can't scroll the panel out of place (iOS Safari).
- `on-*` handlers of content portaled outside the LiveView (`use-portal` to
  `<body>`) now push from the component's hook element, so LiveView finds an
  owner; before, they were silently dropped.
- Menus no longer wrap with the arrow keys by default (Radix `loop={false}`);
  set `loop` on the content to wrap. Menubar trigger navigation still loops.
- Class merging follows tailwind-merge v3 exactly, e.g. `outline outline-2`
  now gives `outline-2`.
- Form errors are now hidden on fields the user has not touched
  (`Phoenix.Component.used_input?/1`): `form_label`, `form_message` and
  `aria-invalid` all follow this rule.
- Destructive button and badge use `text-white` (with `dark:bg-destructive/60`)
  instead of `--destructive-foreground`; the token is still defined.
- Shadows follow the Tailwind v4 scale (`shadow-xs` on inputs, outline buttons,
  checkbox, select trigger, switch). Tooltip content drops its border and shadow
  for shadcn's `bg-foreground text-background` style.
- Button, switch, tabs, dialog, alert dialog and card classes now match shadcn v4,
  so default spacing and sizes shift slightly (card header is a grid).
- Single select trigger is `w-fit` instead of `w-full`; pass a width class to
  keep the old look.
- Select items match shadcn v4: the check indicator moves from the start side to
  the end side (`pe-8 ps-2`, indicator at `end-2`), and icons inside an item are
  sized and muted like shadcn's. `select_label` is the small muted `text-xs`
  heading, `select_separator` uses `bg-border` and now applies `class` and extra
  attributes. The trigger gets `role="combobox"` and `aria-controls` pointing at
  the listbox.
- Skeleton uses `bg-accent` instead of `bg-muted`. Pagination previous/next hide
  their text below the `sm` breakpoint (chevron only), and the `nav` has
  `role="navigation"` instead of the invalid `role="pagination"`.
- Badge root is a `<span>` instead of a `<div>`.
- Select and radio group render an extra hidden input so used-input tracking
  works; an empty radio group now submits `""`.
- Toggle puts `aria-invalid` on its button rather than the hidden checkbox.
- Slider markup is now shadcn's (one `role="slider"` thumb per value, one hidden
  input per thumb; several thumbs post as `name[]`). A number `value` still gives
  one thumb and a scalar `value` in `value-changed`, which now also carries
  `values`. With no `dir`, the slider follows the page direction.
- Popover, dropdown menu, carousel, slider, resizable, navigation menu, drawer,
  chart, dialog (and so sheet and alert dialog), select, tabs, accordion,
  collapsible, tooltip, hover card, command, toggle, toggle group and sidebar keep
  their client state across LiveView patches instead of resetting to the server
  render. Open overlays and menus stay open, drags in progress continue, and a
  field focused inside a tab panel, accordion item or collapsible keeps focus. A
  changed server `open`/`value` is still applied.
- Dropdown menu fires `on-close` and returns focus as soon as closing starts, not
  after the exit animation.
- **Menus**: picking a checkbox or radio item now closes the dropdown, context
  menu or menubar menu, as in Radix. Pass `close-on-select={false}` on the item to
  keep the old behaviour.
- Dropdown menu: a pointer open focuses the content with no item highlighted
  (Enter, Space or ArrowDown on the trigger still focus the first item); the
  pointer leaving an item clears its highlight; Tab inside open content is
  swallowed; the content is `aria-labelledby` its trigger; items, labels and
  sub-menus use v4 classes (`gap-2`, `font-medium` labels), so icons that carried
  their own `mr-2` now get double spacing.
- A caller's `class` now overrides component defaults written in Tailwind v4
  syntax (`w-(--x)`, `data-[orientation=vertical]:h-auto`, `outline-hidden`,
  text-shadow, inset-ring and other v4-only groups). Classes that used to ship
  side by side may now replace each other; for example `button_group_separator`
  no longer collapses to 0px because its `h-auto` override now wins.
- Code block content fades its scrolling edges (`scroll-fade-x`, and
  `scroll-fade-y` when lines wrap).
- Dialog, sheet, alert dialog, drawer and the sidebar's mobile sheet lock page
  scrolling while open, as Radix and vaul do: `<html>`/`<body>` get
  `overflow: hidden` and `<body>` is padded by the scrollbar width (exposed as
  `--removed-body-scroll-bar-size`, with `data-scroll-locked` on `<body>`). Locks
  are counted, so nested modals unlock the page only when the last one closes;
  the page's inline styles are restored afterwards.
- **Toggle (breaking)**: `id` now goes on the button (the checkbox gets
  `"<id>-input"`), global attributes land on the button instead of the hidden
  input, and styling uses `data-[state=on]` instead of `has-[:checked]`. Apps that
  ran `mix salad.setup` before this release must import the new `toggle` and
  `toggle_group` JS components, or the controls stop responding.
- Toggle group: clicking the pressed item of a single group now releases it (as
  Radix); a single group with a name submits `""` when nothing is pressed, and a
  multiple group with a plain `name` submits `name[]`.
- `toast_update/3` without `:variant` keeps the toast's current variant (it used
  to reset to default).
- Color schemes define `--sidebar` instead of `--sidebar-background`; the theme
  reads either, and re-running the installer upgrades an old theme block.
- Separator defaults to `role="none"` (decorative); pass `decorative={false}` for
  `role="separator"`.
- Alert uses the v4 two-column grid; sheet padding moved from the panel to header
  and footer; accordion, label, progress, table and command use new-york-v4
  classes (table gets a scroll container).
- Sidebar: `data-collapsible` is `""` while expanded (was `"none"`); the
  server-side `is_mobile` Sheet branch is gone (the hook handles mobile); the
  sidebar no longer imports Sheet or Tooltip; only its own trigger, rail and
  overlay `data-action`s toggle it.
- An empty `multiple` select submits `name=""`, so it reaches the changeset.
- Menu-family items (dropdown, context menu, menubar, select, combobox) use logical
  padding and indicator classes (`ps-8`, `start-2`), so a caller's `pl-*` no longer
  replaces the default through `tw_merge`.
- Sub-menu, pagination and breadcrumb chevrons flip under RTL.
- `SaladUI.Form` is documented as legacy in favour of `Field`; it is not removed.
- `mix salad.install` now shares code with `salad.add`, and its base CSS copies
  skip files that already exist instead of aborting.

**Fixes**
- Modals (dialog, sheet, alert dialog, drawer, dropdown menu) block outside
  pointers, hide the rest of the page with `aria-hidden` and block outside
  wheel/touch scroll, restoring everything across LiveView patches. Content
  portaled from inside a modal stays interactive; toasts stay clickable. New
  `modal` attr. Fixed elements can opt into scrollbar compensation with
  `width-before-scroll-bar` / `right-scroll-bar-position`.
- RTL: logical classes across components; toast `swipe-direction` accepts
  `start`/`end`; chart axes and arrow keys mirror; sliders render RTL before the
  hook mounts.
- Combobox: `use-portal`, PageUp/PageDown/Home/End, an accessible name on the
  listbox, and an `open` event payload (`%{"query" => q}`) so server filtering
  can reset its results. `Portal.restore` returns content to its original
  position.
- Class merging is a port of tailwind-merge 3.7.0: `mask-*`, `bg-size`,
  `bg-position`, `text-*/N` vs `leading-*`, logical properties, `(--var)`,
  `!` suffix and `*:` variants. About 25x faster on a cache miss, and the cache
  is bounded (flushed at 10,000 entries).
- Attributes from an outer trigger no longer duplicate the child's
  (`data-slot` appeared twice on `as_child` triggers). Pagination renders
  `aria-current` only on the active page and lucide icons with `aria-hidden`.
  Sidebar menu tooltips set `aria-describedby` while shown.
- Dialog and alert dialog content is centered with `inset-0 m-auto h-fit`
  instead of a translate, so a combobox or date picker opened inside a dialog
  is positioned correctly.
- Popovers, dropdowns, hover cards and other positioned content shift along
  their side to stay in the viewport (Radix's collision avoidance), without
  leaving the trigger. Context menus keep hanging the other way from the
  pointer instead.
- `message_scroller`: no default `contain-content`, `scroll-fade-b` or item
  `content-visibility: auto`; they clipped and offset popovers, menus and hover
  cards in rows. The moduledoc shows how to opt back in, and how to load history
  with `on-scrollable-change` instead of `phx-viewport-top`.
- `mix salad.setup` / `mix salad.install` import `command.js`; a test now checks
  every registered JS component is imported. (`use SaladUI` still leaves out
  `SaladUI.Command`, whose `command/1` collides with the Lucide icon; the docs now
  say to `import SaladUI.Command`.)
- `command_input` accepts `placeholder`, `name`, `value` and other input attributes
  without undefined-attribute warnings.
- Trigger and close parts (`popover_trigger`, `dropdown_menu_trigger`,
  `dialog_trigger`, `dialog_close`, `alert_dialog_trigger`, `drawer_trigger`,
  `drawer_close`, `collapsible_trigger`, `context_menu_trigger`) accept `variant` and
  `size` for `as={&button/1}`; plain tags drop them.
- `checkbox` gains `checked`, `checked_value` and `unchecked_value` (`nil` omits the
  hidden input), so checkbox groups can submit `name="tags[]"` values.
- Outline sidebar menu button ring rendered invalid CSS (`hsl()` around an
  oklch token).
- Checkbox indicator survives `@tailwindcss/forms` and dark mode.
- `Helpers.dynamic/1` no longer renders a stray `name="div"` attribute.
- Keydown handlers bound for several states on one element (checkbox and radio
  menu items) leaked past `destroy()` and threw on every keypress after a
  re-render.
- A `data-action` element inside a nested component no longer also triggers its
  parent (for example a collapsible inside a collapsible).
- Menu items apply `aria-disabled`; checkbox items highlight on hover; reopening a
  menu focuses its first item again.
- Table: the checkbox column tweaks now match SaladUI's native checkbox.
- Toast: a dismiss that finished after the toaster was destroyed no longer throws;
  timers started while the stack is hovered start paused, and `expand` stacks
  resume them after a hover.
- Sidebar menu buttons with a tooltip keep the `sidebar_menu_action`/`_badge`
  styles, and an outer trigger passed through `as_child` works again.
- Dropdown menu with `use-portal`: the content survives LiveView patches, and
  Escape inside portaled content closes the menu.
- Component class merging no longer crashes on `not-*` classes (`not-typeset`,
  `not-prose`) or `no-scrollbar`.
- Sub-menus close when the pointer leaves the sub-trigger away from the sub-menu
  (Radix pointer-direction grace).

**Fixes from downstream use: server state**
- Tabs: `tabs/1` hands a builder to its slot (`:let={tabs}`); passed to the
  list, triggers and panels, the server renders the selected tab and its full
  ARIA, so a URL-driven tab is right before the JS runs. Parts render their
  roles without it. `default-value` is an alias for `default`. Arrow keys,
  Home and End click the tab they select, so a trigger's `phx-click` runs.
- Toggle group and toggle: with `value` (or a `field`) they are controlled and
  show the server's value on every re-render and after the server answered
  `on-value-changed`/`on-pressed-changed`, so the server can refuse a change.
  `default-value` keeps the client state as before.
- Popover follows a changed `open` from the server; its `send_command`
  (`open`/`close`/`toggle`) support is documented. Combobox gets an `open` attr.
- Resizable: `collapsible` and `collapsed-size` panels (react-resizable-panels
  snapping), `collapse`/`expand` commands by panel id, Enter on a handle.
- `SaladUI.command(elOrSelector, command, params)` runs a component command
  from plain JS.
- `collision-padding` on popover, dropdown menu, hover card, tooltip, select
  (popper) and context menu content; default 0 as in Radix.
- The focus trap no longer pulls focus back to the opener when a close handler
  (or the click that closed it) moved focus elsewhere.

**Fixes from downstream use: accessibility and overlays**
- `ariaConfig` writes `role` and `tabindex` as-is: tab panels get a real
  `tabindex="0"`, not the invalid `aria-tabindex`.
- Resizable: the panel group no longer carries `aria-orientation` (it has no
  role); only the handles do, as in react-resizable-panels.
- Toaster follows Sonner's markup: a `<section aria-label="Notifications Alt+T">`
  landmark that is the polite live region, with role-less `<ol>`/`<li>`. Error
  toasts are no longer assertive alerts; `important: true` opts a toast in.
- Toaster: `close-button` (per toast `close_button:`), a toaster-wide
  `duration`, and the hotkey matches the physical key, so Option+T works on macOS.
- Alert dialog closes on Escape, as Radix's does. Escape in a nested dialog,
  menu or select closes only that layer (key handlers skip a key a nested
  component already handled).
- A dialog opened by the server returns focus to its trigger on close.
- Dialog overlay is `z-50`; dialog, alert dialog and drawer roots drop
  `relative z-50`, so an open dialog no longer paints under a later dialog's trigger.
- Focus cannot leave an open modal layer: focus that lands on the hidden page
  (Tab from `<body>`, a script's `focus()`) goes back into the layer.
- Menu items: a click bubbles again, so `phx-click` on dropdown, context and
  menubar items fires; Enter and Space click the item, as in Radix. Clicks in
  content portaled out of a popover or dialog count as inside it.
- `command_separator` is `role="none"` inside the listbox (overridable with `role`).
- Attachment: shadcn's 3px focus ring when the card's trigger has keyboard focus.
- `salad_ui.css`: the scroll area thumb uses `var(--border)`, not `#c2c2c2`.
- `select.js` no longer contains a comment Tailwind reads as a broken utility.

**API fixes from downstream use**
- `command`, `command_list`, `command_group`, `command_empty`,
  `command_shortcut` and every `dialog` part take global attributes;
  `command_list` is named like cmdk's (`label`, default `"Suggestions"`), and
  `command_group`'s `heading` is optional.
- `command_item` renders `type="button"`. `dialog_trigger`, `dialog_close`,
  `alert_dialog_trigger`, `drawer_trigger` and `drawer_close` take `type` and
  default it to `"button"` when `as` renders a button.
- `sidebar_group_action` and `sidebar_menu_action` take `as` and render a link
  for `href`/`navigate`/`patch`, otherwise a `type="button"` button.
  `sidebar_trigger` and `sidebar_rail` take `label` (default
  `"Toggle Sidebar"`), and attributes passed to them replace their own instead
  of rendering twice.
- `attachment` renders as a link with `href`/`navigate`/`patch` (or `as`).
- `icon` takes global attributes.
- Every component's `class` takes a list as well as a string (`:any`), merged
  by `classes/1`.
- **Breaking:** `tooltip` requires `id`, and `toggle`, `toggle_group` and
  `radio_group` raise without an `id` or `field`: they no longer generate a new
  id on every render, which remounted their hooks.
- The class merge learns an app's theme scales:
  `config :salad_ui, :class_merge, theme: [text: ~w(panel), radius: ~w(card)]`
  (see `SaladUI.ClassMerge`).
- `use SaladUI, only: [...]` / `except: [...]` take modules, `name: arity` pairs
  and function names, to avoid clashes with an app's own `sidebar/1`,
  `json/1`, ...
- `igniter` and `sourceror` are optional dependencies. The installer tasks ask
  for `{:igniter, "~> 0.6", only: [:dev, :test]}` when it is missing.

**Tooltips and hover cards no longer pile up**
- One tooltip at a time: opening one closes any other (Radix's provider).
- Leaving the trigger before the open delay ends cancels it (a tooltip used to
  open after the pointer left and stay stuck).
- Pressing the trigger, Escape, and scrolling a container around the trigger
  close it, as in Radix; a pointer seen elsewhere closes one whose mouseout
  was missed.
- No tooltip opens while a menu, popover, dialog, select, combobox or hover
  card is open, except for triggers inside that popup.
- Focus that follows a click does not open a tooltip; keyboard focus does.
- Hover cards follow the same rules (shared `core/hover-popups.js`): one
  tooltip or hover card at a time (a tooltip inside a hover card keeps it
  open), leaving during the open delay cancels it, and Escape, scrolling or the
  pointer moving elsewhere close it.
- Root cause: `mouseMap` handlers only ran in the state that declared them, so
  a "leave" during a pending delayed open was never heard. `mouseMap` now
  supports `_all`, as `keyMap` does.

**More fixes from downstream use**
- Dialog, alert dialog, sheet and drawer take `return-focus`, a selector for
  the element that gets focus on close (Radix's `onCloseAutoFocus`).
- Focus returns to the opener on close even when it is scrolled out of view
  (it used to fall to `<body>`), as Radix does.
- Toaster takes `label` (Sonner's `containerAriaLabel`, default
  "Notifications") and global attributes.

**Resizable: collapsed panels from downstream use**
- With `auto-save-id`, the size a collapsed panel expands back to is stored
  with the layout (react-resizable-panels' `expandToSizes`), so `expand`
  restores the width the person set after a reload, not `min-size`. A panel
  collapsed by a drag or the keyboard remembers its size too; with nothing
  remembered, `expand` opens to `default-size`, then `min-size`. The stored
  value is now `{layout, expandToSizes}`; a layout stored as a bare array
  still loads.
- `resizable_panel` takes `collapsed`: the server's state for a
  `collapsible` panel. It is rendered collapsed (at `collapsed-size`, with
  `data-collapsed`) from the first paint, so a panel hidden last time no
  longer shows for a moment on load, and a change to `collapsed` collapses or
  expands it, as `dialog` follows `open`. The group's new `on-collapse` /
  `on-expand` events report changes made by a drag, the keyboard or a command,
  with the panel's id and index, so the server can keep the state (the
  moduledoc shows the pattern, or a cookie as react-resizable-panels
  recommends).
- A panel collapsed to size 0 is `inert` (out of the tab order and the
  accessibility tree) until it expands; focus inside it moves to its handle. A
  panel with a `collapsed-size` above 0, such as an icon rail, stays
  interactive.
- Panel sizes are an inline `--panel-size` custom property read by the
  panel's `flex-[var(--panel-size,1)_1_0px]` class instead of an inline
  `flex`, so app CSS overrides them without `!important` (e.g. one full-width
  panel at a time below a breakpoint).
- Panels are `min-h-0 min-w-0`: with `overflow: clip` (not a scroll
  container) a panel could not shrink below its content's min-content size,
  so a collapsed panel with content still showed, and small sizes were wider
  than their percentage.

**Modal layers are cheap on large pages**
- Opening a modal dropdown menu, context menu, dialog or sheet no longer
  restyles every element of the page on open and on close. On a page of 40k
  elements (2000 chat rows) a dropdown opens in ~120 ms instead of ~180 ms, a
  context menu in ~95 ms instead of ~160 ms and a dialog in ~90 ms instead of
  ~175 ms. Two writes each forced that full style recalc (~130 ms):
  - the hidden page was made `inert`. It is now `aria-hidden` only, as in
    Radix, and focus that lands outside the layer goes back in. axe's
    `aria-hidden-focus` rule reports the focusable controls behind an open
    modal again, as it does for Radix.
  - the scroll lock set `--removed-body-scroll-bar-size` on `<body>` even when
    there was no scrollbar to remove. It is now set only when `<body>` is
    padded (or the page had set it); read it as
    `var(--removed-body-scroll-bar-size, 0px)`, as `salad_ui.css` does.
- What remains is `pointer-events: none` on `<body>` (~50 ms at 40k
  elements), which Radix sets too.

**Extensions from downstream use** (not in shadcn/Radix/Sonner; defaults unchanged)
- Toggle group takes `required`: in a `type="single"` group pressing the
  pressed item (click, Space, Enter) does nothing: no release, no
  `value-changed` event, and so no blink in a controlled group waiting for
  the server. In a `type="multiple"` group the last pressed item cannot be
  released. Radix has no `required`; without it nothing changes.
- Toaster takes `breakpoint` (px, default 600 as in Sonner) for the switch to
  the phone layout, which used a Tailwind `max-[600px]` fixed at build time.
  The viewport now carries `data-mobile` from a `(max-width: <breakpoint>px)`
  media query. Phone-layout cards fill the viewport width, as Sonner's do
  (they kept 356px). The switch is now at or below 600px, as in Sonner (it
  was below 600px).
- `top-center` / `bottom-center` toasts centre on
  `var(--toaster-center-x, 50%)`, so an app can centre them on the page
  beside a sidebar (example in `SaladUI.Toast`, "Placement"). In the phone
  layout they sit between the mobile offsets, as in Sonner. `offset` and
  `mobile-offset` already took CSS lengths such as `"var(--header-height)"`;
  now documented.
- `sidebar_trigger` takes an `:icon` slot that replaces shadcn's panel icon
  (e.g. an app logo), keeping the trigger's toggle wiring and label.

# 0.14.0

**Changes**
- Implement Sidebar component
- Introduce `as_child` tag to merge multiple `SaladUI` tag
- Introduce `dynamic` tag which allow dynamic rendering a tag.

**Breaking changes**
- Replace `tails` by `tw_merge` which extracted from `turboprop`. You have to add `TwMerge.Cache` to children list in your `application.ex`
- `Collapsible` component doesn't use builder anymore.

# 0.9.0

- ashkan117: fix: Explicitly include the <a> attributes to avoid lsp warning
- selenil: feature: Add mix task for init & install salad_ui components

- forest: fix input warning
- bluzky: fix overriding input name/value not working
- bluzky: feature: Add support for custom error translation function

# 0.8.0

- Add support Form.Field for all input components

**Breaking changes**
This version introduce some change to unify interface and term for some components:
- `Toggle.toggle` change `pressed` attribute -> `value`
- `Select` change `instance` -> `builder`
- `Tab.tab_trigger` change `root` attribute -> `builder` and required exposing builder from the `tabs`
