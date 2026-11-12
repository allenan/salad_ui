# Unreleased

shadcn/ui v4 parity work (pinned at shadcn `dd41d19`). See `docs/shadcn-parity.md`
for status and known gaps.

**New**
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
  scrollable viewport; the content is capped to the room left in the window,
  so long lists near an edge stay reachable.

**Behaviour changes**
- Form errors are now hidden on fields the user has not touched
  (`Phoenix.Component.used_input?/1`): `form_label`, `form_message` and
  `aria-invalid` all follow this rule.
- Destructive button and badge use `text-white` (with `dark:bg-destructive/60`)
  instead of `--destructive-foreground`; the token is still defined.
- Shadows follow the Tailwind v4 scale (`shadow-xs` on inputs, outline buttons,
  checkbox, select trigger, switch); tooltip content drops its border and shadow
  for shadcn's `bg-foreground text-background` style.
- Button, switch, tabs, dialog, alert dialog and card classes now match shadcn v4,
  so default spacing and sizes shift slightly (card header is a grid).
- Single select trigger is `w-fit` instead of `w-full`; pass a width class to
  keep the old look.
- Badge root is a `<span>` instead of a `<div>`.
- Select and radio group render an extra hidden input so used-input tracking
  works; an empty radio group now submits `""`.
- Toggle puts `aria-invalid` on its button rather than the hidden checkbox.

**Fixes**
- Outline sidebar menu button ring rendered invalid CSS (`hsl()` around an
  oklch token).
- Checkbox indicator survives `@tailwindcss/forms` and dark mode.

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
