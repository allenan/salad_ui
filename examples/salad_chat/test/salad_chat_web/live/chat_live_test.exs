defmodule SaladChatWeb.ChatLiveTest do
  use SaladChatWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias SaladChat.Chat

  setup do
    Chat.reset!()
    :ok
  end

  describe "landing" do
    test "lists the people to sign in as", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      assert html =~ "Salad Chat"
      assert html =~ "Maya Okafor"
      assert html =~ "Staff Engineer"
      refute html =~ "Sprout"

      assert {:error, {:live_redirect, %{to: "/as/maya/c/general"}}} =
               view |> element("#pick-maya") |> render_click()
    end

    test "picking a user opens #general", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/")
      {:ok, chat, _} = view |> element("#pick-leo") |> render_click() |> follow_redirect(conn)

      html = render(chat)
      assert html =~ "Welcome to #general" or html =~ "Message #general"
      assert has_element?(chat, "#app-sidebar", "Leo Brandt")
      assert has_element?(chat, "#messages [data-row]")
    end

    test "an unknown user is sent back to the landing page", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/as/nobody/c/general")
    end
  end

  describe "channel" do
    test "renders history, header, members and the composer", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/as/maya/c/engineering")

      assert html =~ "Deploying v2.15 to production"
      assert has_element?(view, "header", "engineering")
      assert has_element?(view, "#main-form textarea")
      # code snippets go through SaladUI.CodeBlock
      assert has_element?(view, "[data-slot=code-block]")
      # thread summaries link to the thread
      assert has_element?(view, "a[href^='/as/maya/c/engineering/t/']")
    end

    test "a message from one tab shows up in another user's tab", %{conn: conn} do
      {:ok, maya, _} = live(conn, ~p"/as/maya/c/random")
      {:ok, leo, _} = live(build_conn(), ~p"/as/leo/c/random")

      maya
      |> form("#main-form", %{"body" => "Anyone up for **ramen**?"})
      |> render_submit()

      assert render(maya) =~ "<strong>ramen</strong>"
      assert render(leo) =~ "<strong>ramen</strong>"
    end

    test "the message list is a message_scroller over the stream", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/as/maya/c/random")

      assert has_element?(view, "#message-scroller[data-component=message-scroller]")
      assert has_element?(view, "#message-scroller [data-part=scroll-button]")

      assert has_element?(
               view,
               "#message-scroller [data-part=content]#messages[phx-update=stream]"
             )

      assert has_element?(view, "#messages > [data-slot=message-scroller-item][data-message-id]")

      view |> form("#main-form", %{"body" => "scroll me"}) |> render_submit()

      assert_push_event(view, "saladui:command", %{
        command: "scroll_to_end",
        target: "message-scroller"
      })
    end

    test "the open thread scrolls in its own message_scroller", %{conn: conn} do
      {:ok, parent} = Chat.create_message("leo", "design", "Thread me")
      {:ok, view, _} = live(conn, ~p"/as/maya/c/design/t/#{parent.id}")

      assert has_element?(
               view,
               "#thread-desktop-scroller [data-part=content] > #thread-desktop-parent"
             )
    end

    test "typing shows an indicator in the other tab", %{conn: conn} do
      {:ok, maya, _} = live(conn, ~p"/as/maya/c/random")
      {:ok, leo, _} = live(build_conn(), ~p"/as/leo/c/random")

      maya |> form("#main-form", %{"body" => "Who wants"}) |> render_change()

      assert render(leo) =~ "Maya is typing…"
      refute render(maya) =~ "is typing…"
    end

    test "a mention in another channel bumps the unread badge", %{conn: conn} do
      {:ok, kai, _} = live(conn, ~p"/as/kai/c/general")
      Chat.mark_read("kai", "random", Chat.latest_id("random"))
      {:ok, _} = Chat.create_message("maya", "random", "@kai have you seen this?")

      assert render(kai) =~ ~s(aria-label="1 unread")
    end

    test "reaching the top of the scroller loads older history", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/as/kai/c/general")
      {messages, false} = Chat.list_messages("general", limit: 1_000)
      assert length(messages) > 40, "general needs more than one page of history"
      older = hd(messages)

      refute has_element?(view, "#msg-#{older.id}")
      # Scrollable-edge changes that don't reach the top are ignored.
      render_hook(view, "scroll_edges", %{"start" => true, "end" => false})
      refute has_element?(view, "#msg-#{older.id}")

      render_hook(view, "scroll_edges", %{"start" => false, "end" => true})
      assert has_element?(view, "#msg-#{older.id}")
    end

    test "slash commands are expanded", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/as/sam/c/random")

      view |> form("#main-form", %{"body" => "/"}) |> render_change()
      assert has_element?(view, "#main-commands", "/shrug")

      view |> form("#main-form", %{"body" => "/shrug fine"}) |> render_submit()
      assert render(view) =~ "fine ¯\\_(ツ)_/¯"
    end

    test "toggling a reaction updates the count", %{conn: conn} do
      {:ok, message} = Chat.create_message("leo", "random", "react please")
      {:ok, view, _} = live(conn, ~p"/as/maya/c/random")

      view
      |> element("#msg-#{message.id} button[aria-label='React with 👍']")
      |> render_click()

      assert [%{emoji: "👍", users: ["maya"]}] = Chat.get_message(message.id).reactions
      assert has_element?(view, "#msg-#{message.id} [role=group][aria-label=Reactions]", "1")

      # the toggle in the reactions row removes it again
      view
      |> element("#msg-#{message.id} button[phx-value-emoji='👍']")
      |> render_click()

      assert Chat.get_message(message.id).reactions == []
    end
  end

  describe "message context menu" do
    test "right click offers the ⋮ menu's actions", %{conn: conn} do
      {:ok, mine} = Chat.create_message("maya", "random", "mine")
      {:ok, theirs} = Chat.create_message("leo", "random", "theirs")
      {:ok, view, _} = live(conn, ~p"/as/maya/c/random")

      menu = "#msg-#{mine.id}-context"
      assert has_element?(view, "#{menu}[data-component=context-menu]")
      assert has_element?(view, "#{menu} [data-slot=context-menu-trigger]", "mine")

      for label <-
            ["React", "Reply in thread", "Copy text", "Pin to channel"] ++
              ["Remind me about this", "Mark unread", "Edit message", "Delete message"] do
        assert has_element?(view, "#{menu} [data-slot=context-menu-content]", label)
      end

      # same actions (and events) as the ⋮ menu
      assert render(element(view, "#{menu} [data-slot=context-menu-content]")) =~ "toggle_pin"

      refute has_element?(
               view,
               "#msg-#{theirs.id}-context [data-slot=context-menu-content]",
               "Edit message"
             )
    end
  end

  describe "threads" do
    test "replying in a thread updates the thread and the parent", %{conn: conn} do
      {:ok, parent} = Chat.create_message("leo", "design", "Which icon set?")
      {:ok, maya, _} = live(conn, ~p"/as/maya/c/design/t/#{parent.id}")
      {:ok, leo, _} = live(build_conn(), ~p"/as/leo/c/design")

      assert has_element?(maya, "#thread-desktop", "Which icon set?")

      maya
      |> form("#thread-desktop-composer-form", %{"body" => "Heroicons, obviously"})
      |> render_submit()

      assert has_element?(maya, "#thread-desktop", "Heroicons, obviously")
      assert has_element?(leo, "#msg-#{parent.id}", "1 reply")
    end

    test "closing the thread patches back to the channel", %{conn: conn} do
      {:ok, parent} = Chat.create_message("leo", "design", "Thread me")
      {:ok, view, _} = live(conn, ~p"/as/maya/c/design/t/#{parent.id}")

      view |> element("#thread-desktop button[aria-label='Close thread']") |> render_click()
      assert_patch(view, ~p"/as/maya/c/design")
      assert has_element?(view, "#thread-desktop", "No thread selected")
    end
  end

  describe "create channel" do
    test "validates and creates a channel", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/as/maya/c/general")

      view
      |> form("#create-channel-form", %{"channel" => %{"name" => "general"}})
      |> render_change()

      assert has_element?(view, "#create-channel-form", "a channel with that name already exists")

      # The member combobox renders the picked people as chips...
      view
      |> form("#create-channel-form", %{"channel" => %{"name" => "Offsite Planning"}})
      |> render_change(%{"channel" => %{"members" => ["leo", "kai"]}})

      assert has_element?(view, "#new-channel-members [data-slot=combobox-chip]", "Leo Brandt")
      assert has_element?(view, "#create-channel-form", "2 selected")

      # ...and submits them as channel[members][] (its JS keeps hidden inputs in sync)
      view
      |> form("#create-channel-form", %{
        "channel" => %{"name" => "Offsite Planning", "description" => "Tents!"}
      })
      |> render_submit(%{"channel" => %{"members" => ["leo"]}})

      assert_patch(view, ~p"/as/maya/c/offsite-planning")
      assert has_element?(view, "#app-sidebar", "offsite-planning")
      assert Enum.sort(Chat.get_channel("offsite-planning").members) == ~w(leo maya sprout)
    end
  end

  describe "reminders" do
    test "a date from the date picker plus a time schedules the reminder", %{conn: conn} do
      {:ok, message} = Chat.create_message("leo", "random", "remind me")
      {:ok, view, _} = live(conn, ~p"/as/maya/c/random")

      render_hook(view, "remind", %{"id" => message.id})
      picker = "#remind-date-#{message.id}"
      assert has_element?(view, "#{picker}-trigger", "Pick a date")

      today = SaladChatWeb.TimeFormat.date(DateTime.utc_now(), Chat.get_user("maya").timezone)
      tomorrow = Date.add(today, 1)

      # past days are disabled
      assert has_element?(
               view,
               "#{picker} button[phx-value-date='#{Date.add(today, -1)}'][disabled]"
             )

      view |> element("#{picker} button[phx-value-date='#{tomorrow}']") |> render_click()
      assert has_element?(view, "#{picker} input[name=date][value='#{tomorrow}']")
      assert has_element?(view, "#{picker}-trigger", Calendar.strftime(tomorrow, "%a, %b %-d"))

      view |> form("#remind-form", %{"time" => "09:30"}) |> render_submit()

      assert_push_event(view, "saladui:command", %{
        command: "add",
        params: %{title: "Reminder set", description: description}
      })

      assert description =~ "tomorrow at 9:30 AM"
    end

    test "the date is required for a custom time", %{conn: conn} do
      {:ok, message} = Chat.create_message("leo", "random", "remind me")
      {:ok, view, _} = live(conn, ~p"/as/maya/c/random")

      render_hook(view, "remind", %{"id" => message.id})
      view |> form("#remind-form") |> render_submit()

      assert_push_event(view, "saladui:command", %{
        command: "add",
        params: %{title: "Pick a time for the reminder", variant: "error"}
      })
    end
  end

  describe "jump to" do
    test "the header combobox opens a channel or a DM", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/as/maya/c/general")

      assert has_element?(view, "#jump-to[data-component=combobox]")
      assert has_element?(view, "#jump-to [data-slot=combobox-item][data-value='channel:random']")

      render_hook(view, "jump", %{"value" => "channel:random"})
      assert_patch(view, ~p"/as/maya/c/random")
      assert_push_event(view, "saladui:command", %{command: "clear", target: "jump-to"})

      render_hook(view, "jump", %{"value" => "person:leo"})
      {:ok, dm} = Chat.ensure_dm("maya", "leo")
      assert_patch(view, ~p"/as/maya/c/#{dm.id}")
    end
  end

  describe "Sprout" do
    test "answers in #ai-assistant with a trace, then streamed text", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/as/kai/c/ai-assistant")

      view
      |> form("#main-form", %{"body" => "When is the deploy freeze?"})
      |> render_submit()

      html = eventually(fn -> render(view) end, &(&1 =~ "Friday at 6pm"))

      assert html =~ "Thought for"
      assert html =~ "Searched messages"
      assert html =~ "Read 3 sources"
      assert html =~ "deploy freeze starts"
    end
  end

  describe "settings" do
    test "validates the profile form and saves it", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/as/sam/c/general")

      view
      |> form("#settings-form", %{
        "profile" => %{"name" => "", "bio" => String.duplicate("x", 161)}
      })
      |> render_change()

      assert has_element?(view, "#settings-form", "can't be blank")
      assert has_element?(view, "#settings-form", "should be at most 160 characters")

      view
      |> form("#settings-form", %{
        "profile" => %{"name" => "Samantha W.", "bio" => "Hi", "timezone" => "tokyo"}
      })
      |> render_submit()

      assert %{name: "Samantha W.", timezone: "tokyo"} = Chat.get_user("sam")
      refute has_element?(view, "#settings-form", "can't be blank")
    end
  end

  describe "@mentions" do
    test "typing @ lists people to mention; nil closes the list", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/as/kai/c/general")
      refute has_element?(view, "#main-mentions")

      render_hook(view, "mention_query", %{"composer" => "main", "query" => "ma"})
      assert has_element?(view, "#main-mention-maya[role=option]")
      refute has_element?(view, "#main-mention-kai"), "never suggests yourself"
      assert has_element?(view, "#main-input[aria-expanded=true][aria-controls=main-mentions]")

      render_hook(view, "mention_query", %{"composer" => "main", "query" => nil})
      refute has_element?(view, "#main-mentions")
    end

    test "matches any word of the name, and @here/@channel outside DMs", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/as/kai/c/general")

      render_hook(view, "mention_query", %{"composer" => "main", "query" => "okaf"})
      assert has_element?(view, "#main-mention-maya")

      render_hook(view, "mention_query", %{"composer" => "main", "query" => "h"})
      assert has_element?(view, "#main-mention-here")
    end

    test "the thread composer has its own list", %{conn: conn} do
      {:ok, parent} = Chat.create_message("leo", "general", "Thread me")
      {:ok, view, _} = live(conn, ~p"/as/kai/c/general/t/#{parent.id}")

      render_hook(view, "mention_query", %{
        "composer" => "thread-desktop-composer",
        "query" => "s"
      })

      assert has_element?(view, "#thread-desktop-composer-mention-sam")
      refute has_element?(view, "#main-mentions")
    end
  end

  defp eventually(fun, check, tries \\ 100) do
    result = fun.()

    cond do
      check.(result) -> result
      tries == 0 -> flunk("condition never became true. Last result:\n#{result}")
      true -> Process.sleep(20) && eventually(fun, check, tries - 1)
    end
  end
end
