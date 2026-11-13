defmodule SaladUI.UseExceptFixture do
  @moduledoc false
  # Defines the names it leaves out of `use SaladUI`, which would otherwise
  # clash with the imports.
  use Phoenix.Component
  use SaladUI, except: [SaladUI.Sidebar, :json, message: 1]

  def sidebar(assigns), do: ~H"<nav>{@id}</nav>"
  def json(data), do: {:json, data}
  def message(assigns), do: ~H"<p>{@id}</p>"

  def imports, do: __ENV__.functions
end

defmodule SaladUI.UseOnlyFixture do
  @moduledoc false
  use SaladUI, only: [SaladUI.Button, SaladUI.Command, badge: 1]

  def imports, do: __ENV__.functions
end

defmodule SaladUI.DownstreamApiTest do
  @moduledoc """
  API gaps reported by a downstream app (Commons): extra attributes, button
  types, `as`, labels, stable hook ids, theme scales in the class merge and
  `use SaladUI` options.
  """
  use ComponentCase

  import SaladUI.AlertDialog
  import SaladUI.Attachment
  import SaladUI.Button
  import SaladUI.Command
  import SaladUI.Dialog
  import SaladUI.Drawer
  import SaladUI.Icon
  import SaladUI.RadioGroup
  import SaladUI.Sidebar
  import SaladUI.ToggleGroup
  import SaladUI.Tooltip

  # The start tag of the element with this data-slot (attribute order varies).
  defp tag(html, slot), do: ~r/<[a-z0-9]+ [^>]*data-slot="#{slot}"[^>]*>/ |> Regex.run(html) |> List.first()

  describe "command parts take global attributes" do
    test "command, list, group, empty and shortcut render rest; the list is named" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command id="cmd" aria-label="Go to" data-test="root">
          <.command_input placeholder="Search" />
          <.command_list id="cmd-list" data-test="list">
            <.command_empty data-test="empty">None</.command_empty>
            <.command_group data-test="group">
              <.command_item>
                Inbox<.command_shortcut data-test="sc">G I</.command_shortcut>
              </.command_item>
            </.command_group>
          </.command_list>
        </.command>
        """)

      assert tag(html, "command") =~ ~s(aria-label="Go to")
      assert tag(html, "command") =~ ~s(data-test="root")
      assert tag(html, "command-list") =~ ~s(aria-label="Suggestions")
      assert tag(html, "command-list") =~ ~s(id="cmd-list")
      assert tag(html, "command-empty") =~ ~s(data-test="empty")
      assert tag(html, "command-group") =~ ~s(data-test="group")
      assert tag(html, "command-shortcut") =~ ~s(data-test="sc")
      assert duplicate_attrs(html) == []
    end

    test "command_list takes a label, and an aria-label in rest replaces it" do
      assigns = %{}

      html = rendered_to_string(~H|<.command_list label="People">x</.command_list>|)
      assert html =~ ~s(aria-label="People")

      html = rendered_to_string(~H|<.command_list aria-label="Channels">x</.command_list>|)
      assert html =~ ~s(aria-label="Channels")
      assert duplicate_attrs(html) == []
    end

    test "command_group renders no heading when none is given" do
      assigns = %{}

      html = rendered_to_string(~H|<.command_group>
  <.command_item>A</.command_item>
</.command_group>|)
      refute html =~ "command-group-heading"

      html = rendered_to_string(~H|<.command_group heading="Chats">x</.command_group>|)
      assert html =~ ~r/data-slot="command-group-heading"[^>]*>\s*Chats/
    end

    test "command_item is a type=button button" do
      assigns = %{}
      html = rendered_to_string(~H|<.command_item>A</.command_item>|)
      assert html =~ ~r/<button type="button" data-slot="command-item"/
    end
  end

  describe "dialog parts take global attributes" do
    test "root, content, header, title, description and footer render rest" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="d" data-test="root">
          <.dialog_content aria-describedby="d-desc" data-test="content">
            <.dialog_header data-test="header">
              <.dialog_title id="d-title">Title</.dialog_title>
              <.dialog_description id="d-desc">Desc</.dialog_description>
            </.dialog_header>
            <.dialog_footer data-test="footer">x</.dialog_footer>
          </.dialog_content>
        </.dialog>
        """)

      assert tag(html, "dialog") =~ ~s(data-test="root")
      assert tag(html, "dialog-content") =~ ~s(aria-describedby="d-desc")
      assert tag(html, "dialog-content") =~ ~s(data-test="content")
      assert tag(html, "dialog-header") =~ ~s(data-test="header")
      assert tag(html, "dialog-title") =~ ~s(id="d-title")
      assert tag(html, "dialog-description") =~ ~s(id="d-desc")
      assert tag(html, "dialog-footer") =~ ~s(data-test="footer")
    end
  end

  describe "triggers rendered as buttons get type=button" do
    test "dialog, alert dialog and drawer triggers and closes" do
      assigns = %{}

      for html <- [
            rendered_to_string(~H|<.dialog_trigger as={&button/1}>Open</.dialog_trigger>|),
            rendered_to_string(~H|<.dialog_trigger as="button">Open</.dialog_trigger>|),
            rendered_to_string(~H|<.dialog_close as={&button/1}>Close</.dialog_close>|),
            rendered_to_string(~H|<.alert_dialog_trigger as={&button/1}>Open</.alert_dialog_trigger>|),
            rendered_to_string(~H|<.drawer_trigger as={&button/1}>Open</.drawer_trigger>|),
            rendered_to_string(~H|<.drawer_close as={&button/1}>Close</.drawer_close>|)
          ] do
        assert html =~ ~r/<button type="button"/
        assert count_substring(html, "type=") == 1
      end
    end

    test "an explicit type wins and a div trigger gets none" do
      assigns = %{}

      html = rendered_to_string(~H|<.dialog_trigger as={&button/1} type="submit">Go</.dialog_trigger>|)
      assert html =~ ~s(type="submit")
      refute html =~ ~s(type="button")

      html = rendered_to_string(~H|<.alert_dialog_trigger type="reset" as="button">Go</.alert_dialog_trigger>|)
      assert html =~ ~s(type="reset")

      html = rendered_to_string(~H|<.dialog_trigger>Go</.dialog_trigger>|)
      refute html =~ "type="
    end

    test "the trigger keeps its own data-slot under `as`, as shadcn's Slot does" do
      # shadcn's <DialogTrigger asChild><Button /></DialogTrigger> renders
      # data-slot="dialog-trigger": the Slot's props are spread over Button's.
      assigns = %{}
      html = rendered_to_string(~H|<.dialog_trigger as={&button/1}>Open</.dialog_trigger>|)
      assert html =~ ~s(data-slot="dialog-trigger")
      refute html =~ ~s(data-slot="button")
    end
  end

  describe "sidebar actions" do
    test "group and menu actions are type=button buttons by default" do
      assigns = %{}

      for html <- [
            rendered_to_string(~H|<.sidebar_group_action aria-label="Add">+</.sidebar_group_action>|),
            rendered_to_string(~H|<.sidebar_menu_action aria-label="More">…</.sidebar_menu_action>|)
          ] do
        assert html =~ ~r/^\s*<button [^>]*type="button"/
        assert duplicate_attrs(html) == []
      end
    end

    test "href, navigate or patch render a link; `as` renders anything" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.sidebar_group_action navigate="/projects/new" aria-label="New">+</.sidebar_group_action>|)

      assert tag(html, "sidebar-group-action") =~ ~r/^<a /
      assert tag(html, "sidebar-group-action") =~ ~s(href="/projects/new")
      assert tag(html, "sidebar-group-action") =~ ~s(data-phx-link="redirect")
      refute html =~ "type="

      html = rendered_to_string(~H|<.sidebar_menu_action href="/x" aria-label="Open">→</.sidebar_menu_action>|)
      assert tag(html, "sidebar-menu-action") =~ ~r/^<a [^>]*href="\/x"/

      html = rendered_to_string(~H|<.sidebar_group_action as="span">+</.sidebar_group_action>|)
      assert tag(html, "sidebar-group-action") =~ ~r/^<span /
    end

    test "sidebar_trigger takes a label" do
      assigns = %{}

      html = rendered_to_string(~H|<.sidebar_trigger />|)
      assert html =~ ~s(<span class="sr-only">Toggle Sidebar</span>)

      html = rendered_to_string(~H|<.sidebar_trigger label="Toggle navigation" />|)
      assert html =~ ~s(<span class="sr-only">Toggle navigation</span>)
    end

    test "sidebar_trigger and sidebar_rail render no attribute twice when overridden" do
      assigns = %{}

      html = rendered_to_string(~H|<.sidebar_trigger type="submit" data-sidebar="panel-trigger" />|)
      assert duplicate_attrs(html) == []
      assert html =~ ~s(type="submit")
      assert html =~ ~s(data-sidebar="panel-trigger")

      html = rendered_to_string(~H|<.sidebar_rail label="Resize navigation" />|)
      assert html =~ ~s(aria-label="Resize navigation")
      assert html =~ ~s(title="Resize navigation")

      html = rendered_to_string(~H|<.sidebar_rail aria-label="Toggle panel" title="Panel" tabindex="0" />|)
      assert duplicate_attrs(html) == []
      assert html =~ ~s(aria-label="Toggle panel")
      assert html =~ ~s(title="Panel")
      assert html =~ ~s(tabindex="0")
    end
  end

  describe "attachment root as a link" do
    test "href, navigate or patch make the whole card one link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.attachment navigate="/files/1" aria-label="Open report.pdf">
          <.attachment_content>
            <.attachment_title>report.pdf</.attachment_title>
          </.attachment_content>
        </.attachment>
        """)

      assert tag(html, "attachment") =~ ~r/^<a /
      assert tag(html, "attachment") =~ ~s(href="/files/1")
      assert tag(html, "attachment") =~ ~s(data-phx-link="redirect")
      assert html =~ "hover:bg-muted/50"
    end

    test "the default root stays a div, so the trigger overlay still works" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.attachment>
          <.attachment_trigger aria-label="Open report.pdf" />
        </.attachment>
        """)

      assert html =~ ~r/^<div data-slot="attachment"/
      assert tag(html, "attachment-trigger") =~ ~r/^<button [^>]*type="button"/
    end

    test "`as` renders another tag" do
      assigns = %{}
      html = rendered_to_string(~H|<.attachment as="li">x</.attachment>|)
      assert tag(html, "attachment") =~ ~r/^<li /
    end
  end

  describe "hooked components need a stable id" do
    test "toggle_group and radio_group raise without an id or field" do
      assigns = %{}

      assert_raise ArgumentError, ~r/toggle_group\/1 needs an `id`/, fn ->
        rendered_to_string(~H|<.toggle_group name="x" />|)
      end

      assert_raise ArgumentError, ~r/radio_group\/1 needs an `id`/, fn ->
        rendered_to_string(~H|<.radio_group name="x">x</.radio_group>|)
      end
    end

    test "the same id renders on every render" do
      assigns = %{}
      render = fn -> rendered_to_string(~H|<.tooltip id="tip">
  <.tooltip_trigger>T</.tooltip_trigger>
</.tooltip>|) end
      assert render.() == render.()
      assert render.() =~ ~s(id="tip")
    end

    test "a form field supplies the id" do
      assigns = %{form: Phoenix.Component.to_form(%{"plan" => "a"}, as: :sub)}

      html =
        rendered_to_string(~H"""
        <.radio_group field={@form[:plan]}><.radio_group_item id="a" value="a" /></.radio_group>
        """)

      assert html =~ ~s(id="sub_plan")
    end
  end

  describe "icon" do
    test "renders global attributes and takes a class list" do
      assigns = %{}

      html = rendered_to_string(~H|<.icon name="hero-star" class={["size-3", "text-star"]} aria-hidden="true" />|)

      assert html =~ ~s(aria-hidden="true")
      assert html =~ "hero-star"
      assert html =~ "size-3"
    end
  end

  describe "class merge with the app's theme scales" do
    # config/config.exs (test) adds text: panel, color: star, radius: control
    test "a custom text size no longer removes a text colour" do
      assert SaladUI.ClassMerge.merge("text-muted-foreground text-panel") == "text-muted-foreground text-panel"
      assert SaladUI.ClassMerge.merge("text-sm text-panel") == "text-panel"
    end

    test "custom colours and radii merge with their scale" do
      assert SaladUI.ClassMerge.merge("text-red-500 text-star") == "text-star"
      assert SaladUI.ClassMerge.merge("text-star text-panel") == "text-star text-panel"
      assert SaladUI.ClassMerge.merge("rounded-md rounded-control") == "rounded-control"
    end
  end

  describe "use SaladUI options" do
    test "except: leaves out modules and functions" do
      imports = Map.new(SaladUI.UseExceptFixture.imports())

      refute Map.has_key?(imports, SaladUI.Sidebar)
      assert {:button, 1} in imports[SaladUI.Button]
      refute {:message, 1} in imports[SaladUI.Message]
      assert {:message_group, 1} in imports[SaladUI.Message]
      refute {:json, 1} in imports[SaladUI.Helpers]
      refute {:classes, 1} in (imports[SaladUI.Helpers] || [])
      assert {:json, :data} == SaladUI.UseExceptFixture.json(:data)
    end

    test "only: imports just the given modules and functions" do
      imports = Map.new(SaladUI.UseOnlyFixture.imports())

      assert imports |> Map.delete(Kernel) |> Map.keys() |> Enum.sort() == [
               SaladUI.Badge,
               SaladUI.Button,
               SaladUI.Command
             ]

      assert imports[SaladUI.Badge] == [badge: 1]
      assert {:command_list, 1} in imports[SaladUI.Command]
    end

    test "unknown names raise" do
      assert_raise ArgumentError, ~r/no imported module defines/, fn ->
        Code.compile_string("defmodule SaladUI.UseBadFixture do use SaladUI, except: [no_such: 1] end")
      end

      assert_raise ArgumentError, ~r/unknown options/, fn ->
        Code.compile_string("defmodule SaladUI.UseBadFixture2 do use SaladUI, exclude: [] end")
      end
    end
  end
end
