# shadcn/ui parity — gap catalog

## Status

Run against shadcn/ui ref `dd41d19e2f80ff6891951f7ced74c2c9a650b065`.

| Item | Status | Branch | Notes |
|---|---|---|---|
| `tailwind-drift` | needs-human | `parity/tailwind-drift` | Review left 1 must + 10 should (deduplicated). Not integrated. |
| `data-slot` | blocked | — | Blocked by `tailwind-drift`. |
| `small-deltas` | blocked | — | Blocked by `data-slot`. |
| `tiny-primitives` | blocked | — | Blocked by `data-slot`. |

### Open "should" findings on integrated items

None. No item has been integrated into `parity/integration` yet.

### `tailwind-drift`: findings blocking integration

**Must (blocks merge):**

- Installers still emit `border-color: hsl(var(--border));` after an oklch color
  scheme (`lib/mix/tasks/salad.setup.ex:118`, `lib/mix/tasks/salad.install.ex:177`).
  `hsl(oklch(...))` is invalid, so bare `border` renders in `currentColor`.
  Fix: `border-color: var(--border);` plus an `outline-color` for `ring/50`,
  matching shadcn's `* { @apply border-border outline-ring/50 }`.

**Should (open, carry forward once merged):**

1. `docs/manual_install.md` still maps colors as `hsl(var(--x))` and points at
   shadcn themes (now oklch). Switch to `var(--x)` / `@theme inline`; add sidebar,
   radius and chart tokens.
2. Bare `aria-invalid` (HEEx port of `<Input aria-invalid />`) renders without a
   value, so `aria-invalid:` styles and AT announcement don't fire. Have
   `put_aria_invalid/1` map `true` to `"true"`, or document the string form.
3. `toggle` lacks shadcn's `aria-invalid:*` classes and `data-slot="toggle"`;
   tooltip content keeps `shadow-md` (shadcn v4 has none).
4. `badge` ships `[a&]:hover:*` classes but always renders `<span>` with no
   `as_child`/`href`; `button` has no `as_child` either (badge-link,
   button-aschild examples can't be written). Likely belongs to badge/button items.
5. `checkbox` has `indeterminate:` styles but no attr sets `el.indeterminate`.
6. Token naming: `--sidebar-background` vs shadcn's `--sidebar`; library CSS and
   storybook ship no `* { border-color: var(--border) }` base rule.
7. Leftover `h-4 w-4` pairs in `test/salad_ui/dropdown_menu_test.exs`
   (lines 37–114). Cosmetic.
8. Empty `multiple` select is never flagged invalid after submit: its tracking
   input is `disabled`, so the key is absent from params and `used_input?/1` is
   false. Moduledoc claim is wrong for this case; add a test.
9. CHANGELOG entry needed: errors now hidden on unused fields
   (`form_label`/`form_message`/`aria-invalid`), single-select trigger `w-full` →
   `w-fit`, badge root `div` → `span`, empty radio groups submit `""`.
10. Select trigger's `aria-invalid` is set only by the JS hook, so it is missing
    on dead render and briefly on each patch. Documented; optional fix is passing
    `invalid` to `select_trigger` server-side.

(The review also repeated the installer `hsl(var(--border))` issue as a "should";
it is the same fix as the must above.)

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
