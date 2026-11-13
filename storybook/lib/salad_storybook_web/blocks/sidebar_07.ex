defmodule SaladStorybookWeb.Blocks.Sidebar07 do
  @moduledoc """
  shadcn/ui block `sidebar-07`: a sidebar that collapses to icons, with a
  team switcher, collapsible navigation, a projects list and a user menu.
  """
  use SaladStorybookWeb, :demo_view

  import SaladUI.Avatar
  import SaladUI.Breadcrumb
  import SaladUI.Collapsible
  import SaladUI.DropdownMenu
  import SaladUI.Helpers, only: [as_child: 1, dynamic: 1]
  import SaladUI.Separator
  import SaladUI.Sidebar

  @data %{
    user: %{
      name: "shadcn",
      email: "m@example.com",
      avatar: "https://github.com/shadcn.png"
    },
    teams: [
      %{name: "Acme Inc", logo: &Lucideicons.gallery_vertical_end/1, plan: "Enterprise"},
      %{name: "Acme Corp.", logo: &Lucideicons.audio_waveform/1, plan: "Startup"},
      %{name: "Evil Corp.", logo: &Lucideicons.command/1, plan: "Free"}
    ],
    nav_main: [
      %{
        title: "Playground",
        url: "#",
        icon: &Lucideicons.square_terminal/1,
        is_active: true,
        items: [
          %{title: "History", url: "#"},
          %{title: "Starred", url: "#"},
          %{title: "Settings", url: "#"}
        ]
      },
      %{
        title: "Models",
        url: "#",
        icon: &Lucideicons.bot/1,
        items: [
          %{title: "Genesis", url: "#"},
          %{title: "Explorer", url: "#"},
          %{title: "Quantum", url: "#"}
        ]
      },
      %{
        title: "Documentation",
        url: "#",
        icon: &Lucideicons.book_open/1,
        items: [
          %{title: "Introduction", url: "#"},
          %{title: "Get Started", url: "#"},
          %{title: "Tutorials", url: "#"},
          %{title: "Changelog", url: "#"}
        ]
      },
      %{
        title: "Settings",
        url: "#",
        icon: &Lucideicons.settings_2/1,
        items: [
          %{title: "General", url: "#"},
          %{title: "Team", url: "#"},
          %{title: "Billing", url: "#"},
          %{title: "Limits", url: "#"}
        ]
      }
    ],
    projects: [
      %{name: "Design Engineering", url: "#", icon: &Lucideicons.frame/1},
      %{name: "Sales & Marketing", url: "#", icon: &Lucideicons.chart_pie/1},
      %{name: "Travel", url: "#", icon: &Lucideicons.map/1}
    ]
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, data: @data, active_team: hd(@data.teams))}
  end

  @impl true
  def handle_event("select_team", %{"index" => index}, socket) do
    team = Enum.at(socket.assigns.data.teams, String.to_integer(index), socket.assigns.active_team)
    {:noreply, assign(socket, :active_team, team)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.sidebar_provider>
      <.app_sidebar data={@data} active_team={@active_team} />
      <.sidebar_inset>
        <header class="flex h-16 shrink-0 items-center gap-2 transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-12">
          <div class="flex items-center gap-2 px-4">
            <.sidebar_trigger class="-ml-1" />
            <.separator orientation="vertical" class="mr-2 h-4" />
            <.breadcrumb>
              <.breadcrumb_list>
                <.breadcrumb_item class="hidden md:block">
                  <.breadcrumb_link href="#">
                    Build Your Application
                  </.breadcrumb_link>
                </.breadcrumb_item>
                <.breadcrumb_separator class="hidden md:block" />
                <.breadcrumb_item>
                  <.breadcrumb_page>Data Fetching</.breadcrumb_page>
                </.breadcrumb_item>
              </.breadcrumb_list>
            </.breadcrumb>
          </div>
        </header>
        <div class="flex flex-1 flex-col gap-4 p-4 pt-0">
          <div class="grid auto-rows-min gap-4 md:grid-cols-3">
            <div class="aspect-video rounded-xl bg-muted/50" />
            <div class="aspect-video rounded-xl bg-muted/50" />
            <div class="aspect-video rounded-xl bg-muted/50" />
          </div>
          <div class="min-h-[100vh] flex-1 rounded-xl bg-muted/50 md:min-h-min" />
        </div>
      </.sidebar_inset>
    </.sidebar_provider>
    """
  end

  attr :data, :map, required: true
  attr :active_team, :map, required: true

  def app_sidebar(assigns) do
    ~H"""
    <.sidebar id="app-sidebar" collapsible="icon">
      <.sidebar_header>
        <.team_switcher teams={@data.teams} active_team={@active_team} />
      </.sidebar_header>
      <.sidebar_content>
        <.nav_main items={@data.nav_main} />
        <.nav_projects projects={@data.projects} />
      </.sidebar_content>
      <.sidebar_footer>
        <.nav_user user={@data.user} />
      </.sidebar_footer>
      <.sidebar_rail />
    </.sidebar>
    """
  end

  attr :teams, :list, required: true
  attr :active_team, :map, required: true

  def team_switcher(assigns) do
    ~H"""
    <.sidebar_menu>
      <.sidebar_menu_item>
        <.dropdown_menu id="team-switcher" class="block">
          <.as_child
            tag={&dropdown_menu_trigger/1}
            child={&sidebar_menu_button/1}
            size="lg"
            class="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
          >
            <div class="flex aspect-square size-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground">
              <.dynamic tag={@active_team.logo} class="size-4" />
            </div>
            <div class="grid flex-1 text-left text-sm leading-tight">
              <span class="truncate font-medium">{@active_team.name}</span>
              <span class="truncate text-xs">{@active_team.plan}</span>
            </div>
            <Lucideicons.chevrons_up_down class="ml-auto" />
          </.as_child>
          <.dropdown_menu_content
            class="w-(--radix-dropdown-menu-trigger-width) min-w-56 rounded-lg"
            align="start"
            side="right"
            side-offset={4}
          >
            <.dropdown_menu_label class="text-xs text-muted-foreground">
              Teams
            </.dropdown_menu_label>
            <.dropdown_menu_item
              :for={{team, index} <- Enum.with_index(@teams)}
              class="gap-2 p-2"
              phx-click="select_team"
              phx-value-index={index}
            >
              <div class="flex size-6 items-center justify-center rounded-md border">
                <.dynamic tag={team.logo} class="size-3.5 shrink-0" />
              </div>
              {team.name}
              <.dropdown_menu_shortcut>⌘{index + 1}</.dropdown_menu_shortcut>
            </.dropdown_menu_item>
            <.dropdown_menu_separator />
            <.dropdown_menu_item class="gap-2 p-2">
              <div class="flex size-6 items-center justify-center rounded-md border bg-transparent">
                <Lucideicons.plus class="size-4" />
              </div>
              <div class="font-medium text-muted-foreground">Add team</div>
            </.dropdown_menu_item>
          </.dropdown_menu_content>
        </.dropdown_menu>
      </.sidebar_menu_item>
    </.sidebar_menu>
    """
  end

  attr :items, :list, required: true

  def nav_main(assigns) do
    ~H"""
    <.sidebar_group>
      <.sidebar_group_label>Platform</.sidebar_group_label>
      <.sidebar_menu>
        <.sidebar_menu_item :for={item <- @items}>
          <.collapsible
            id={"nav-main-" <> slug(item.title)}
            open={item[:is_active] || false}
            class="group/collapsible"
          >
            <.as_child
              tag={&collapsible_trigger/1}
              child={&sidebar_menu_button/1}
              tooltip={item.title}
            >
              <.dynamic :if={item[:icon]} tag={item.icon} />
              <span>{item.title}</span>
              <Lucideicons.chevron_right class="ml-auto transition-transform duration-200 group-data-[state=open]/collapsible:rotate-90" />
            </.as_child>
            <.collapsible_content>
              <.sidebar_menu_sub>
                <.sidebar_menu_sub_item :for={sub_item <- item.items}>
                  <.as_child tag={&sidebar_menu_sub_button/1} child="a" href={sub_item.url}>
                    <span>{sub_item.title}</span>
                  </.as_child>
                </.sidebar_menu_sub_item>
              </.sidebar_menu_sub>
            </.collapsible_content>
          </.collapsible>
        </.sidebar_menu_item>
      </.sidebar_menu>
    </.sidebar_group>
    """
  end

  attr :projects, :list, required: true

  def nav_projects(assigns) do
    ~H"""
    <.sidebar_group class="group-data-[collapsible=icon]:hidden">
      <.sidebar_group_label>Projects</.sidebar_group_label>
      <.sidebar_menu>
        <.sidebar_menu_item :for={item <- @projects}>
          <.as_child tag={&sidebar_menu_button/1} child="a" href={item.url}>
            <.dynamic tag={item.icon} />
            <span>{item.name}</span>
          </.as_child>
          <.dropdown_menu id={"project-" <> slug(item.name)} class="contents">
            <.as_child tag={&dropdown_menu_trigger/1} child={&sidebar_menu_action/1} show_on_hover>
              <Lucideicons.ellipsis />
              <span class="sr-only">More</span>
            </.as_child>
            <.dropdown_menu_content class="w-48 rounded-lg" side="right" align="start">
              <.dropdown_menu_item>
                <Lucideicons.folder class="text-muted-foreground" />
                <span>View Project</span>
              </.dropdown_menu_item>
              <.dropdown_menu_item>
                <Lucideicons.forward class="text-muted-foreground" />
                <span>Share Project</span>
              </.dropdown_menu_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_item>
                <Lucideicons.trash_2 class="text-muted-foreground" />
                <span>Delete Project</span>
              </.dropdown_menu_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </.sidebar_menu_item>
        <.sidebar_menu_item>
          <.sidebar_menu_button class="text-sidebar-foreground/70">
            <Lucideicons.ellipsis class="text-sidebar-foreground/70" />
            <span>More</span>
          </.sidebar_menu_button>
        </.sidebar_menu_item>
      </.sidebar_menu>
    </.sidebar_group>
    """
  end

  attr :user, :map, required: true

  def nav_user(assigns) do
    ~H"""
    <.sidebar_menu>
      <.sidebar_menu_item>
        <.dropdown_menu id="nav-user" class="block">
          <.as_child
            tag={&dropdown_menu_trigger/1}
            child={&sidebar_menu_button/1}
            size="lg"
            class="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
          >
            <.avatar class="h-8 w-8 rounded-lg">
              <.avatar_image src={@user.avatar} alt={@user.name} />
              <.avatar_fallback class="rounded-lg">CN</.avatar_fallback>
            </.avatar>
            <div class="grid flex-1 text-left text-sm leading-tight">
              <span class="truncate font-medium">{@user.name}</span>
              <span class="truncate text-xs">{@user.email}</span>
            </div>
            <Lucideicons.chevrons_up_down class="ml-auto size-4" />
          </.as_child>
          <.dropdown_menu_content
            class="w-(--radix-dropdown-menu-trigger-width) min-w-56 rounded-lg"
            side="right"
            align="end"
            side-offset={4}
          >
            <.dropdown_menu_label class="p-0 font-normal">
              <div class="flex items-center gap-2 px-1 py-1.5 text-left text-sm">
                <.avatar class="h-8 w-8 rounded-lg">
                  <.avatar_image src={@user.avatar} alt={@user.name} />
                  <.avatar_fallback class="rounded-lg">CN</.avatar_fallback>
                </.avatar>
                <div class="grid flex-1 text-left text-sm leading-tight">
                  <span class="truncate font-medium">{@user.name}</span>
                  <span class="truncate text-xs">{@user.email}</span>
                </div>
              </div>
            </.dropdown_menu_label>
            <.dropdown_menu_separator />
            <.dropdown_menu_group>
              <.dropdown_menu_item>
                <Lucideicons.sparkles /> Upgrade to Pro
              </.dropdown_menu_item>
            </.dropdown_menu_group>
            <.dropdown_menu_separator />
            <.dropdown_menu_group>
              <.dropdown_menu_item>
                <Lucideicons.badge_check /> Account
              </.dropdown_menu_item>
              <.dropdown_menu_item>
                <Lucideicons.credit_card /> Billing
              </.dropdown_menu_item>
              <.dropdown_menu_item>
                <Lucideicons.bell /> Notifications
              </.dropdown_menu_item>
            </.dropdown_menu_group>
            <.dropdown_menu_separator />
            <.dropdown_menu_item>
              <Lucideicons.log_out /> Log out
            </.dropdown_menu_item>
          </.dropdown_menu_content>
        </.dropdown_menu>
      </.sidebar_menu_item>
    </.sidebar_menu>
    """
  end

  defp slug(text), do: text |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")
end
