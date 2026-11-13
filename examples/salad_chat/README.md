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

## Run it

```bash
cd examples/salad_chat
mix setup        # deps, Tailwind/esbuild, npm install of the local salad_ui package
mix phx.server
```

Open <http://localhost:4000>, pick a user, then open another tab (or a
private window) and pick someone else.

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
| `dropdown_menu` (sub-menus, radio group, link items) | Workspace menu, user menu, message ⋮ menu |
| `context_menu` | Right click (or long press) on a message: the ⋮ menu's actions at the pointer |
| `avatar`, `avatar_badge`, `avatar_group`, `avatar_group_count` | People everywhere, presence dots, channel members, thread participants |
| `badge` | Unread and mention counts, `APP` tag, source chips |
| `tooltip`, `kbd`, `kbd_group` | Icon buttons, keyboard hints |
| `button`, `button_group` | Header actions, message hover toolbar, reminder quick picks |
| `popover` | Pinned messages, emoji pickers |
| `sheet` | Channel details, the thread on phones, the mobile sidebar |
| `tabs` | Channel details, settings |
| `message`, `bubble` | Message rows (ghost bubbles in channels, real bubbles in DMs) |
| `message_scroller` | Main message list and thread: follows new messages at the bottom, keeps your place when older history loads, "jump to latest" button |
| `marker` | Day separators, the "New messages" divider, "Sprout is thinking…" |
| `toggle` | Reaction pills |
| `hover_card` | Profile card on author names |
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
| `field` family, `input`, `native_select`, `select`, `switch`, `radio_group`, `slider`, `checkbox` | Settings and create-channel forms, validated with `to_form/2` of a map |
| `item` | Landing page people, pinned messages, members |
| `empty` | Empty channel, no search results, no thread selected, nothing pinned |
| `scroll_area`, `separator` | Popovers, member lists, header dividers |
| `toaster` / `SaladUI.Toast` | Mentions, DMs, confirmations, errors and flash messages |

## How it is put together

```
lib/salad_chat/
  chat.ex                 # context: users, channels, messages, reactions, pins, read state, PubSub
  chat/store.ex           # GenServer owning the ETS tables (single writer)
  chat/seed.ex            # deterministic seed data
  sprout.ex, sprout/*     # the assistant: reminders + one streaming responder per reply
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

Some pieces wait on components SaladUI doesn't ship yet; look for
`TODO(salad-pass-2)` (date picker).

## Tests

```bash
mix test
```

LiveView tests cover picking a user, sending a message that shows up for a
second connected user, thread replies, reactions, typing, slash commands,
creating a channel, Sprout's streamed reply and settings validation, plus unit
tests for the store.
