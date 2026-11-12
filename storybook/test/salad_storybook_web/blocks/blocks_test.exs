defmodule SaladStorybookWeb.BlocksTest do
  use SaladStorybookWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SaladStorybookWeb.Blocks

  describe "registry" do
    test "every block has a route and its source" do
      for %{slug: slug, file: file} <- Blocks.blocks() do
        assert Blocks.source(slug) =~ "defmodule SaladStorybookWeb.Blocks."
        assert File.exists?(Path.join([__DIR__, "../../../lib/salad_storybook_web/blocks", file]))
      end
    end

    test "preview renders the iframe and a copyable source" do
      html = render_component(&Blocks.preview/1, slug: "login-03")

      assert html =~ ~s(src="/blocks/login-03")
      assert html =~ ~s(data-slot="code-block")
      assert html =~ "login_03.ex"
    end

    test "unknown blocks raise" do
      assert_raise ArgumentError, fn -> Blocks.block!("nope") end
    end
  end

  describe "login-03 and signup-03" do
    test "login renders the card and social buttons", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/blocks/login-03")

      assert html =~ "Welcome back"
      assert html =~ "Login with Apple"
      assert html =~ "Login with Google"
      assert html =~ "Or continue with"
      assert html =~ ~s(id="password")
    end

    test "signup renders the form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/blocks/signup-03")

      assert html =~ "Create your account"
      assert html =~ ~s(id="confirm-password")
      assert html =~ "Must be at least 8 characters long."
    end
  end

  describe "sidebar-07" do
    test "renders an icon-collapsible sidebar and switches teams", %{conn: conn} do
      {:ok, view, html} = live(conn, "/blocks/sidebar-07")

      assert html =~ ~s(id="app-sidebar")
      assert html =~ "Playground"
      assert html =~ "Design Engineering"
      assert view |> element("#app-sidebar") |> render() =~ ~s(data-collapsible="none")

      assert view |> element("#team-switcher [data-part=trigger]") |> render() =~ "Enterprise"
      view |> element("#team-switcher [phx-value-index='2']") |> render_click()
      assert view |> element("#team-switcher [data-part=trigger]") |> render() =~ "Evil Corp."
    end
  end

  describe "chat-01" do
    test "sends the scripted prompt, thinks, then streams the reply", %{conn: conn} do
      {:ok, view, html} = live(conn, "/blocks/chat-01")
      assert html =~ "Write me a haiku"

      html = view |> form("#chat-form", prompt: "Write me a haiku") |> render_submit()
      assert html =~ "Thinking..."
      assert html =~ ~s(aria-busy="true")

      send(view.pid, {:reply, 0})
      html = render(view)
      refute html =~ "Thinking..."
      assert html =~ "Stop"

      html = drain(view)
      assert html =~ "margin: 0 auto"
      assert html =~ "Is this conversation actually happening?"
      refute html =~ ~s(aria-busy="true")
    end

    test "stop ends the reply early and new chat clears it", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/blocks/chat-01")

      view |> form("#chat-form", prompt: "Hello") |> render_submit()
      send(view.pid, {:reply, 0})
      render(view)
      view |> element("button[phx-click=stop]") |> render_click()
      refute render(view) =~ ~s(phx-click="stop")

      view |> element("button[phx-click=new_chat]") |> render_click()
      refute render(view) =~ "Hello"
    end

    test "ignores blank prompts", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/blocks/chat-01")
      refute view |> form("#chat-form", prompt: "   ") |> render_submit() =~ "Thinking..."
    end

    defp drain(view, n \\ 200) do
      html = render(view)

      if n > 0 and html =~ ~s(phx-click="stop") do
        send(view.pid, {:chunk, 0})
        drain(view, n - 1)
      else
        html
      end
    end
  end

  describe "dashboard-01" do
    test "renders cards, chart and the first page of the table", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/blocks/dashboard-01")

      assert html =~ "Total Revenue"
      assert html =~ "Total Visitors"
      assert html =~ ~s(id="visitors-chart")
      assert html =~ ~s(id="row-1")
      assert html =~ ~s(id="row-10")
      refute html =~ ~s(id="row-11")
      assert html =~ "Page 1 of 7"
      assert html =~ "0 of 68 row(s) selected."
    end

    test "paginates and changes the page size", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/blocks/dashboard-01")

      html = view |> element("button[phx-value-page='1']", "Go to next page") |> render_click()
      assert html =~ "Page 2 of 7"
      assert html =~ ~s(id="row-11")

      html = render_hook(view, "set_page_size", %{"value" => "50"})
      assert html =~ "Page 1 of 2"
      assert html =~ ~s(id="row-50")
    end

    test "selects rows and the whole page", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/blocks/dashboard-01")

      html = view |> element("#select-row-3") |> render_click()
      assert html =~ "1 of 68 row(s) selected."

      html = view |> element("#select-page") |> render_click()
      assert html =~ "10 of 68 row(s) selected."

      html = view |> element("#select-page") |> render_click()
      assert html =~ "0 of 68 row(s) selected."
    end

    test "hides and shows columns", %{conn: conn} do
      {:ok, view, html} = live(conn, "/blocks/dashboard-01")
      assert html =~ "Section Type"

      html = render_hook(view, "toggle_column", %{"value" => "type", "checked" => false})
      refute html =~ "Section Type"

      html = render_hook(view, "toggle_column", %{"value" => "type", "checked" => true})
      assert html =~ "Section Type"
    end

    test "filters the chart by time range", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/blocks/dashboard-01")

      html = view |> element("#visitors-chart") |> render()
      assert html =~ "Apr 1"

      render_hook(view, "set_time_range", %{"value" => "7d"})
      html = view |> element("#visitors-chart") |> render()
      refute html =~ "Apr 1"
      assert html =~ "Jun 30"
    end

    test "opens a row in the drawer and saves inline edits", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/blocks/dashboard-01")

      view |> element("#row-5 button[phx-click=view_row]") |> render_click()
      assert view |> element("#row-viewer") |> render() =~ "Design"

      view
      |> form("#5-target-form", %{"value" => "42"})
      |> render_submit()

      assert view |> element("#5-target") |> render() =~ ~s(value="42")

      # One toast morphs from loading to success, like shadcn's toast.promise.
      assert_push_event(view, "saladui:command", %{
        command: "add",
        params: %{id: "save-5-target", variant: "loading", title: "Saving Design"}
      })

      render_async(view, 3000)

      assert_push_event(view, "saladui:command", %{
        command: "update",
        params: %{id: "save-5-target", variant: "success", title: "Done"}
      })
    end

    test "switches views from the select", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/blocks/dashboard-01")

      render_hook(view, "set_view", %{"value" => "key-personnel"})
      assert view |> element("#data-table-tabs") |> render() =~ "&quot;value&quot;:&quot;key-personnel&quot;"
    end
  end
end
