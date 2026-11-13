defmodule SaladChatWeb.MessageComponents do
  @moduledoc """
  Everything inside the message list: rows, bodies, reactions, attachments,
  Sprout's trace, the hover actions and the thread summary.

  Rows render no popup of their own. The ⋮ menu, the right-click menu, the
  author hover cards and the tooltips are shared instances that ChatLive
  renders once per page (`message_menus/1`, `author_cards/1`, a
  `tooltip_provider`). Each row only carries their triggers: `for` names the
  instance and `context` (`%{id: message.id}`) tells the menu items which
  message they act on, as `phx-value-id` for their plain `phx-click`. With a
  few hundred messages loaded, a menu, context menu, hover card and tooltips
  per row made the page several times slower to mount. See "Shared menus"
  in `SaladUI.DropdownMenu`.
  """
  use SaladChatWeb, :html

  import SaladChatWeb.People

  alias SaladChat.Chat.Message
  alias SaladChatWeb.{MessageFormat, Paths, TimeFormat}

  @quick_reactions ~w(👍 ✅ 😂)
  @emoji ~w(👍 👎 ✅ 🎉 😂 😍 🙏 🔥 👀 🚀 💯 🌱 ☕ 🍕 🤔 😅 🙌 ✨ 💚 🫡 🐛 📌 🧠 🍜)

  def emoji, do: @emoji

  @doc """
  One row of a message list.

  `row` is `%{id, message, grouped?, day, unread?}`: `grouped?` hides the
  avatar and name under the previous message from the same person, `day` adds
  a date separator and `unread?` the "New messages" divider.

  The row is a `message_scroller_item/1`, so it must be a direct child of a
  `message_scroller_content/1`.
  """
  attr :id, :string, required: true
  attr :row, :map, required: true

  attr :ctx, :map,
    required: true,
    doc: "%{me, users, known, online, tz, editing_id, bubbles?, thread?}"

  def message_row(assigns) do
    assigns =
      assigns
      |> assign(:message, assigns.row.message)
      |> assign(:author, assigns.ctx.users[assigns.row.message.user_id])
      |> assign(:mine?, assigns.row.message.user_id == assigns.ctx.me)

    ~H"""
    <.message_scroller_item
      id={@id}
      message_id={"m-#{@message.id}"}
      data-row
      class="relative"
    >
      <.marker :if={@row.day} variant="separator" class="px-4 py-3">
        <.marker_content class="rounded-full border bg-background px-3 py-0.5 text-xs font-medium text-foreground">
          {@row.day}
        </.marker_content>
      </.marker>
      <.marker
        :if={@row[:unread?]}
        id={"#{@id}-new"}
        variant="separator"
        role="status"
        class="px-4 py-1 text-destructive before:bg-destructive/50 after:bg-destructive/50 [&_hr]:border-destructive/50"
      >
        <.marker_content class="text-xs font-semibold text-destructive">New messages</.marker_content>
      </.marker>
      <%!-- Right click (or long press) opens the page's shared context menu
           (the same actions as the ⋮ menu) for this message. --%>
      <.context_menu_trigger
        as="div"
        for={menu_id(:context, @message, @mine?, @ctx)}
        context={%{id: @message.id}}
        disabled={@message.deleted? or @message.id == @ctx.editing_id or Message.streaming?(@message)}
        class={
          Enum.join(
            [
              "group/msg relative block px-4 transition-colors hover:bg-muted/50 has-[[data-state=open]]:bg-muted/50 data-[state=open]:bg-muted/50",
              if(@row.grouped?, do: "py-0.5", else: "pt-2 pb-0.5"),
              @message.id == @ctx.editing_id && "bg-amber-50 dark:bg-amber-400/5"
            ]
            |> Enum.filter(& &1),
            " "
          )
        }
      >
        <%= if @message.deleted? do %>
          <.deleted_message />
        <% else %>
          <.message
            align={if @ctx.bubbles? and @mine?, do: "end", else: "start"}
            class="gap-3"
          >
            <.message_avatar class="w-9 self-start bg-transparent group-has-data-[slot=message-footer]/message:translate-y-0">
              <%= if @row.grouped? do %>
                <span
                  class="mt-1 hidden w-9 text-center text-[10px] text-muted-foreground tabular-nums group-hover/msg:block"
                  title={TimeFormat.full(@message.inserted_at, @ctx.tz)}
                >
                  {@message.inserted_at
                  |> TimeFormat.time(@ctx.tz)
                  |> String.replace(~r/ [AP]M/, "")}
                </span>
              <% else %>
                <.user_avatar user={@author} class="size-9 rounded-lg" />
              <% end %>
            </.message_avatar>
            <.message_content class="min-w-0 gap-1">
              <.message_header :if={!@row.grouped?} class="gap-2 px-0 text-sm">
                <.author_name user={@author} />
                <.badge :if={@author.bot?} variant="secondary" class="h-4 px-1 text-[10px]">
                  APP
                </.badge>
                <time
                  class="text-xs font-normal text-muted-foreground"
                  datetime={DateTime.to_iso8601(@message.inserted_at)}
                  title={TimeFormat.full(@message.inserted_at, @ctx.tz)}
                >
                  {TimeFormat.time(@message.inserted_at, @ctx.tz)}
                </time>
                <span
                  :if={@message.pinned_by}
                  class="flex items-center gap-0.5 text-xs text-amber-600"
                >
                  <.icon name="hero-bookmark-solid" class="size-3" /> Pinned
                </span>
              </.message_header>

              <%= cond do %>
                <% @message.id == @ctx.editing_id -> %>
                  <.edit_form message={@message} />
                <% @message.bot -> %>
                  <.bot_reply id={@id} message={@message} ctx={@ctx} />
                <% true -> %>
                  <.message_body id={@id} message={@message} ctx={@ctx} mine?={@mine?} />
              <% end %>

              <.attachments
                :if={@message.attachments != []}
                id={@id}
                attachments={@message.attachments}
              />
              <.reactions
                :if={@message.reactions != []}
                id={@id}
                message={@message}
                ctx={@ctx}
              />
              <.message_footer
                :if={(@message.reply_count > 0 and !@ctx.thread?) or @message.edited_at}
                class="gap-2 px-0"
              >
                <.thread_summary
                  :if={@message.reply_count > 0 and !@ctx.thread?}
                  message={@message}
                  ctx={@ctx}
                />
                <span :if={@message.edited_at} class="text-[11px] font-normal">(edited)</span>
              </.message_footer>
            </.message_content>
          </.message>
          <.message_actions
            :if={@message.id != @ctx.editing_id and !Message.streaming?(@message)}
            id={@id}
            message={@message}
            mine?={@mine?}
            ctx={@ctx}
          />
        <% end %>
      </.context_menu_trigger>
    </.message_scroller_item>
    """
  end

  @doc """
  The shared ⋮ and right-click menus of one message list (the channel's, or
  a thread's), rendered once per page.

  The items differ by message: only your own messages can be edited or
  deleted, and a pinned one offers "Unpin". So there is one menu per
  combination (own or not, pinned or not), and each row's triggers name the
  one that fits (`menu_id/4`). The items act on the open row through its
  `context`: `phx-value-id` on their `phx-click`.
  """
  attr :thread?, :boolean, default: false

  def message_menus(assigns) do
    assigns =
      assign(
        assigns,
        :variants,
        for(own? <- [false, true], pinned? <- [false, true], do: {own?, pinned?})
      )

    ~H"""
    <%= for {own?, pinned?} <- @variants do %>
      <.dropdown_menu
        id={menu_id(:more, own?, pinned?, @thread?)}
        use-portal
        portal-container="#chat-portal"
      >
        <.dropdown_menu_content align="end" class="w-56">
          <.dropdown_menu_sub>
            <.dropdown_menu_sub_trigger>
              <.icon name="hero-face-smile" /> React
            </.dropdown_menu_sub_trigger>
            <.dropdown_menu_sub_content class="grid w-auto min-w-0 grid-cols-4 p-1">
              <.dropdown_menu_item
                :for={e <- Enum.take(emoji(), 8)}
                phx-click="react"
                phx-value-emoji={e}
                class="justify-center text-lg"
              >
                {e}
              </.dropdown_menu_item>
            </.dropdown_menu_sub_content>
          </.dropdown_menu_sub>
          <%= for action <- message_menu_actions(own?, pinned?, @thread?) do %>
            <.dropdown_menu_separator :if={action.separator?} />
            <.dropdown_menu_item variant={action.variant} phx-click={action.click}>
              <.icon name={action.icon} /> {action.label}
              <.dropdown_menu_shortcut :if={action.shortcut}>
                {action.shortcut}
              </.dropdown_menu_shortcut>
            </.dropdown_menu_item>
          <% end %>
        </.dropdown_menu_content>
      </.dropdown_menu>
      <.context_menu
        id={menu_id(:context, own?, pinned?, @thread?)}
        use-portal
        portal-container="#chat-portal"
      >
        <.context_menu_content class="w-56">
          <.context_menu_sub>
            <.context_menu_sub_trigger>
              <.icon name="hero-face-smile" /> React
            </.context_menu_sub_trigger>
            <.context_menu_sub_content class="grid w-auto min-w-0 grid-cols-4 p-1">
              <.context_menu_item
                :for={e <- Enum.take(emoji(), 8)}
                phx-click="react"
                phx-value-emoji={e}
                class="justify-center text-lg"
              >
                {e}
              </.context_menu_item>
            </.context_menu_sub_content>
          </.context_menu_sub>
          <%= for action <- message_menu_actions(own?, pinned?, @thread?) do %>
            <.context_menu_separator :if={action.separator?} />
            <.context_menu_item variant={action.variant} phx-click={action.click}>
              <.icon name={action.icon} /> {action.label}
              <.context_menu_shortcut :if={action.shortcut}>
                {action.shortcut}
              </.context_menu_shortcut>
            </.context_menu_item>
          <% end %>
        </.context_menu_content>
      </.context_menu>
    <% end %>
    """
  end

  @doc "The id of the shared menu (`:more` or `:context`) that fits a message."
  def menu_id(kind, %Message{} = message, mine?, ctx) do
    menu_id(kind, mine? and !message.bot, !!message.pinned_by, ctx.thread?)
  end

  def menu_id(kind, own?, pinned?, thread?) do
    Enum.join(
      [
        if(thread?, do: "thread-msg", else: "msg"),
        kind,
        if(own?, do: "own", else: "other"),
        if(pinned?, do: "pinned", else: "unpinned")
      ],
      "-"
    )
  end

  @doc """
  One hover card per person, shared by every message they wrote (their name
  in each row is a detached trigger, `for={author_card_id(user)}`).
  """
  attr :users, :map, required: true
  attr :me, :string, required: true
  attr :online, :any, required: true

  def author_cards(assigns) do
    ~H"""
    <.hover_card :for={{_handle, user} <- @users} id={author_card_id(user)} open-delay={400}>
      <.hover_card_content side="top" align="start" class="w-auto">
        <.profile_card
          user={user}
          me={@me}
          online={user.bot? or MapSet.member?(@online, user.handle)}
        />
      </.hover_card_content>
    </.hover_card>
    """
  end

  def author_card_id(user), do: "author-card-#{user.handle}"

  defp deleted_message(assigns) do
    ~H"""
    <div class="flex items-center gap-3 py-1 text-sm text-muted-foreground italic">
      <span class="flex w-9 justify-center"><.icon name="hero-trash" class="size-4" /></span>
      This message was deleted.
    </div>
    """
  end

  attr :user, :any, required: true

  # The author's name opens their hover card (author_cards/1).
  defp author_name(assigns) do
    ~H"""
    <.hover_card_trigger
      as="button"
      type="button"
      for={author_card_id(@user)}
      class="font-semibold text-foreground hover:underline"
    >
      {@user.name}
    </.hover_card_trigger>
    """
  end

  attr :id, :string, required: true
  attr :message, Message, required: true
  attr :ctx, :map, required: true
  attr :mine?, :boolean, default: false

  @doc "Text, lists and code blocks of a message."
  def message_body(assigns) do
    assigns = assign(assigns, :segments, MessageFormat.segments(assigns.message.body))

    ~H"""
    <div class="flex min-w-0 flex-col gap-2" data-message-text>
      <%= for {segment, i} <- Enum.with_index(@segments) do %>
        <%= case segment do %>
          <% {:text, text} -> %>
            <.bubble
              variant={bubble_variant(@ctx.bubbles?, @mine?)}
              align={if @ctx.bubbles? and @mine?, do: "end", else: "start"}
            >
              <.bubble_content class="chat-text">
                {MessageFormat.to_html(text, @ctx.known, @ctx.me)}
              </.bubble_content>
            </.bubble>
          <% {:code, lang, code} -> %>
            <.snippet id={"#{@id}-code-#{i}"} language={lang} code={code} />
        <% end %>
      <% end %>
    </div>
    """
  end

  defp bubble_variant(true, true), do: "default"
  defp bubble_variant(true, false), do: "muted"
  defp bubble_variant(false, _), do: "ghost"

  attr :id, :string, required: true
  attr :language, :string, default: nil
  attr :code, :string, required: true

  def snippet(assigns) do
    ~H"""
    <.code_block class="max-w-2xl">
      <.code_block_header>
        <.code_block_title>
          <.icon name="hero-code-bracket" class="size-3.5" /> {@language || "text"}
        </.code_block_title>
        <.code_block_actions>
          <.code_block_copy_button id={"#{@id}-copy"} value={@code} />
        </.code_block_actions>
      </.code_block_header>
      <.code_block_content code={@code} language={@language} class="max-h-80" />
    </.code_block>
    """
  end

  attr :message, Message, required: true

  defp edit_form(assigns) do
    ~H"""
    <.form
      for={%{}}
      as={:edit}
      id={"edit-form-#{@message.id}"}
      phx-submit="save_edit"
      class="flex flex-col gap-2 py-1"
    >
      <input type="hidden" name="message_id" value={@message.id} />
      <.input_group id={"edit-group-#{@message.id}"}>
        <.input_group_textarea
          id={"edit-input-#{@message.id}"}
          name="body"
          value={@message.body}
          phx-hook="Composer"
          data-escape="cancel_edit"
          class="min-h-12"
          phx-mounted={JS.focus()}
        />
      </.input_group>
      <div class="flex items-center gap-2">
        <.button type="button" size="sm" variant="outline" phx-click="cancel_edit">Cancel</.button>
        <.button type="submit" size="sm">Save</.button>
        <span class="text-xs text-muted-foreground">
          <.kbd>Enter</.kbd>
          to save ·
          <.kbd>Esc</.kbd>
          to cancel
        </span>
      </div>
    </.form>
    """
  end

  attr :id, :string, required: true
  attr :attachments, :list, required: true

  def attachments(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <%= for {file, i} <- Enum.with_index(@attachments) do %>
        <%= if file.kind == :image do %>
          <.attachment orientation="vertical" class="w-60! max-w-full sm:w-72!">
            <.attachment_media variant="image" class="aspect-[16/10]! w-full">
              <img src={file.url} alt={file.alt} loading="lazy" class="object-cover" />
            </.attachment_media>
            <.attachment_content>
              <.attachment_title>{file.name}</.attachment_title>
              <.attachment_description>
                {file.type} · {SaladUI.Attachment.format_bytes(file.size)}
              </.attachment_description>
            </.attachment_content>
            <.attachment_trigger
              as="a"
              href={file.url}
              target="_blank"
              rel="noopener"
              id={"#{@id}-file-#{i}"}
              aria-label={"Open #{file.name}"}
            />
          </.attachment>
        <% else %>
          <.attachment class="w-64 max-w-full">
            <.attachment_media><.icon name={file_icon(file.name)} /></.attachment_media>
            <.attachment_content>
              <.attachment_title>{file.name}</.attachment_title>
              <.attachment_description>
                {file.type} · {SaladUI.Attachment.format_bytes(file.size)}
              </.attachment_description>
            </.attachment_content>
            <.attachment_actions>
              <.icon name="hero-arrow-down-tray" class="size-4 text-muted-foreground" />
            </.attachment_actions>
            <.attachment_trigger
              as="a"
              href={file.url}
              download={file.name}
              id={"#{@id}-file-#{i}"}
              aria-label={"Download #{file.name}"}
            />
          </.attachment>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp file_icon(name) do
    case Path.extname(name) do
      ext when ext in ~w(.csv .xlsx) -> "hero-table-cells"
      ext when ext in ~w(.sql .ex .exs .js .json) -> "hero-code-bracket-square"
      ".pdf" -> "hero-document"
      ".zip" -> "hero-archive-box"
      _ -> "hero-document-text"
    end
  end

  attr :id, :string, required: true
  attr :message, Message, required: true
  attr :ctx, :map, required: true

  defp reactions(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-1" role="group" aria-label="Reactions">
      <.toggle
        :for={r <- @message.reactions}
        id={"#{@id}-react-#{emoji_key(r.emoji)}"}
        size="sm"
        variant="outline"
        value={@ctx.me in r.users}
        phx-click="react"
        phx-value-id={@message.id}
        phx-value-emoji={r.emoji}
        data-salad-tooltip={reacted_by(r.users, @ctx)}
        class="h-7 gap-1 rounded-full px-2 text-xs data-[state=on]:border-primary/50 data-[state=on]:bg-primary/10 data-[state=on]:text-primary"
      >
        <span class="text-sm leading-none">{r.emoji}</span>
        <span class="tabular-nums">{length(r.users)}</span>
      </.toggle>
      <.reaction_picker id={"#{@id}-add-reaction"} message_id={@message.id} compact />
    </div>
    """
  end

  defp emoji_key(emoji),
    do: emoji |> String.to_charlist() |> Enum.map_join("-", &Integer.to_string(&1, 16))

  defp reacted_by(handles, ctx) do
    names =
      Enum.map(handles, fn
        h when h == ctx.me -> "You"
        h -> ctx.users[h].name
      end)

    case names do
      [one] -> "#{one} reacted"
      _ -> "#{names |> Enum.drop(-1) |> Enum.join(", ")} and #{List.last(names)} reacted"
    end
  end

  @doc """
  The "Add reaction" button: it opens the page's one SaladUI emoji picker
  (rendered by ChatLive), which pushes "react" with this message's id, so a
  long message list costs no popover per row.
  """
  attr :id, :string, required: true
  attr :message_id, :integer, required: true
  attr :compact, :boolean, default: false

  def reaction_picker(assigns) do
    ~H"""
    <.button
      id={@id}
      type="button"
      variant={if @compact, do: "outline", else: "ghost"}
      size="icon-sm"
      class={if @compact, do: "size-7 rounded-full text-muted-foreground"}
      aria-label="Add reaction"
      data-salad-tooltip="Add reaction"
      data-emoji-picker="emoji-picker"
      data-emoji-event="react"
      data-emoji-value-id={@message_id}
    >
      <.icon name="hero-face-smile" />
    </.button>
    """
  end

  attr :message, Message, required: true
  attr :ctx, :map, required: true

  defp thread_summary(assigns) do
    ~H"""
    <.link
      patch={Paths.thread_path(@ctx.me, @message.channel_id, @message.id)}
      class="group/thread -ml-1 flex items-center gap-2 rounded-md p-1 pr-2 text-xs font-medium hover:bg-background hover:ring-1 hover:ring-border"
    >
      <.avatar_group class="*:data-[slot=avatar]:size-5 *:data-[slot=avatar]:ring-1">
        <.user_avatar
          :for={h <- Enum.take(@message.reply_users, 3)}
          user={@ctx.users[h]}
          size="sm"
          class="size-5"
        />
      </.avatar_group>
      <span class="text-primary group-hover/thread:underline">
        {@message.reply_count} {if @message.reply_count == 1, do: "reply", else: "replies"}
      </span>
      <span class="font-normal text-muted-foreground">
        Last reply {TimeFormat.relative(@message.last_reply_at)}
      </span>
    </.link>
    """
  end

  attr :id, :string, required: true
  attr :message, Message, required: true
  attr :mine?, :boolean, required: true
  attr :ctx, :map, required: true

  # The toolbar that appears over a message on hover (always visible as a
  # single "more" button on touch screens).
  defp message_actions(assigns) do
    assigns = assign(assigns, :quick, @quick_reactions)

    ~H"""
    <div class={[
      "absolute -top-4 right-4 z-10 rounded-lg border bg-background p-0.5 shadow-sm transition-opacity",
      "pointer-events-none opacity-0 group-hover/msg:pointer-events-auto group-hover/msg:opacity-100",
      "focus-within:pointer-events-auto focus-within:opacity-100",
      "has-[[data-state=open]]:pointer-events-auto has-[[data-state=open]]:opacity-100",
      "[@media(hover:none)]:pointer-events-auto [@media(hover:none)]:top-1 [@media(hover:none)]:border-0 [@media(hover:none)]:bg-transparent [@media(hover:none)]:opacity-100 [@media(hover:none)]:shadow-none"
    ]}>
      <.button_group aria-label="Message actions">
        <.button
          :for={e <- @quick}
          variant="ghost"
          size="icon-sm"
          class="text-base [@media(hover:none)]:hidden"
          aria-label={"React with #{e}"}
          data-salad-tooltip={"React with #{e}"}
          phx-click={JS.push("react", value: %{id: @message.id, emoji: e})}
        >
          {e}
        </.button>
        <span class="contents [@media(hover:none)]:hidden">
          <.reaction_picker id={"#{@id}-react-more"} message_id={@message.id} />
        </span>
        <.button
          :if={!@ctx.thread?}
          variant="ghost"
          size="icon-sm"
          class="[@media(hover:none)]:hidden"
          aria-label="Reply in thread"
          data-salad-tooltip="Reply in thread"
          phx-click={JS.patch(Paths.thread_path(@ctx.me, @message.channel_id, @message.id))}
        >
          <.icon name="hero-chat-bubble-left-ellipsis" />
        </.button>
        <.dropdown_menu_trigger
          for={menu_id(:more, @message, @mine?, @ctx)}
          context={%{id: @message.id}}
          as={&button/1}
          variant="ghost"
          size="icon-sm"
          aria-label="More actions"
          data-salad-tooltip="More actions"
        >
          <.icon name="hero-ellipsis-vertical" />
        </.dropdown_menu_trigger>
      </.button_group>
    </div>
    """
  end

  # The actions of the ⋮ menu and the right-click context menu (after their
  # "React" sub-menu), for one menu variant. Each one is a plain `phx-click`
  # on an existing ChatLive event that receives the open message's
  # `%{"id" => id}`, except "Copy text", which is handled in the browser
  # (assets/js/chat.js reads the message's text by that id).
  defp message_menu_actions(own?, pinned?, thread?) do
    [
      !thread? && action("hero-chat-bubble-left-ellipsis", "Reply in thread", "open_thread"),
      action("hero-clipboard-document", "Copy text", JS.dispatch("salad-chat:copy")),
      action(
        if(pinned?, do: "hero-bookmark-slash", else: "hero-bookmark"),
        if(pinned?, do: "Unpin from channel", else: "Pin to channel"),
        "toggle_pin"
      ),
      action("hero-bell-alert", "Remind me about this", "remind"),
      action("hero-eye-slash", "Mark unread", "mark_unread"),
      own? && action("hero-pencil", "Edit message", "edit", separator?: true, shortcut: "E"),
      own? && action("hero-trash", "Delete message", "confirm_delete", variant: "destructive")
    ]
    |> Enum.filter(& &1)
  end

  defp action(icon, label, click, opts \\ []) do
    %{
      icon: icon,
      label: label,
      click: click,
      separator?: Keyword.get(opts, :separator?, false),
      shortcut: Keyword.get(opts, :shortcut),
      variant: Keyword.get(opts, :variant, "default")
    }
  end

  ## Sprout

  attr :id, :string, required: true
  attr :message, Message, required: true
  attr :ctx, :map, required: true

  @doc "Sprout's reply: its trace (reasoning, tool call, sources), then the answer."
  def bot_reply(assigns) do
    assigns = assign(assigns, :bot, assigns.message.bot)

    ~H"""
    <div class="flex min-w-0 flex-col gap-2">
      <.trace class="max-w-xl">
        <.trace_collapsible id={"#{@id}-reasoning"} open={@bot.status == :thinking}>
          <.trace_collapsible_trigger>
            <.trace_line status={running(@bot.status == :thinking)}>
              <.trace_icon><.icon name="hero-light-bulb" /></.trace_icon>
              <.trace_title>
                {if @bot.status == :thinking,
                  do: "Thinking",
                  else: "Thought for #{seconds(@bot.thought_ms)}"}
              </.trace_title>
            </.trace_line>
          </.trace_collapsible_trigger>
          <.trace_collapsible_content>{@bot.reasoning}</.trace_collapsible_content>
        </.trace_collapsible>

        <.trace_collapsible :if={@bot.status != :thinking} id={"#{@id}-tool"}>
          <.trace_collapsible_trigger>
            <.trace_line status={running(@bot.status == :searching)}>
              <.trace_icon><.icon name="hero-magnifying-glass" /></.trace_icon>
              <.trace_title>
                {if @bot.status == :searching, do: "Searching messages", else: "Searched messages"} for “{@bot.query}”
              </.trace_title>
              <.trace_description :if={@bot.status != :searching}>
                {length(@bot.results)} results
              </.trace_description>
            </.trace_line>
          </.trace_collapsible_trigger>
          <.trace_collapsible_content class="flex flex-col gap-2">
            <.code_block size="sm">
              <.code_block_header>
                <.code_block_title>search_messages · input</.code_block_title>
              </.code_block_header>
              <.code_block_content
                code={Jason.encode!(%{query: @bot.query, limit: 3}, pretty: true)}
                language="json"
                class="text-foreground"
              />
            </.code_block>
            <.code_block size="sm">
              <.code_block_header>
                <.code_block_title>output</.code_block_title>
              </.code_block_header>
              <.code_block_content
                code={
                  Jason.encode!(Enum.map(@bot.results, &Map.take(&1, [:id, :where, :excerpt])),
                    pretty: true
                  )
                }
                language="json"
                wrap
                class="max-h-48 text-foreground"
              />
            </.code_block>
          </.trace_collapsible_content>
        </.trace_collapsible>

        <.trace_collapsible
          :if={@bot.status in [:answering, :done] and @bot.results != []}
          id={"#{@id}-sources"}
        >
          <.trace_collapsible_trigger>
            <.trace_line>
              <.trace_icon><.icon name="hero-book-open" /></.trace_icon>
              <.trace_title>Read {length(@bot.results)} sources</.trace_title>
            </.trace_line>
          </.trace_collapsible_trigger>
          <.trace_collapsible_content class="flex flex-col gap-1">
            <.link
              :for={r <- @bot.results}
              patch={source_path(@ctx.me, r)}
              class="flex items-start gap-2 rounded-md px-1 py-0.5 text-foreground hover:bg-muted"
            >
              <.badge variant="outline" class="shrink-0">{r.where}</.badge>
              <span class="line-clamp-1 text-xs">{r.excerpt}</span>
            </.link>
          </.trace_collapsible_content>
        </.trace_collapsible>
      </.trace>

      <.marker :if={@bot.status in [:thinking, :searching]} role="status">
        <.marker_icon><.spinner /></.marker_icon>
        <.marker_content class="shimmer">
          {if @bot.status == :thinking, do: "Sprout is thinking…", else: "Searching the workspace…"}
        </.marker_content>
      </.marker>

      <.bubble :if={@bot.status in [:answering, :done]} variant="ghost" data-message-text>
        <.bubble_content class={
          if @bot.status == :answering, do: "chat-text stream-caret", else: "chat-text"
        }>
          <%= for segment <- MessageFormat.segments(@message.body) do %>
            <%= case segment do %>
              <% {:text, text} -> %>
                {MessageFormat.to_html(text, @ctx.known, @ctx.me)}
              <% {:code, lang, code} -> %>
                <.snippet id={"#{@id}-answer-code"} language={lang} code={code} />
            <% end %>
          <% end %>
        </.bubble_content>
      </.bubble>
    </div>
    """
  end

  defp source_path(me, %{channel_id: channel_id, id: id}) do
    case SaladChat.Chat.get_message(id) do
      %Message{parent_id: parent_id} when is_integer(parent_id) ->
        Paths.thread_path(me, channel_id, parent_id)

      %Message{} ->
        Paths.thread_path(me, channel_id, id)

      nil ->
        Paths.channel_path(me, channel_id)
    end
  end

  defp running(true), do: "running"
  defp running(false), do: nil

  defp seconds(nil), do: "a moment"
  defp seconds(ms), do: "#{Float.round(ms / 1000, 1)}s"

  ## Loading and empty states

  @doc "Placeholder rows shown while history loads."
  attr :count, :integer, default: 4
  attr :id, :string, default: nil

  def message_skeletons(assigns) do
    ~H"""
    <div id={@id} class="flex flex-col gap-5 px-4 py-4" aria-busy="true" aria-label="Loading messages">
      <div :for={i <- 1..@count} class="flex gap-3">
        <.skeleton class="size-9 shrink-0 rounded-lg" />
        <div class="flex flex-1 flex-col gap-2">
          <div class="flex gap-2">
            <.skeleton class="h-3.5 w-28" />
            <.skeleton class="h-3.5 w-12" />
          </div>
          <.skeleton class={"h-3.5 " <> Enum.at(~w(w-3/4 w-1/2 w-2/3 w-5/6), rem(i, 4))} />
          <.skeleton :if={rem(i, 2) == 1} class="h-3.5 w-1/3" />
        </div>
      </div>
    </div>
    """
  end

  @doc "Who is typing, under the composer."
  attr :names, :list, required: true

  def typing_indicator(assigns) do
    ~H"""
    <div class="flex h-5 items-center gap-1.5 px-1 text-xs text-muted-foreground" aria-live="polite">
      <%= if @names != [] do %>
        <span class="typing-dots flex gap-0.5" aria-hidden="true">
          <span class="size-1 rounded-full bg-current"></span>
          <span class="size-1 rounded-full bg-current"></span>
          <span class="size-1 rounded-full bg-current"></span>
        </span>
        <span><strong class="font-medium text-foreground">{typing_text(@names)}</strong></span>
      <% end %>
    </div>
    """
  end

  defp typing_text([name]), do: "#{name} is typing…"
  defp typing_text([a, b]), do: "#{a} and #{b} are typing…"
  defp typing_text(_), do: "Several people are typing…"
end
