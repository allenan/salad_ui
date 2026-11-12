# shadcn/ui parity — gap catalog

## Status

Run against shadcn/ui ref `dd41d19e2f80ff6891951f7ced74c2c9a650b065`. All four
items below are on `parity/integration`; the rest of the catalog (Tier 1–3
components, dropdown sub-menus/radio, slider range, chart theming, `mix salad.add`)
was not part of this run.

| Item | Status | Commit | What landed |
|---|---|---|---|
| `tailwind-drift` | pushed | `696806c` | v4 shadow scale; `aria-invalid:` styling + automatic `aria-invalid="true"` on touched FormFields (input, textarea, select trigger, checkbox, radio, switch, toggle); destructive `text-white`; `size-N`; button xs/icon-* sizes; badge ghost/link; switch `size`; tooltip `bg-foreground` style; sidebar `hsl(oklch)` bug fixed. |
| `data-slot` | pushed | `32390fc` | shadcn `data-slot` on every part of every component; `put_data_slot/2` helper; `data_slot_test.exs`. |
| `overlay-deltas` | pushed + reviewed | `67f6c67`, review fix `ac341c8` | Popover header/title/description/anchor; tabs vertical + `line` variant; select scroll buttons + viewport, capped to available window height. |
| `small-deltas` | pushed | `3c5f6de` | Button/badge as `<a>`; card action/size/spacing; dialog close parts; alert-dialog media/size; command separator; avatar sizes/badge/group; scroll-area orientation. |

### Not covered

**tailwind-drift**
- Tooltip has no arrow part (shadcn renders `TooltipPrimitive.Arrow`).
- `toggle_group` items have no `aria-invalid:` styling (only `toggle` was in scope).
- Checkbox custom colors use `checked:` rather than `data-[state=checked]:` (native input; documented in moduledoc).

**data-slot**
- `form_control` has no `form-control` slot: it renders no wrapper, and adding one breaks `form_item`'s `space-y` layout.
- `menu` has no shadcn counterpart; its parts use invented `menu-*` names.
- No slot on toast/toaster (sonner has none either) or `icon`.
- No slots for parts SaladUI lacks: `checkbox-indicator`, `scroll-area-scrollbar/thumb`, `table-container`, dropdown-menu radio/sub/portal. Popover and dropdown positioner wrappers have none, matching Radix.

**overlay-deltas**
- Select: no `position="item-aligned"` (always popper); no first-class `disabled` attr on `select/1` (story uses `data-disabled`).
- `popover-form` example uses plain label/input (no `field` component yet).
- RTL examples (popover, tabs, select) not covered.
- Out of scope, still differs: `popover_content` default side-offset 8 (shadcn 4); `select_label`/`select_item` classes and check-indicator side.

**small-deltas**
- RTL examples for button, badge, card, dialog, alert-dialog, command, switch, avatar, scroll-area (→ `direction`).
- `button-group-demo` (→ `button_group`); `switch-description`/`switch-choice-card` (→ `field`).
- No `spinner` yet: button/badge spinner examples use an `animate-spin` icon.
- No separate `scroll_bar` part: horizontal scroll is `orientation="horizontal"` with styled native scrollbars.
- `card-spacing` example shows two fixed spacings, not the interactive ToggleGroup switcher.

### Remaining review issues

From the `overlay-deltas` review (none block merge):
1. Tabs: no RTL key swap (`dir=rtl` should swap Left/Right). Belongs to a cross-cutting `direction` item.
2. Tabs: Radix also puts `data-orientation` on list/triggers/content; shadcn's classes only read the root, so low value.
3. Popover anchor: clicking the anchor keeps the popover open (Radix closes it). Kept deliberately — friendlier when the anchor wraps an input.
4. Popover title/description are not wired to `aria-labelledby`/`aria-describedby` (Radix doesn't either; client-generated ids break LiveView patching).
5. Select (pre-existing): any LiveView patch re-renders `data-state="closed"`, so an open select closes on patch.

Carried over from the earlier `tailwind-drift` review, still open:
- `docs/manual_install.md` still maps colors as `hsl(var(--x))`; switch to `var(--x)` / `@theme inline` and add sidebar, radius and chart tokens.
- `checkbox` has `indeterminate:` styles but no attr sets `el.indeterminate`.
- Token naming: `--sidebar-background` vs shadcn's `--sidebar`.
- Empty `multiple` select is never flagged invalid after submit (its tracking input is `disabled`, so `used_input?/1` is false).
- Select trigger `aria-invalid` is set only by the JS hook, so it is missing on dead render and briefly on each patch.
- Leftover `h-4 w-4` pairs in `test/salad_ui/dropdown_menu_test.exs` (cosmetic).

Resolved since that review: installer `hsl(var(--border))` (now `var(--border)` + `@apply border-border outline-ring/50`), toggle `aria-invalid`/`data-slot`, tooltip shadow, badge/button link rendering, CHANGELOG entry.

---

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
