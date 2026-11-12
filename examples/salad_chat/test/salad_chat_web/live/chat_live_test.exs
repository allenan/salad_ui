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

    test "a mention in another channel bumps the unread badge", %{conn: conn} do
      {:ok, kai, _} = live(conn, ~p"/as/kai/c/general")
      Chat.mark_read("kai", "random", Chat.latest_id("random"))
      {:ok, _} = Chat.create_message("maya", "random", "@kai have you seen this?")

      assert render(kai) =~ ~s(aria-label="1 unread")
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
      |> element("#msg-#{message.id} input[phx-value-emoji='👍']")
      |> render_click()

      assert Chat.get_message(message.id).reactions == []
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

      view
      |> form("#create-channel-form", %{
        "channel" => %{
          "name" => "Offsite Planning",
          "description" => "Tents!",
          "members" => %{"leo" => "true"}
        }
      })
      |> render_submit()

      assert_patch(view, ~p"/as/maya/c/offsite-planning")
      assert has_element?(view, "#app-sidebar", "offsite-planning")
      assert Enum.sort(Chat.get_channel("offsite-planning").members) == ~w(leo maya sprout)
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

  defp eventually(fun, check, tries \\ 100) do
    result = fun.()

    cond do
      check.(result) -> result
      tries == 0 -> flunk("condition never became true. Last result:\n#{result}")
      true -> Process.sleep(20) && eventually(fun, check, tries - 1)
    end
  end
end
