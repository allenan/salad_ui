# Salad Chat

A Slack-style team chat built with [SaladUI](../../README.md) and Phoenix
LiveView. It is the library's showcase app: almost every pixel on screen is a
SaladUI component, wired to a realistic, real-time workspace.

- **No auth.** The landing page lists the people in the "Greenhouse"
  workspace; pick one and the identity is part of the URL
  (`/as/maya/c/general`). Open a second tab as someone else to watch messages,
  reactions, typing and presence move between them.
- **No database.** Everything lives in an in-memory ETS store
  (`SaladChat.Chat`), seeded on boot with deterministic people, channels and
  about ten days of history. **It resets on every restart.**
- **Sprout**, the AI assistant, answers in `#ai-assistant`, in a DM, or when
  @mentioned. It is canned (no model): it shows its reasoning, a real
  `search_messages` tool call against the store, its sources, and then streams
  the answer token by token.
- **Simulated activity.** `SaladChat.Activity` has the seeded people post in
  the public channels, react, reply in threads and send the odd DM every
  6-20 seconds, with a typing indicator first, so the real-time parts move
  even when you are alone. Anyone with a tab open is left alone, simulated
  people show as online while active, and only the newest 200 simulated
  messages per conversation are kept. Turn it off with
  `SALAD_CHAT_ACTIVITY=off mix phx.server`; it is always off in tests.

## Run it

```bash
cd examples/salad_chat
mix setup        # deps, Tailwind/esbuild, npm install of the local salad_ui package
mix phx.server
```

Open <http://localhost:4000>, pick a user, then open another tab (or a
private window) and pick someone else.

### On your tailnet

To try it from a phone, run a production build on loopback and let
[`tailscale serve`](https://tailscale.com/kb/1312/serve) put HTTPS in front
of it (tailnet only, not the public internet):

`mix assets.deploy` writes digested copies next to the seed images, so do
this in a separate checkout:

```bash
git worktree add --detach ../salad_ui-host main
cd ../salad_ui-host/examples/salad_chat
export MIX_ENV=prod PHX_SERVER=true PHX_IP=127.0.0.1 PORT=4100
export SECRET_KEY_BASE=$(mix phx.gen.secret)
export PHX_HOST=$(tailscale status --json | jq -r '.Self.DNSName | rtrimstr(".")')
mix deps.get --only prod && mix compile && mix assets.deploy
mix phx.server &
tailscale serve --bg 4100
```

Then open `https://$PHX_HOST` on any device in the tailnet. The first
`tailscale serve` on a tailnet prints a link to enable Serve (and HTTPS
certificates) in the admin console; it finishes once that is done.
`tailscale serve reset` stops serving.

Try:

- <kbd>⌘K</kbd> / <kbd>Ctrl+K</kbd> for the quick switcher, <kbd>⌥1</kbd>–<kbd>⌥5</kbd> to jump between channels.
- Hover a message for reactions, "Reply in thread" and the ⋮ menu (pin, remind, edit, delete), or right click it for the same actions.
- Type `/` in the composer for slash commands (`/shrug`, `/me`, `/topic`, `/sprout`, `/theme`).
- Ask Sprout "What did we decide about webhook retries?" in `#ai-assistant`.
- Drag files onto the composer, or use the paper clip.
- Open **Preferences** from the user menu for the settings dialog, and switch to dark mode.

## Which component does what

| SaladUI component | Where it shows up |
| --- | --- |
| `sidebar` (+ `sidebar_trigger`, `sidebar_rail`, menu parts) | Workspace sidebar, collapsible to icons; a sheet on phones |
| `collapsible` | Channel and DM sections in the sidebar; Sprout's trace rows |
| `dropdown_menu` (sub-menus, radio group, link items) | Workspace menu, user menu, message ⋮ menu (shared, see below) |
| `context_menu` | Right click (or long press) on a message: the ⋮ menu's actions at the pointer (shared) |
| `avatar`, `avatar_badge`, `avatar_group`, `avatar_group_count` | People everywhere, presence dots, channel members, thread participants |
| `badge` | Unread and mention counts, `APP` tag, source chips |
| `tooltip`, `kbd`, `kbd_group` | Header icon buttons, keyboard hints |
| `tooltip_provider` (`data-salad-tooltip`) | Text tooltips on the message toolbar and reaction pills ("Maya and Leo reacted"), one tooltip for the page |
| `button`, `button_group` | Header actions, message hover toolbar, reminder quick picks |
| `popover` | Pinned messages |
| `emoji_picker` | One picker for the page: the composer's emoji button (inserts at the cursor) and every message's "Add reaction" (search, categories, recents, skin tone) |
| `drop_zone` | Drag files over the conversation to attach them; pasted files attach too (`attachFiles`) |
| `sheet` | Channel details, the thread on phones, the mobile sidebar |
| `tabs` | Channel details, settings |
| `message`, `bubble` | Message rows (ghost bubbles in channels, real bubbles in DMs) |
| `message_scroller` | Main message list and thread: follows new messages at the bottom, keeps your place when older history loads, "jump to latest" button |
| `marker` | Day separators, the "New messages" divider, "Sprout is thinking…" |
| `toggle` | Reaction pills |
| `hover_card` | Profile card on author names: one card per person, shared by all their messages |
| `code_block` | Code snippets in messages and Sprout's tool input/output (Makeup highlighting) |
| `attachment` (+ `attachment_upload_entry`) | Files and images in messages, upload previews with progress/cancel |
| `trace` | Sprout's reasoning, `search_messages` tool call and sources |
| `spinner`, `skeleton` | Sprout thinking, history loading |
| `resizable` | Main list \| thread pane on desktop |
| `input_group`, `textarea` | The composer (attach, emoji, commands, send), topic editor |
| `command`, `command_dialog` | ⌘K quick switcher, slash command suggestions |
| `combobox` (single, and multiple with chips) | "Jump to…" channel/people search in the header, member picker when creating a channel |
| `alert_dialog` | Delete confirmation |
| `dialog` | Settings, create channel, "Remind me about this" |
| `date_picker` (`calendar` in a popover, with presets) | The reminder's date, next to a time input |
| `field` family, `input`, `native_select`, `select`, `switch`, `radio_group`, `slider`, `checkbox` | Settings and create-channel forms, validated with `to_form/2` of a map |
| `item` | Landing page people, pinned messages, members |
| `empty` | Empty channel, no search results, no thread selected, nothing pinned |
| `scroll_area`, `separator` | Popovers, member lists, header dividers |
| `toaster` / `SaladUI.Toast` | Mentions, DMs, confirmations, errors and flash messages |

### Message rows use shared instances

A message row renders no menu, hover card or tooltip of its own. ChatLive
renders them once per page and each row carries only their triggers:

- the ⋮ button is a `dropdown_menu_trigger` and the row a
  `context_menu_trigger`, with `for` (the shared menu's id) and
  `context={%{id: message.id}}`. While a menu is open for a row, SaladUI
  writes that context on its items as `phx-value-id`, so the items are plain
  `phx-click="toggle_pin"` and ChatLive's handlers read `%{"id" => id}`. There
  is one menu per variant (your own message or not, pinned or not, channel
  or thread), since their items differ (`MessageComponents.message_menus/1`);
- the author's name is a `hover_card_trigger` for that person's card
  (`author_cards/1`: one per person, not per message);
- toolbar buttons and reaction pills carry `data-salad-tooltip="…"`, shown
  by the page's one `tooltip_provider`.

With a few hundred messages loaded, a menu, a context menu, a hover card and
two tooltips in every row made the page several times slower to mount and
much heavier (each row carried all of their hidden markup and five hooks).
See "Shared menus" in `SaladUI.DropdownMenu`, "Text tooltips for long lists"
in `SaladUI.Tooltip` and "Shared hover cards for long lists" in
`SaladUI.HoverCard`.

## How it is put together

```
lib/salad_chat/
  chat.ex                 # context: users, channels, messages, reactions, pins, read state, PubSub
  chat/store.ex           # GenServer owning the ETS tables (single writer)
  chat/seed.ex            # deterministic seed data
  sprout.ex, sprout/*     # the assistant: reminders + one streaming responder per reply
  activity.ex, activity/* # simulated people chatting on a timer
lib/salad_chat_web/
  live/chat_live.ex       # the chat page (streams, PubSub, presence, typing)
  live/landing_live.ex    # pick a user
  live/settings_component.ex, live/new_channel_component.ex
  components/             # sidebar, header, message rows, composer, thread pane, overlays
assets/js/chat.js         # composer hook, shortcuts, theme
```

SaladUI is used in library mode: a path dependency on the repo
(`{:salad_ui, path: "../.."}`), Tailwind sources pointed at the repo's `lib`
and `assets/salad_ui`, and the JS resolved through npm (`"salad_ui":
"file:../../.."`) so `import "salad_ui/components/dialog"` goes through the
package's `exports`.

## Tests

```bash
mix test
```

LiveView tests cover picking a user, sending a message that shows up for a
second connected user, thread replies, reactions, typing, slash commands,
creating a channel, Sprout's streamed reply and settings validation, plus unit
tests for the store.
