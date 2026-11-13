defmodule Storybook.SaladUIComponents.Sidebar do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Collapsible
  alias SaladUI.Sidebar

  def function, do: &Sidebar.sidebar_provider/1

  def imports,
    do: [
      {Sidebar,
       [
         sidebar: 1,
         sidebar_content: 1,
         sidebar_footer: 1,
         sidebar_group: 1,
         sidebar_group_action: 1,
         sidebar_group_content: 1,
         sidebar_group_label: 1,
         sidebar_header: 1,
         sidebar_input: 1,
         sidebar_inset: 1,
         sidebar_menu: 1,
         sidebar_menu_action: 1,
         sidebar_menu_badge: 1,
         sidebar_menu_button: 1,
         sidebar_menu_item: 1,
         sidebar_menu_skeleton: 1,
         sidebar_menu_sub: 1,
         sidebar_menu_sub_button: 1,
         sidebar_menu_sub_item: 1,
         sidebar_rail: 1,
         sidebar_separator: 1,
         sidebar_trigger: 1,
         toggle_sidebar: 1,
         open_sidebar: 1,
         close_sidebar: 1
       ]},
      {Collapsible, [collapsible: 1, collapsible_trigger: 1, collapsible_content: 1]}
    ]

  # Each preview is boxed: the transform makes the box the containing block
  # of the sidebar's `position: fixed` parts, so they stay inside it.
  defp frame(id, provider_attrs, sidebar, inset \\ nil) do
    """
    <div class="relative h-[460px] w-full overflow-hidden rounded-lg border [transform:translateZ(0)]">
      <.sidebar_provider id="#{id}" class="h-full min-h-0" keyboard_shortcut={false} cookie={nil} #{provider_attrs}>
        #{sidebar}
        #{inset || inset()}
      </.sidebar_provider>
    </div>
    """
  end

  defp inset(title \\ "Toggle with the button, the rail or Cmd/Ctrl+B") do
    """
    <.sidebar_inset class="min-h-0">
      <header class="flex h-12 shrink-0 items-center gap-2 border-b px-4">
        <.sidebar_trigger class="-ml-1" />
        <span class="text-sm text-muted-foreground">#{title}</span>
      </header>
      <div class="flex flex-1 flex-col gap-4 p-4">
        <div class="grid auto-rows-min gap-4 md:grid-cols-3">
          <div class="aspect-video rounded-xl bg-muted/50" />
          <div class="aspect-video rounded-xl bg-muted/50" />
          <div class="aspect-video rounded-xl bg-muted/50" />
        </div>
      </div>
    </.sidebar_inset>
    """
  end

  defp app_menu do
    """
    <.sidebar_group>
      <.sidebar_group_label>Application</.sidebar_group_label>
      <.sidebar_group_content>
        <.sidebar_menu>
          <.sidebar_menu_item>
            <.sidebar_menu_button as="a" href="#" is_active tooltip="Home">
              <Lucideicons.home /> <span>Home</span>
            </.sidebar_menu_button>
          </.sidebar_menu_item>
          <.sidebar_menu_item>
            <.sidebar_menu_button as="a" href="#" tooltip="Inbox">
              <Lucideicons.inbox /> <span>Inbox</span>
            </.sidebar_menu_button>
          </.sidebar_menu_item>
          <.sidebar_menu_item>
            <.sidebar_menu_button as="a" href="#" tooltip="Calendar">
              <Lucideicons.calendar /> <span>Calendar</span>
            </.sidebar_menu_button>
          </.sidebar_menu_item>
          <.sidebar_menu_item>
            <.sidebar_menu_button as="a" href="#" tooltip="Search">
              <Lucideicons.search /> <span>Search</span>
            </.sidebar_menu_button>
          </.sidebar_menu_item>
          <.sidebar_menu_item>
            <.sidebar_menu_button as="a" href="#" tooltip="Settings">
              <Lucideicons.settings /> <span>Settings</span>
            </.sidebar_menu_button>
          </.sidebar_menu_item>
        </.sidebar_menu>
      </.sidebar_group_content>
    </.sidebar_group>
    """
  end

  defp header do
    """
    <.sidebar_header>
      <.sidebar_menu>
        <.sidebar_menu_item>
          <.sidebar_menu_button size="lg" as="a" href="#" tooltip="Acme Inc">
            <div class="flex aspect-square size-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground">
              <Lucideicons.gallery_vertical_end class="size-4" />
            </div>
            <div class="flex flex-col gap-0.5 leading-none">
              <span class="font-medium">Acme Inc</span>
              <span class="text-xs">Enterprise</span>
            </div>
          </.sidebar_menu_button>
        </.sidebar_menu_item>
      </.sidebar_menu>
    </.sidebar_header>
    """
  end

  defp footer do
    """
    <.sidebar_footer>
      <.sidebar_menu>
        <.sidebar_menu_item>
          <.sidebar_menu_button tooltip="Username">
            <Lucideicons.circle_user_round /> <span>Username</span>
          </.sidebar_menu_button>
        </.sidebar_menu_item>
      </.sidebar_menu>
    </.sidebar_footer>
    """
  end

  defp basic_sidebar(id, attrs) do
    """
    <.sidebar id="#{id}" class="h-full" #{attrs}>
      #{header()}
      <.sidebar_content>
        #{app_menu()}
      </.sidebar_content>
      #{footer()}
      <.sidebar_rail />
    </.sidebar>
    """
  end

  def variations do
    [
      %Variation{
        id: :structure,
        description: """
        `sidebar_provider` > `sidebar` (`sidebar_header`, `sidebar_content` with `sidebar_group`s,
        `sidebar_footer`, `sidebar_rail`) + `sidebar_inset` with a `sidebar_trigger`. Below 768px the
        sidebar becomes an offcanvas sheet; the trigger then opens it. Every desktop toggle writes the
        `sidebar_state` cookie (turned off in these previews with `cookie={nil}`).
        """,
        template:
          frame(
            "sidebar-structure",
            "",
            """
            <.sidebar id="sidebar-structure-sb" class="h-full">
              #{header()}
              <.sidebar_content>
                <.sidebar_group>
                  <.sidebar_input placeholder="Search the docs..." />
                </.sidebar_group>
                <.sidebar_separator />
                #{app_menu()}
              </.sidebar_content>
              #{footer()}
              <.sidebar_rail />
            </.sidebar>
            """
          )
      },
      %Variation{
        id: :collapsible_offcanvas,
        description: "`collapsible=\"offcanvas\"` (default): the sidebar slides out of view.",
        template: frame("sidebar-offcanvas", "", basic_sidebar("sidebar-offcanvas-sb", ~s(collapsible="offcanvas")))
      },
      %Variation{
        id: :collapsible_icon,
        description: """
        `collapsible="icon"`: the sidebar collapses to its icons. Menu button tooltips show only while
        collapsed, and follow client-side toggles.
        """,
        template:
          frame(
            "sidebar-icon",
            "default_open={false}",
            basic_sidebar("sidebar-icon-sb", ~s(collapsible="icon" state="collapsed"))
          )
      },
      %Variation{
        id: :collapsible_none,
        description: "`collapsible=\"none\"`: a static, non-collapsible sidebar.",
        template: """
        <div class="flex h-[460px] overflow-hidden rounded-lg border">
          <.sidebar id="sidebar-none-sb" collapsible="none">
            <.sidebar_content>
              #{app_menu()}
            </.sidebar_content>
          </.sidebar>
          <div class="flex-1 p-4 text-sm text-muted-foreground">Main content</div>
        </div>
        """
      },
      %Variation{
        id: :variant_floating,
        description: "`variant=\"floating\"`: a rounded, bordered panel with a gap around it.",
        template:
          frame(
            "sidebar-floating",
            "",
            basic_sidebar("sidebar-floating-sb", ~s(variant="floating" collapsible="icon"))
          )
      },
      %Variation{
        id: :variant_inset,
        description: "`variant=\"inset\"`: wrap the main content in `sidebar_inset`, which is inset from the sidebar.",
        template:
          frame(
            "sidebar-inset",
            "",
            basic_sidebar("sidebar-inset-sb", ~s(variant="inset" collapsible="icon"))
          )
      },
      %Variation{
        id: :side_right,
        description: "`side=\"right\"` places the sidebar (and the mobile sheet) on the right.",
        template: """
        <div class="relative h-[460px] w-full overflow-hidden rounded-lg border [transform:translateZ(0)]">
          <.sidebar_provider id="sidebar-right" class="h-full min-h-0" keyboard_shortcut={false} cookie={nil}>
            #{inset("The sidebar sits on the right")}
            #{basic_sidebar("sidebar-right-sb", ~s(side="right"))}
          </.sidebar_provider>
        </div>
        """
      },
      %Variation{
        id: :groups,
        description: """
        A `sidebar_group` has a `sidebar_group_label`, a `sidebar_group_content` and an optional
        `sidebar_group_action`.
        """,
        template:
          frame(
            "sidebar-groups",
            "",
            """
            <.sidebar id="sidebar-groups-sb" class="h-full">
              <.sidebar_content>
                #{app_menu()}
                <.sidebar_group>
                  <.sidebar_group_label>Projects</.sidebar_group_label>
                  <.sidebar_group_action title="Add Project">
                    <Lucideicons.plus /> <span class="sr-only">Add Project</span>
                  </.sidebar_group_action>
                  <.sidebar_group_content>
                    <.sidebar_menu>
                      <.sidebar_menu_item>
                        <.sidebar_menu_button as="a" href="#">
                          <Lucideicons.frame /> <span>Design Engineering</span>
                        </.sidebar_menu_button>
                      </.sidebar_menu_item>
                      <.sidebar_menu_item>
                        <.sidebar_menu_button as="a" href="#">
                          <Lucideicons.chart_pie /> <span>Sales &amp; Marketing</span>
                        </.sidebar_menu_button>
                      </.sidebar_menu_item>
                    </.sidebar_menu>
                  </.sidebar_group_content>
                </.sidebar_group>
              </.sidebar_content>
            </.sidebar>
            """
          )
      },
      %Variation{
        id: :collapsible_groups,
        description: "Wrap a `sidebar_group` in a `collapsible` to make it collapsible.",
        template:
          frame(
            "sidebar-collapsible-groups",
            "",
            """
            <.sidebar id="sidebar-collapsible-groups-sb" class="h-full">
              <.sidebar_content>
                <.collapsible :for={label <- ["Help", "Resources"]} id={"sidebar-group-" <> label} open class="group/collapsible">
                  <.sidebar_group>
                    <.sidebar_group_label>
                      <.collapsible_trigger class="flex w-full items-center">
                        {label}
                        <Lucideicons.chevron_down class="ml-auto size-4 transition-transform group-data-[state=open]/collapsible:rotate-180" />
                      </.collapsible_trigger>
                    </.sidebar_group_label>
                    <.collapsible_content>
                      <.sidebar_group_content>
                        <.sidebar_menu>
                          <.sidebar_menu_item :for={item <- ["Getting started", "Guides", "FAQ"]}>
                            <.sidebar_menu_button as="a" href="#">{item}</.sidebar_menu_button>
                          </.sidebar_menu_item>
                        </.sidebar_menu>
                      </.sidebar_group_content>
                    </.collapsible_content>
                  </.sidebar_group>
                </.collapsible>
              </.sidebar_content>
            </.sidebar>
            """
          )
      },
      %Variation{
        id: :menu,
        description: """
        `sidebar_menu_action` (`show_on_hover`), `sidebar_menu_sub` with `sidebar_menu_sub_button`s,
        `sidebar_menu_badge` and `sidebar_menu_skeleton` for loading states.
        """,
        template:
          frame(
            "sidebar-menu",
            "",
            """
            <.sidebar id="sidebar-menu-sb" class="h-full">
              <.sidebar_content>
                <.sidebar_group>
                  <.sidebar_group_label>Menu</.sidebar_group_label>
                  <.sidebar_group_content>
                    <.sidebar_menu>
                      <.sidebar_menu_item>
                        <.sidebar_menu_button as="a" href="#">
                          <Lucideicons.home /> <span>Home</span>
                        </.sidebar_menu_button>
                        <.sidebar_menu_action show_on_hover>
                          <Lucideicons.plus /> <span class="sr-only">Add Project</span>
                        </.sidebar_menu_action>
                      </.sidebar_menu_item>
                      <.sidebar_menu_item>
                        <.sidebar_menu_button as="a" href="#">
                          <Lucideicons.inbox /> <span>Inbox</span>
                        </.sidebar_menu_button>
                        <.sidebar_menu_badge>24</.sidebar_menu_badge>
                      </.sidebar_menu_item>
                      <.sidebar_menu_item>
                        <.sidebar_menu_button>
                          <Lucideicons.settings /> <span>Settings</span>
                        </.sidebar_menu_button>
                        <.sidebar_menu_sub>
                          <.sidebar_menu_sub_item>
                            <.sidebar_menu_sub_button href="#" is_active>General</.sidebar_menu_sub_button>
                          </.sidebar_menu_sub_item>
                          <.sidebar_menu_sub_item>
                            <.sidebar_menu_sub_button href="#">Team</.sidebar_menu_sub_button>
                          </.sidebar_menu_sub_item>
                          <.sidebar_menu_sub_item>
                            <.sidebar_menu_sub_button href="#" size="sm">Billing</.sidebar_menu_sub_button>
                          </.sidebar_menu_sub_item>
                        </.sidebar_menu_sub>
                      </.sidebar_menu_item>
                    </.sidebar_menu>
                  </.sidebar_group_content>
                </.sidebar_group>
                <.sidebar_group>
                  <.sidebar_group_label>Loading</.sidebar_group_label>
                  <.sidebar_menu>
                    <.sidebar_menu_item :for={_ <- 1..3}>
                      <.sidebar_menu_skeleton show_icon />
                    </.sidebar_menu_item>
                    <.sidebar_menu_item :for={_ <- 1..2}>
                      <.sidebar_menu_skeleton />
                    </.sidebar_menu_item>
                  </.sidebar_menu>
                </.sidebar_group>
              </.sidebar_content>
            </.sidebar>
            """
          )
      },
      %Variation{
        id: :rail,
        description: "`sidebar_rail` is a thin hit area on the sidebar's edge that toggles it.",
        template:
          frame(
            "sidebar-rail",
            "",
            basic_sidebar("sidebar-rail-sb", ~s(collapsible="offcanvas")),
            inset("Click the sidebar's edge")
          )
      },
      %Variation{
        id: :controlled,
        description: """
        Drive the sidebar from outside: `open_sidebar/2`, `close_sidebar/2` and `toggle_sidebar/2` build
        JS commands for the provider's id; from a LiveView use
        `SaladUI.LiveView.send_command(socket, "provider-id", "open")`. For a server-controlled sidebar
        pass `open={@open}` and `on-open-change="..."` (see the Sidebar Controlled example).
        """,
        template: """
        <div class="space-y-3">
          <div class="flex gap-2">
            <button type="button" class="rounded-md border px-3 py-1.5 text-sm" phx-click={open_sidebar("sidebar-controlled")}>Open</button>
            <button type="button" class="rounded-md border px-3 py-1.5 text-sm" phx-click={close_sidebar("sidebar-controlled")}>Close</button>
            <button type="button" class="rounded-md border px-3 py-1.5 text-sm" phx-click={toggle_sidebar("sidebar-controlled")}>Toggle</button>
          </div>
          #{frame("sidebar-controlled", "default_open={false}", basic_sidebar("sidebar-controlled-sb", ~s(collapsible="icon" state="collapsed")))}
        </div>
        """
      },
      %Variation{
        id: :mobile,
        description: """
        The mobile layout, forced with `is_mobile={true}` (normally picked by a 768px media query): the
        trigger opens an 18rem offcanvas sheet with an overlay; Escape or a click outside closes it.
        """,
        template:
          frame(
            "sidebar-mobile",
            "is_mobile={true}",
            basic_sidebar("sidebar-mobile-sb", ""),
            inset("Open the mobile sheet")
          )
      }
    ]
  end
end
