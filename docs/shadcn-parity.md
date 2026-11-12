# shadcn/ui parity — gap catalog

## Status

Compared against shadcn/ui `dd41d19e2f80ff6891951f7ced74c2c9a650b065`
(`apps/v4/registry/new-york-v4/ui` and `apps/v4/content/docs/components/radix`).
Every item below is on `parity/integration`. `parity-audit.sh` reports no bad
squashes as of `3e86ea6`. The two earlier bad squashes (9b34b26 and 856a69d) were
repaired by `c01934d` and `029e138`.

| Item | Status | Commit (feat / review fix) | What landed |
|---|---|---|---|
| `tailwind-drift` | pushed | `696806c` | v4 shadow scale, `aria-invalid:` styling plus automatic `aria-invalid` on touched FormFields, button `xs`/`icon-*` sizes, badge ghost/link, switch `size`, sidebar `hsl(oklch)` fix |
| `data-slot` | pushed | `32390fc` | shadcn `data-slot` on every part; `put_data_slot/2` |
| `overlay-deltas` | pushed, reviewed | `67f6c67` / `ac341c8` | Popover header/title/description/anchor; tabs vertical and `line`; select scroll buttons and viewport |
| `small-deltas` | pushed | `3c5f6de` | Button/badge as links, card action/size, dialog close parts, alert-dialog media/size, command separator, avatar sizes/badge/group, scroll-area orientation |
| `slider-range` | pushed, reviewed | `2f37711` / `c0dd9f0` | Range and multi-thumb, vertical, inverted, RTL, fractional step |
| `display-primitives` | pushed | `96a92ba` | Item, Empty, Kbd, Spinner, AspectRatio, Typography |
| `resizable` | pushed, reviewed | `562a44d` / `856a69d` | Resizable panel group/panel/handle with keyboard, persistence, setLayout |
| `form-primitives` | pushed | `3b0a649` (restored in `029e138`) | Field family, NativeSelect |
| `code-block` | pushed, reviewed | `c7b7ef6` / `eb2aa56` | CodeBlock with Makeup highlighting, line numbers, diff, ANSI, copy button |
| `dropdown-menu-sub-radio` | pushed, reviewed | `24c795a` / `e033dd7` | Sub-menus, radio group/items, pointer grace, state kept across patches |
| `navigation-menu` | pushed, reviewed | `d4f2a05` / `755c2a5` | NavigationMenu with shared viewport, indicator, keyboard, RTL |
| `input-otp` | pushed, reviewed | `be64659` / `61f9495` | InputOTP with one real input, paste, pattern, form reset |
| `carousel` | pushed, reviewed | `a5858d0` / `efd7440` | Scroll-snap carousel, loop, autoplay, server commands |
| `drawer` | pushed, reviewed | `3fde18d` / `d21661e` | Vaul-style drawer with drag-to-dismiss and snap points |
| `group-primitives` | pushed | `5ec858e` (restored in `c01934d`) | InputGroup, ButtonGroup |
| `chat-kit` | pushed | `9b34b26` | Message, Bubble, Marker, Attachment (UploadEntry aware), Trace |
| `chart-theming` | pushed, reviewed | `ffed150` / `bc584d4` | shadcn chart config, `chart/1` for area/bar/line/pie/radar/radial, HTML tooltip and legend |
| `calendar-date-picker` | pushed, reviewed | `c04c5c9` / `db2e424` | Server-rendered Calendar (single/multiple/range, dropdown captions, presets), DatePicker |
| `data-table` | pushed, reviewed | `76708ad` / `573bcd6` | `SaladUI.DataTable` state helpers, column header, view options, pagination; checkbox `indeterminate` |
| `context-menu-menubar` | pushed, reviewed | `4f565fd` / `73da22a` | ContextMenu and Menubar on the shared menu internals |
| `combobox` | pushed, reviewed | `b15ef50` / `6651909` | Combobox: single, multiple with chips, groups, clear, client or server filtering |
| `questionnaire` | pushed, reviewed | `d1a74ce` / `0fa2c91` | Questionnaire with `Questionnaire.State` for server-driven and no-JS flows |
| `message-scroller` | pushed, reviewed | `5110b6d` / `c7384fb` | MessageScroller: turn anchoring, follow output, history prepend, stream aware |
| `direction-rtl` | pushed, reviewed | `4e4089c` / `c0ab4df` | `direction_provider/1`, shared `core/direction.js`, RTL across positioned and keyboard components |
| `blocks` | pushed | `c4a05cd` | dashboard-01, sidebar-07, login-03, signup-03, chat-01 as storybook LiveViews |
| `mix-salad-add` | pushed | `3e86ea6` | `mix salad.add <component...>` with a dependency map derived from the source |

### Not covered (by item)

Deliberate omissions and limits the implementers recorded. React-only concepts
(Portal, Provider, asChild internals) are left out of this list.

- **tailwind-drift**: tooltip has no arrow; `toggle_group` items have no
  `aria-invalid:` styling; checkbox colors use `checked:` (native input).
- **data-slot**: no `form-control` slot (no wrapper element); `menu-*` slots are
  SaladUI's own; no slot on toast or icon; no `scroll-area-scrollbar/thumb` or
  `table-container`, because SaladUI has no such elements.
- **overlay-deltas**: select has no `position="item-aligned"` and no `disabled` attr
  on `select/1`; `popover_content` side offset defaults to 8 (shadcn uses 4).
- **small-deltas**: no separate `scroll_bar` part (native scrollbars are styled
  instead); `card-spacing` shows fixed spacings instead of shadcn's interactive switcher.
- **chart-theming**: no dedicated chart RTL story; no `formatter`/`labelFormatter`
  callbacks (server functions can't reach the client); the chart-demo preview is
  only approximated.
- **calendar-date-picker**: Gregorian only (no Hijri/Persian); only month and
  weekday names are localized; natural-language picker uses a small stand-in
  parser; presets are buttons, not a Select; `date_picker/1` doesn't pass popover
  offsets through.
- **data-table**: no RTL example; single-column sort; the "Copy payment ID" action
  uses a storybook-only clipboard listener.
- **context-menu-menubar**: no typeahead; no per-item pointer-leave unhighlight;
  `context_menu` has no `open` attr; transform-origin classes dropped.
- **combobox**: chips always show the item label (no ComboboxValue render prop); no
  `ComboboxCollection`; no `use-portal`; older examples (dropdown-menu, responsive,
  popover+command) have no stories.
- **questionnaire**: no `render` prop (only `as` on the title); one root
  `on-status-change` instead of per-item; conditional items and controlled choices
  need a server render; the form is always `novalidate`.
- **message-scroller**: no inline anti-flash `<script>` recipe, no virtualization
  example; the group-chat and animation examples are simplified.
- **direction-rtl**: logical-class sweep covers only the menu family and pagination;
  chart keyboard navigation and toast swipe are not mirrored; a slider that
  inherits RTL renders LTR until the hook mounts.
- **blocks**: dashboard-01 has no drag-to-reorder rows, no mobile viewport
  switching and no gradient area fill; toast.promise is replaced by a single
  success toast; collapsed-sidebar tooltips and a mobile sidebar don't work (see
  `sidebar-behaviour` below); chat-01 replies are plain text.
- **mix-salad-add**: no `--all`/`--path`/`--cwd`/`--silent`; adding `chart` prints
  an npm notice and does not run npm.

### Remaining review issues

Issues reviewers found but didn't fix. None blocks a merge.

- **Patch survival outside the reviewed items**: `dialog.js` (so dialog, sheet and
  alert dialog), `select.js`, `tabs.js`, `accordion.js`, `collapsible.js`,
  `tooltip.js`, `hover-card.js` and `command.js` have no `skipReinitialize`. Any
  LiveView patch inside them rebuilds the instance from server state. For example,
  a client-opened dialog with a `phx-change` form closes on the first keystroke.
  The dropdown menu still runs `on-close` and focus return after its exit
  animation, the same race the context-menu review fixed. Tracked as
  `legacy-patch-survival`.
- **Menus**: no typeahead in the dropdown menu, context menu, menubar or select.
  Radio and checkbox items keep the menu open when picked, unlike Radix. Radio
  indicators render only on the client.
- **Carousel**: no autoplay pause button and no `aria-controls` on previous/next
  (shadcn has neither).
- **Code block**: "Copy"/"Copied" labels are hard-coded; hunk headers go through
  the language lexer; `scroll-fade-x/y` is not ported.
- **Drawer**: the overlay doesn't follow `fadeFromIndex` with snap points; snap
  offsets are not recalculated on resize.
- **Input OTP**: `<.form_label field={...}>` points at the hook root, not the
  `-input` element, so it doesn't focus the input. Not checked in a real browser or
  with SMS autofill.
- **Navigation menu**: the indicator doesn't follow resizes; no ArrowUp/ArrowDown
  between closed top-level triggers.
- **Chart**: tooltip, legend and icon `<template>`s don't update on patch until the
  chart remounts.
- **Calendar**: month-crossing keyboard and form round-trip were not tested in a
  live browser; there is no `live_isolated` test infrastructure.
- **Data table**: the rows-per-page select ignores `target`; view-option toggles
  bake `visible` in at render time.
- **Combobox**: with server filtering in single mode, reopening shows the last
  query's results; no PageUp/PageDown/Home/End keys; no listbox accessible name.
- **Questionnaire**: in server-driven mode, freeform text is lost when a fixed
  choice is picked; no server-rendered `aria-describedby`.
- **Message scroller**: LiveView 1.0 only, a focused scroll button loses focus on
  patch; a tail spacer after `scroll_to_message` without `auto_scroll` stays (as in
  shadcn).
- **Direction**: physical classes remain in dialog/sheet close buttons, the
  navigation-menu viewport, the sidebar rail and input-group; toggle group has no
  arrow keys to mirror; `tw_merge` doesn't treat `pl-*` as conflicting with `ps-*`.
- **Tooling**: `docs/manual_install.md` still maps colors as
  `hsl(var(--x))`; the sidebar token is `--sidebar-background` where shadcn uses
  `--sidebar`; an empty `multiple` select is never flagged invalid; select trigger
  `aria-invalid` is set only by JS; 10 leftover `h-4 w-4` in
  `test/salad_ui/dropdown_menu_test.exs`. (The storybook format failures seen
  during `blocks` were fixed in `7fc81ae`.)
- **Attribution**: every parity commit leaves out the harness's Co-Authored-By
  trailer, following the user's CLAUDE.md.

### Completeness critic, round 1

Each shadcn ui file and radix docs page was checked against this branch for
exported parts, data-slots, cva variants, class strings and docs examples. All 61 ui
files and 67 docs pages have a SaladUI counterpart, and every exported part maps to
a function except React-only ones. Remaining gaps, as work items:

| Id | Kind | Gap |
|---|---|---|
| `legacy-patch-survival` | JS | Keep dialog/sheet/alert-dialog, select, tabs, accordion, collapsible, tooltip, hover-card and command state across LiveView patches; fix the dropdown close-animation race |
| `toggle-group-v4` | JS | Toggle group still uses v3 classes; add `spacing`, `orientation`, data-variant/size/spacing, roving arrow keys (RTL), and `aria-pressed`/`data-state` on toggle and items |
| `legacy-class-sync` | CSS | v3 markup in accordion, alert, label, progress, separator, sheet (plus `show_close_button`), table (plus container), command dialog title; tooltip arrow |
| `select-deltas` | JS | `disabled` on `select/1`, `position="item-aligned"` (shadcn's default), `align` on content |
| `sidebar-behaviour` | JS | Responsive mobile sheet without the server `is_mobile`, Cmd/Ctrl+B, cookie persistence, collapsed tooltips that follow client toggles, component story |
| `toast-loading-promise` | JS | Sonner `loading` type and promise flow, shadcn's icons and popover tokens, stories for sonner docs examples |
| `menu-typeahead` | JS | Typeahead in dropdown, context menu, menubar and select |
| `tailwind-drift-followup` | CSS | `docs/manual_install.md` on v4 tokens; accept shadcn's `--sidebar` token name |

---

_The catalog below is the original snapshot that planned the work above; the Status section is current._

Snapshot: 2026-11-12. SaladUI `v1.0.0` (main @ `64090ea`) vs shadcn/ui `main`
(last commit 2026-11-11, `apps/v4/registry/new-york-v4/ui` + `apps/v4/content/docs/components/radix`).

Counts: shadcn documents **66** components; SaladUI ships **39** (+ `menu`, `icon`
which have no shadcn equivalent). **27 components are missing** and **~15 existing
components are shallower** than their shadcn counterparts.

Legend for "Kind":
- **CSS** — function component + Tailwind only, no JS. Fast to port.
- **JS** — needs a `Component` subclass + state machine in `assets/salad_ui/components/`.
- **LV** — best built server-driven (LiveView assigns/streams/uploads), little or no JS.

Estimates assume one component, storybook story, and basic tests.

---

## 1. Missing components

### Tier 1 — form & layout primitives (CSS, unblock everything else)

These are the "new" shadcn building blocks (2025+). Most other shadcn examples and
blocks are now written against them, so they have the highest leverage.

| Component | Kind | What it is | Est. |
|---|---|---|---|
| `field` | CSS | `FieldSet/Legend/Group/Field/Content/Label/Title/Description/Separator/Error`. shadcn's replacement for `form`. Should accept `Phoenix.HTML.FormField` and render errors. | ~3 h |
| `input_group` | CSS | Input/textarea with addons (icons, text, buttons) at inline/block start/end. | ~2 h |
| `button_group` | CSS | Joined buttons, orientation, separator, text segment. | ~1 h |
| `item` | CSS | List row: `Item/Media/Content/Title/Description/Actions/Header/Footer/Group/Separator`, variants. | ~1.5 h |
| `empty` | CSS | Empty state: `Empty/Header/Media/Title/Description/Content`. | ~45 min |
| `kbd` | CSS | `Kbd`, `KbdGroup`. | ~20 min |
| `spinner` | CSS | Animated loader icon, sizes. | ~20 min |
| `native_select` | CSS | Styled native `<select>` with optgroups — LiveView-friendly fallback to `select`. | ~45 min |
| `aspect_ratio` | CSS | Wrapper with `aspect-[ratio]`. | ~15 min |
| `typography` | CSS | h1–h4, p, blockquote, list, inline code, lead, large, small, muted. | ~45 min |

**Prerequisite:** shadcn v4 composes via `data-slot` attributes
(`has-[[data-slot=input-group-control]:focus-visible]`, etc.). SaladUI emits
**zero** `data-slot` attributes today. Add them across existing components first
(~2 h, mechanical) or `field`/`input_group`/`button_group` won't style correctly.

### Tier 2 — interactive components apps actually reach for (JS)

| Component | Kind | Notes | Est. |
|---|---|---|---|
| `calendar` | JS + LV | Month grid, single/multiple/range, min/max, disabled dates, keyboard nav. Could render the grid server-side and keep JS for focus/keys only. | 1–1.5 days |
| `date_picker` | JS | `popover` + `calendar` + input; range + presets. Depends on `calendar`. | ~3 h after calendar |
| `combobox` | JS | Searchable select (single/multi, chips, async/server-filtered options via `phx-change`). Reuse `command` filtering. | ~1 day |
| `context_menu` | JS | Right-click menu. Reuse `dropdown_menu` content/items; new trigger + pointer positioning. | ~4 h |
| `menubar` | JS | Horizontal app menu, arrow-key roving between menus, submenus. | ~1 day |
| `navigation_menu` | JS | Site nav with hover-opened panels + animated viewport/indicator. | ~1 day |
| `drawer` | JS | Bottom sheet with drag-to-dismiss + snap points (vaul). Different from `sheet`. | ~1 day |
| `input_otp` | JS | Segmented code input, paste handling, pattern, separator, hidden real input for forms. | ~4 h |
| `carousel` | JS | Prev/next, keyboard, orientation, loop, API events (embla). Could use CSS scroll-snap + small JS. | ~5 h |
| `resizable` | JS | `ResizablePanelGroup/Panel/Handle`, horizontal/vertical, min/max, keyboard, persisted sizes. | ~1 day |
| `data_table` | LV | shadcn = TanStack recipe (sort, filter, paginate, column visibility, row selection). In LiveView this is a server-driven recipe on top of `table` + `dropdown_menu` + `pagination` + `checkbox`. Ship as a guide + helper module, not a monolith. | ~1 day |
| `direction` | CSS + JS | RTL support. Needs `dir` honored by every positioned component (popover/menu/tooltip side flipping, sidebar, slider). Audit, not a component. | ~4 h audit |

### Tier 3 — chat / AI components (new in shadcn, 2026)

shadcn added a full conversation kit. Good fit for LiveView (streams + PubSub).

| Component | Kind | Notes | Est. |
|---|---|---|---|
| `message` | CSS | `MessageGroup/Message/Avatar/Content/Header/Footer`, alignment. | ~45 min |
| `bubble` | CSS | Bubble variants (primary/secondary/muted/tinted/outline/ghost/destructive), grouping, reactions, collapsible content. | ~1.5 h |
| `marker` | CSS | Inline status / system note / labeled separator in a transcript. | ~30 min |
| `attachment` | CSS + LV | File/image tile w/ media, metadata, upload state, actions. Wire upload state to `Phoenix.LiveView.UploadEntry`. | ~3 h |
| `message_scroller` | JS | Stick-to-bottom while streaming, load history without jump, jump-to-message, "scroll to latest" button. Must cooperate with `phx-update="stream"`. | ~1 day |
| `trace` | JS | Collapsible reasoning / tool-call / sources blocks. Mostly `collapsible` + styling. | ~3 h |
| `code_block` | CSS + small JS | Header, line numbers, diff, copy button. Highlight server-side with Makeup instead of Shiki. | ~4 h |
| `questionnaire` | JS/LV | Multi-step single/multi-choice/freeform/skippable questions. Server-driven steps fit LV well. | ~5 h |

### Not a gap

| shadcn | SaladUI | Why |
|---|---|---|
| `sonner` / `toast` | `toast` | SaladUI's toast already follows Sonner (stacking, swipe, positions, flash bridge). shadcn deprecated its old toast. |
| `form` (react-hook-form) | `form` | Equivalent; superseded by `field` in both libraries going forward. |
| `*Portal`, `*Overlay` parts | `use-portal` attr | React-specific composition; SaladUI handles via attrs. |
| `tooltip_provider` | — | React context for shared delay; not needed in LV. |

---

## 2. Existing components that are shallower than shadcn

| Component | Missing vs shadcn | Kind | Est. |
|---|---|---|---|
| `button` | sizes `xs`, `icon-xs`, `icon-sm`, `icon-lg` (has `default sm lg icon`) | CSS | 15 min |
| `badge` | variants `ghost`, `link`; `as_child`/link rendering | CSS | 15 min |
| `avatar` | `size` (sm/default/lg), `avatar_group`, `avatar_group_count`, `avatar_badge` | CSS | 1 h |
| `card` | `card_action` slot (top-right header action) | CSS | 15 min |
| `dialog` | `dialog_close` part (sheet has one; dialog doesn't) | CSS | 15 min |
| `alert_dialog` | `alert_dialog_media` (icon/media header) | CSS | 15 min |
| `popover` | `popover_header/title/description`, `popover_anchor` | CSS + JS | 1 h |
| `command` | `command_separator` | CSS | 10 min |
| `dropdown_menu` | **sub-menus** (`sub`, `sub_trigger`, `sub_content`), **radio group/items** | JS | 4–5 h |
| `tabs` | `orientation="vertical"`, `variant="line"` on list | CSS + JS keys | 1.5 h |
| `slider` | **range / multiple thumbs**, vertical orientation, non-integer steps | JS | 4 h |
| `switch` | `size="sm"` | CSS | 10 min |
| `select` | trigger `size="sm"`, scroll up/down buttons for long lists | CSS + JS | 1.5 h |
| `scroll_area` | explicit `scroll_bar` part / horizontal scrollbar (verify) | CSS | 30 min |
| `chart` | shadcn = Recharts + `ChartContainer` config (`--chart-1..5` tokens, per-series labels/colors), `ChartTooltipContent`, `ChartLegendContent`. SaladUI = raw Chart.js options. Gap is theming + styled tooltip/legend, not the engine. | JS | 1 day |

---

## 3. Platform / tooling gaps (not components)

| shadcn | SaladUI today | Gap |
|---|---|---|
| `npx shadcn add <component>` — add one component at a time | `mix salad.install` copies everything | Add `mix salad.add button dialog …` (Igniter makes this straightforward). ~4 h |
| 8 visual styles (`vega`, `nova`, `maia`, `lyra`, `mira`, `luma`, `rhea`, `sera`) via `shadcn create` | one style (new-york-ish) + color schemes | Style presets = alternate class sets per component. Large; defer. |
| Blocks (dashboards, login, sidebar layouts) | storybook examples only | Port a handful of blocks as copyable LiveView templates. |
| Base UI / Radix / Aria bases | n/a | Not applicable — SaladUI has its own JS layer. |
| `data-slot` on every part | none | See Tier 1 prerequisite. |

---

## 3b. Tailwind / styling drift

Toolchain is already v4: `config :tailwind, version: "4.3.0"` (latest is 4.3.5),
CSS-first `@import "tailwindcss"` + `@theme inline`, oklch color tokens, `tw-animate`,
installer patches v3 `@tailwind` imports away. The **class strings** are only partly
migrated to shadcn v4's conventions:

| Issue | Where | Impact | Est. |
|---|---|---|---|
| `hsl(var(--sidebar-border))` wrapping an **oklch** token → invalid CSS | `lib/salad_ui/sidebar.ex:738`, `lib/salad_ui/helpers.ex:141` | **Bug:** outline sidebar-menu-button ring doesn't render. Fix: `shadow-[0_0_0_1px_var(--sidebar-border)]`. | 5 min |
| `shadow-sm` where shadcn v4 uses `shadow-xs` (v3→v4 scale shift) | `helpers.ex:91` (default button), `checkbox.ex:55`, `sidebar.ex:148,239` | Slightly heavier shadows than shadcn | 10 min |
| No `aria-invalid:` error styling (shadcn: `aria-invalid:border-destructive aria-invalid:ring-destructive/20`) | inputs, select, checkbox, textarea, etc. | Needed for `field` parity | 1 h |
| `--destructive-foreground` token still used; shadcn v4 dropped it (`text-white`) | color files, button/badge variants | Cosmetic; keep for back-compat or alias | 15 min |
| `@tailwindcss/forms` plugin loaded; shadcn doesn't use it | `assets/css/app.css`, installer `tailwind_patcher.ex` | Resets can fight component styles; consider dropping | 30 min + visual check |
| `h-4 w-4` instead of `size-4` (20 spots) | various | Cosmetic only | 15 min |
| Tailwind binary pin `4.3.0` | `config/config.exs`, `storybook/config/config.exs` | Bump to 4.3.5 | 5 min |

---

## 4. Suggested order

0. **Tailwind drift fixes** from §3b (~2 h) — the `hsl()` bug first.
1. **`data-slot` sweep** across existing components (~2 h) — unblocks Tier 1 styling.
2. **Cheap existing-component deltas** from §2 marked CSS (~2 h total).
3. **Tier 1** primitives: `field` → `input_group` → `button_group` → `item`/`empty`/`kbd`/`spinner`/`native_select`/`aspect_ratio`/`typography` (~1.5 days).
4. **Highest-demand JS**: `dropdown_menu` subs/radio → `combobox` → `calendar` → `date_picker` → `context_menu` (~4 days).
5. Remaining Tier 2, then Tier 3 chat kit, then `mix salad.add`.

Rough total for full component parity: **~3–4 weeks** of focused work; Tiers 1 + step 4
alone cover most real-app needs in **~1 week**.

## Open questions

- Should `field` replace `form` (deprecate) or sit beside it?
- `calendar`: server-rendered grid (LV re-render per month) vs fully client-side? Server-side is simpler and very LiveView-native; client-side feels snappier.
- `data_table`: ship as a component, or as a documented recipe + helpers?
- Chart: keep Chart.js and match shadcn's look, or switch engines?
