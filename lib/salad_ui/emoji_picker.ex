defmodule SaladUI.EmojiPicker do
  @moduledoc """
  An emoji picker in a popover: search by name, categories, recently used
  emoji, an optional skin tone, and full keyboard use (the arrow keys move
  through the grid from the search box, Enter picks, Escape closes and returns
  focus).

  shadcn/ui has no emoji picker; this one is built from SaladUI's popover and
  shadcn's tokens, in the spirit of the community `emoji-picker` block.

  ## One picker, many openers

  Render one picker per page and open it from any number of plain buttons, so
  a long list of messages costs no hook per row:

      <.emoji_picker id="emoji-picker" portal-container="#portal" on-select="emoji_picked" />

      <button type="button" data-emoji-picker="emoji-picker"
              data-emoji-event="react" data-emoji-value-message-id={@message.id}>
        Add reaction
      </button>

  A pick then:

    * pushes the opener's `data-emoji-event`, if it has one, with its
      `data-emoji-value-*` attributes (like `phx-value-*`, so
      `data-emoji-value-message-id` arrives as `"message_id"`) and `"emoji"`;
    * runs `on-select` (an event name, pushed with `"emoji"` and `"name"`, or
      a `Phoenix.LiveView.JS` command);
    * dispatches a bubbling `emoji-picker:select` DOM event (`detail:
      {emoji, name}`) on the opener once the picker has closed, so a hook can
      insert the emoji at its cursor.

  Events go to the LiveView (or LiveComponent) the picker is rendered in.

  ## Opening it from code

      SaladUI.JS.dispatch_command("open", to: "#emoji-picker",
        detail: %{anchor: "#more-button", event: "react",
                  values: %{message_id: id}, return_focus: "#more-button"})

      SaladUI.LiveView.send_command(socket, "emoji-picker", "open", %{anchor: "#more-button"})

  `anchor` and `return_focus` are selectors; `close` and `toggle` work too.

  ## JavaScript

  The behaviour is the `emoji-picker` component in
  `salad_ui/components/emoji_picker.js` (import it in `app.js`; `mix
  salad.setup` and `mix salad.install` do). Its dataset (`emoji_picker/data.json`,
  about 53 KB, generated from Unicode's emoji list; Unicode License V3, see
  `DATA_LICENSE.txt` beside it) is loaded with a dynamic `import()` the first
  time a picker opens.

  To keep the dataset out of the main bundle, build with code splitting, e.g.
  esbuild `--splitting --format=esm` and load `app.js` with
  `<script type="module">`. Without splitting esbuild inlines it into the
  bundle; the picker still works.

  Keep Tailwind from scanning the dataset for class names (`mix salad.setup`
  and `mix salad.install` add these):

      @source not "../../deps/salad_ui/assets/salad_ui/components/emoji_picker";
      @source not "../js/ui/components/emoji_picker";

  ## Labels

  The strings are English; `labels` overrides any of them (atom or string
  keys): `emoji`, `search`, `categories`, `recent`, `results`, `empty`,
  `tone`, `tones` (six names, no tone first) and `groups` (category key to
  name: `smileys`, `people`, `nature`, `food`, `travel`, `activities`,
  `objects`, `symbols`, `flags`).

  Recently used emoji and the skin tone are kept in `localStorage` under
  `storage-key`.
  """
  use SaladUI, :component

  import SaladUI.Popover

  @default_labels %{
    "emoji" => "Emoji",
    "search" => "Search emoji",
    "categories" => "Emoji categories",
    "recent" => "Recently used",
    "results" => "Search results",
    "empty" => "No emoji found.",
    "tone" => "Skin tone",
    "tones" => ["No skin tone", "Light", "Medium-light", "Medium", "Medium-dark", "Dark"]
  }

  @doc "The English strings `labels` overrides."
  def default_labels, do: @default_labels

  attr :id, :string, required: true
  attr :"portal-container", :string, default: nil, doc: "a selector inside the LiveView to portal the content into"
  attr :labels, :map, default: %{}, doc: "overrides for the English strings (see the module doc)"
  attr :"storage-key", :string, default: "salad-ui:emoji-picker", doc: "localStorage key prefix"
  attr :side, :string, values: ~w(top right bottom left), default: "top"
  attr :align, :string, values: ~w(start center end), default: "end"
  attr :"on-select", :any, default: nil, doc: "event name or JS command run on a pick"
  attr :class, :any, default: nil, doc: "classes for the popover content"
  attr :rest, :global

  def emoji_picker(assigns) do
    labels = Map.merge(@default_labels, Map.new(assigns.labels, fn {k, v} -> {to_string(k), v} end))

    assigns =
      assign(assigns,
        portal: assigns[:"portal-container"],
        l: labels,
        event_map: json(event_mappings(assigns)),
        options: json(%{labels: labels, storageKey: assigns[:"storage-key"]})
      )

    ~H"""
    <div
      id={@id}
      data-slot="emoji-picker"
      data-component="emoji-picker"
      data-part="root"
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      class="contents"
      {@rest}
    >
      <.popover
        id={"#{@id}-popover"}
        use-portal={!is_nil(@portal)}
        portal-container={@portal}
        on-close={JS.dispatch("emoji-picker:closed", to: "##{@id}")}
      >
        <.popover_anchor id={"#{@id}-anchor"} class="pointer-events-none fixed top-0 left-0 size-px" />
        <.popover_content
          side={@side}
          align={@align}
          collision-padding={8}
          aria-label={@l["emoji"]}
          class={
            classes([
              "w-[22rem] max-w-[calc(100vw-1rem)] overflow-hidden p-0 max-[479px]:w-[calc(100vw-1rem)]",
              @class
            ])
          }
        >
          <div
            id={"#{@id}-panel"}
            data-slot="emoji-picker-panel"
            phx-update="ignore"
            class="flex flex-col"
          >
            <div class="relative p-2">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="pointer-events-none absolute top-1/2 left-4.5 size-4 -translate-y-1/2 text-muted-foreground"
                aria-hidden="true"
              >
                <path d="m21 21-4.34-4.34" /><circle cx="11" cy="11" r="8" />
              </svg>
              <input
                id={"#{@id}-search"}
                data-slot="emoji-picker-search"
                type="search"
                autofocus
                autocomplete="off"
                spellcheck="false"
                role="combobox"
                aria-expanded="true"
                aria-autocomplete="list"
                aria-controls={"#{@id}-grid"}
                aria-label={@l["search"]}
                placeholder={@l["search"]}
                class="h-9 w-full min-w-0 rounded-md border border-input bg-transparent py-1 pr-3 pl-8 text-base shadow-xs outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 md:text-sm dark:bg-input/30 pointer-coarse:h-11"
              />
            </div>
            <nav
              data-slot="emoji-picker-nav"
              aria-label={@l["categories"]}
              class="flex gap-0.5 overflow-x-auto border-b border-border px-2 pb-1.5"
            >
            </nav>
            <div
              id={"#{@id}-grid"}
              data-slot="emoji-picker-grid"
              role="listbox"
              aria-label={@l["emoji"]}
              class="relative h-64 overflow-y-auto overscroll-contain px-1.5 pb-1.5 text-sm text-muted-foreground"
            >
            </div>
            <div class="flex h-12 items-center gap-2 border-t border-border px-3 pointer-coarse:h-14">
              <div
                data-slot="emoji-picker-preview"
                class="flex min-w-0 flex-1 items-center gap-2"
                aria-hidden="true"
              >
                <span class="text-2xl leading-none"></span>
                <span class="truncate text-xs text-muted-foreground"></span>
              </div>
              <div
                data-slot="emoji-picker-tones"
                role="group"
                aria-label={@l["tone"]}
                hidden
                class="flex min-w-0 flex-1 items-center gap-0.5"
              >
                <button
                  :for={tone <- 0..5}
                  type="button"
                  data-tone={tone}
                  class="flex size-8 items-center justify-center rounded-md text-lg leading-none outline-none hover:bg-accent focus-visible:ring-[3px] focus-visible:ring-ring/50 aria-pressed:bg-accent pointer-coarse:size-11"
                ></button>
              </div>
              <button
                type="button"
                data-slot="emoji-picker-tone-button"
                aria-expanded="false"
                class="flex size-8 flex-none items-center justify-center rounded-md text-lg leading-none outline-none hover:bg-accent focus-visible:ring-[3px] focus-visible:ring-ring/50 pointer-coarse:size-11"
              ></button>
            </div>
          </div>
        </.popover_content>
      </.popover>
    </div>
    """
  end
end
