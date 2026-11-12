defmodule SaladStorybookWeb.Blocks.Dashboard01 do
  @moduledoc """
  shadcn/ui block `dashboard-01`: a dashboard with an inset sidebar, a site
  header, KPI cards, an interactive area chart and a data table.

  The table keeps its state (row selection, visible columns, page, page size,
  the current view and the row open in the drawer) on the server. The chart's
  time range is a server assign that re-filters the data; the chart animates
  in place when it changes.
  """
  use SaladStorybookWeb, :demo_view

  import SaladUI.Avatar
  import SaladUI.Badge
  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Chart
  import SaladUI.Checkbox
  import SaladUI.Drawer
  import SaladUI.DropdownMenu
  import SaladUI.Helpers, only: [as_child: 1, dynamic: 1]
  import SaladUI.Input
  import SaladUI.Label
  import SaladUI.Select
  import SaladUI.Separator
  import SaladUI.Sidebar
  import SaladUI.Table
  import SaladUI.Tabs
  import SaladUI.Toast
  import SaladUI.ToggleGroup

  alias SaladUI.LiveView

  @user %{name: "shadcn", email: "m@example.com", avatar: "https://github.com/shadcn.png"}

  @nav_main [
    %{title: "Dashboard", url: "#", icon: &Lucideicons.layout_dashboard/1},
    %{title: "Lifecycle", url: "#", icon: &Lucideicons.list_todo/1},
    %{title: "Analytics", url: "#", icon: &Lucideicons.chart_no_axes_column/1},
    %{title: "Projects", url: "#", icon: &Lucideicons.folder/1},
    %{title: "Team", url: "#", icon: &Lucideicons.users/1}
  ]

  @nav_secondary [
    %{title: "Settings", url: "#", icon: &Lucideicons.settings/1},
    %{title: "Get Help", url: "#", icon: &Lucideicons.circle_help/1},
    %{title: "Search", url: "#", icon: &Lucideicons.search/1}
  ]

  @documents [
    %{name: "Data Library", url: "#", icon: &Lucideicons.database/1},
    %{name: "Reports", url: "#", icon: &Lucideicons.file_chart_column/1},
    %{name: "Word Assistant", url: "#", icon: &Lucideicons.file_pen_line/1}
  ]

  @section_cards [
    %{
      description: "Total Revenue",
      value: "$1,250.00",
      trend: :up,
      change: "+12.5%",
      summary: "Trending up this month",
      detail: "Visitors for the last 6 months"
    },
    %{
      description: "New Customers",
      value: "1,234",
      trend: :down,
      change: "-20%",
      summary: "Down 20% this period",
      detail: "Acquisition needs attention"
    },
    %{
      description: "Active Accounts",
      value: "45,678",
      trend: :up,
      change: "+12.5%",
      summary: "Strong user retention",
      detail: "Engagement exceed targets"
    },
    %{
      description: "Growth Rate",
      value: "4.5%",
      trend: :up,
      change: "+4.5%",
      summary: "Steady performance increase",
      detail: "Meets growth projections"
    }
  ]

  # {date, desktop, mobile}
  @visitors [
    {"2024-04-01", 222, 150},
    {"2024-04-02", 97, 180},
    {"2024-04-03", 167, 120},
    {"2024-04-04", 242, 260},
    {"2024-04-05", 373, 290},
    {"2024-04-06", 301, 340},
    {"2024-04-07", 245, 180},
    {"2024-04-08", 409, 320},
    {"2024-04-09", 59, 110},
    {"2024-04-10", 261, 190},
    {"2024-04-11", 327, 350},
    {"2024-04-12", 292, 210},
    {"2024-04-13", 342, 380},
    {"2024-04-14", 137, 220},
    {"2024-04-15", 120, 170},
    {"2024-04-16", 138, 190},
    {"2024-04-17", 446, 360},
    {"2024-04-18", 364, 410},
    {"2024-04-19", 243, 180},
    {"2024-04-20", 89, 150},
    {"2024-04-21", 137, 200},
    {"2024-04-22", 224, 170},
    {"2024-04-23", 138, 230},
    {"2024-04-24", 387, 290},
    {"2024-04-25", 215, 250},
    {"2024-04-26", 75, 130},
    {"2024-04-27", 383, 420},
    {"2024-04-28", 122, 180},
    {"2024-04-29", 315, 240},
    {"2024-04-30", 454, 380},
    {"2024-05-01", 165, 220},
    {"2024-05-02", 293, 310},
    {"2024-05-03", 247, 190},
    {"2024-05-04", 385, 420},
    {"2024-05-05", 481, 390},
    {"2024-05-06", 498, 520},
    {"2024-05-07", 388, 300},
    {"2024-05-08", 149, 210},
    {"2024-05-09", 227, 180},
    {"2024-05-10", 293, 330},
    {"2024-05-11", 335, 270},
    {"2024-05-12", 197, 240},
    {"2024-05-13", 197, 160},
    {"2024-05-14", 448, 490},
    {"2024-05-15", 473, 380},
    {"2024-05-16", 338, 400},
    {"2024-05-17", 499, 420},
    {"2024-05-18", 315, 350},
    {"2024-05-19", 235, 180},
    {"2024-05-20", 177, 230},
    {"2024-05-21", 82, 140},
    {"2024-05-22", 81, 120},
    {"2024-05-23", 252, 290},
    {"2024-05-24", 294, 220},
    {"2024-05-25", 201, 250},
    {"2024-05-26", 213, 170},
    {"2024-05-27", 420, 460},
    {"2024-05-28", 233, 190},
    {"2024-05-29", 78, 130},
    {"2024-05-30", 340, 280},
    {"2024-05-31", 178, 230},
    {"2024-06-01", 178, 200},
    {"2024-06-02", 470, 410},
    {"2024-06-03", 103, 160},
    {"2024-06-04", 439, 380},
    {"2024-06-05", 88, 140},
    {"2024-06-06", 294, 250},
    {"2024-06-07", 323, 370},
    {"2024-06-08", 385, 320},
    {"2024-06-09", 438, 480},
    {"2024-06-10", 155, 200},
    {"2024-06-11", 92, 150},
    {"2024-06-12", 492, 420},
    {"2024-06-13", 81, 130},
    {"2024-06-14", 426, 380},
    {"2024-06-15", 307, 350},
    {"2024-06-16", 371, 310},
    {"2024-06-17", 475, 520},
    {"2024-06-18", 107, 170},
    {"2024-06-19", 341, 290},
    {"2024-06-20", 408, 450},
    {"2024-06-21", 169, 210},
    {"2024-06-22", 317, 270},
    {"2024-06-23", 480, 530},
    {"2024-06-24", 132, 180},
    {"2024-06-25", 141, 190},
    {"2024-06-26", 434, 380},
    {"2024-06-27", 448, 490},
    {"2024-06-28", 149, 200},
    {"2024-06-29", 103, 160},
    {"2024-06-30", 446, 400}
  ]

  @visitors_config %{
    visitors: %{label: "Visitors"},
    desktop: %{label: "Desktop", color: "var(--primary)"},
    mobile: %{label: "Mobile", color: "var(--primary)"}
  }

  @time_ranges [{"90d", "Last 3 months", 90}, {"30d", "Last 30 days", 30}, {"7d", "Last 7 days", 7}]

  @drawer_chart [
    %{month: "January", desktop: 186, mobile: 80},
    %{month: "February", desktop: 305, mobile: 200},
    %{month: "March", desktop: 237, mobile: 120},
    %{month: "April", desktop: 73, mobile: 190},
    %{month: "May", desktop: 209, mobile: 130},
    %{month: "June", desktop: 214, mobile: 140}
  ]

  @drawer_chart_config %{
    desktop: %{label: "Desktop", color: "var(--primary)"},
    mobile: %{label: "Mobile", color: "var(--primary)"}
  }

  # {id, header, type, status, target, limit, reviewer}
  @rows [
    {1, "Cover page", "Cover page", "In Process", "18", "5", "Eddie Lake"},
    {2, "Table of contents", "Table of contents", "Done", "29", "24", "Eddie Lake"},
    {3, "Executive summary", "Narrative", "Done", "10", "13", "Eddie Lake"},
    {4, "Technical approach", "Narrative", "Done", "27", "23", "Jamik Tashpulatov"},
    {5, "Design", "Narrative", "In Process", "2", "16", "Jamik Tashpulatov"},
    {6, "Capabilities", "Narrative", "In Process", "20", "8", "Jamik Tashpulatov"},
    {7, "Integration with existing systems", "Narrative", "In Process", "19", "21", "Jamik Tashpulatov"},
    {8, "Innovation and Advantages", "Narrative", "Done", "25", "26", "Assign reviewer"},
    {9, "Overview of EMR's Innovative Solutions", "Technical content", "Done", "7", "23", "Assign reviewer"},
    {10, "Advanced Algorithms and Machine Learning", "Narrative", "Done", "30", "28", "Assign reviewer"},
    {11, "Adaptive Communication Protocols", "Narrative", "Done", "9", "31", "Assign reviewer"},
    {12, "Advantages Over Current Technologies", "Narrative", "Done", "12", "0", "Assign reviewer"},
    {13, "Past Performance", "Narrative", "Done", "22", "33", "Assign reviewer"},
    {14, "Customer Feedback and Satisfaction Levels", "Narrative", "Done", "15", "34", "Assign reviewer"},
    {15, "Implementation Challenges and Solutions", "Narrative", "Done", "3", "35", "Assign reviewer"},
    {16, "Security Measures and Data Protection Policies", "Narrative", "In Process", "6", "36", "Assign reviewer"},
    {17, "Scalability and Future Proofing", "Narrative", "Done", "4", "37", "Assign reviewer"},
    {18, "Cost-Benefit Analysis", "Plain language", "Done", "14", "38", "Assign reviewer"},
    {19, "User Training and Onboarding Experience", "Narrative", "Done", "17", "39", "Assign reviewer"},
    {20, "Future Development Roadmap", "Narrative", "Done", "11", "40", "Assign reviewer"},
    {21, "System Architecture Overview", "Technical content", "In Process", "24", "18", "Maya Johnson"},
    {22, "Risk Management Plan", "Narrative", "Done", "15", "22", "Carlos Rodriguez"},
    {23, "Compliance Documentation", "Legal", "In Process", "31", "27", "Sarah Chen"},
    {24, "API Documentation", "Technical content", "Done", "8", "12", "Raj Patel"},
    {25, "User Interface Mockups", "Visual", "In Process", "19", "25", "Leila Ahmadi"},
    {26, "Database Schema", "Technical content", "Done", "22", "20", "Thomas Wilson"},
    {27, "Testing Methodology", "Technical content", "In Process", "17", "14", "Assign reviewer"},
    {28, "Deployment Strategy", "Narrative", "Done", "26", "30", "Eddie Lake"},
    {29, "Budget Breakdown", "Financial", "In Process", "13", "16", "Jamik Tashpulatov"},
    {30, "Market Analysis", "Research", "Done", "29", "32", "Sophia Martinez"},
    {31, "Competitor Comparison", "Research", "In Process", "21", "19", "Assign reviewer"},
    {32, "Maintenance Plan", "Technical content", "Done", "16", "23", "Alex Thompson"},
    {33, "User Personas", "Research", "In Process", "27", "24", "Nina Patel"},
    {34, "Accessibility Compliance", "Legal", "Done", "18", "21", "Assign reviewer"},
    {35, "Performance Metrics", "Technical content", "In Process", "23", "26", "David Kim"},
    {36, "Disaster Recovery Plan", "Technical content", "Done", "14", "17", "Jamik Tashpulatov"},
    {37, "Third-party Integrations", "Technical content", "In Process", "25", "28", "Eddie Lake"},
    {38, "User Feedback Summary", "Research", "Done", "20", "15", "Assign reviewer"},
    {39, "Localization Strategy", "Narrative", "In Process", "12", "19", "Maria Garcia"},
    {40, "Mobile Compatibility", "Technical content", "Done", "28", "31", "James Wilson"},
    {41, "Data Migration Plan", "Technical content", "In Process", "19", "22", "Assign reviewer"},
    {42, "Quality Assurance Protocols", "Technical content", "Done", "30", "33", "Priya Singh"},
    {43, "Stakeholder Analysis", "Research", "In Process", "11", "14", "Eddie Lake"},
    {44, "Environmental Impact Assessment", "Research", "Done", "24", "27", "Assign reviewer"},
    {45, "Intellectual Property Rights", "Legal", "In Process", "17", "20", "Sarah Johnson"},
    {46, "Customer Support Framework", "Narrative", "Done", "22", "25", "Jamik Tashpulatov"},
    {47, "Version Control Strategy", "Technical content", "In Process", "15", "18", "Assign reviewer"},
    {48, "Continuous Integration Pipeline", "Technical content", "Done", "26", "29", "Michael Chen"},
    {49, "Regulatory Compliance", "Legal", "In Process", "13", "16", "Assign reviewer"},
    {50, "User Authentication System", "Technical content", "Done", "28", "31", "Eddie Lake"},
    {51, "Data Analytics Framework", "Technical content", "In Process", "21", "24", "Jamik Tashpulatov"},
    {52, "Cloud Infrastructure", "Technical content", "Done", "16", "19", "Assign reviewer"},
    {53, "Network Security Measures", "Technical content", "In Process", "29", "32", "Lisa Wong"},
    {54, "Project Timeline", "Planning", "Done", "14", "17", "Eddie Lake"},
    {55, "Resource Allocation", "Planning", "In Process", "27", "30", "Assign reviewer"},
    {56, "Team Structure and Roles", "Planning", "Done", "20", "23", "Jamik Tashpulatov"},
    {57, "Communication Protocols", "Planning", "In Process", "15", "18", "Assign reviewer"},
    {58, "Success Metrics", "Planning", "Done", "30", "33", "Eddie Lake"},
    {59, "Internationalization Support", "Technical content", "In Process", "23", "26", "Jamik Tashpulatov"},
    {60, "Backup and Recovery Procedures", "Technical content", "Done", "18", "21", "Assign reviewer"},
    {61, "Monitoring and Alerting System", "Technical content", "In Process", "25", "28", "Daniel Park"},
    {62, "Code Review Guidelines", "Technical content", "Done", "12", "15", "Eddie Lake"},
    {63, "Documentation Standards", "Technical content", "In Process", "27", "30", "Jamik Tashpulatov"},
    {64, "Release Management Process", "Planning", "Done", "22", "25", "Assign reviewer"},
    {65, "Feature Prioritization Matrix", "Planning", "In Process", "19", "22", "Emma Davis"},
    {66, "Technical Debt Assessment", "Technical content", "Done", "24", "27", "Eddie Lake"},
    {67, "Capacity Planning", "Planning", "In Process", "21", "24", "Jamik Tashpulatov"},
    {68, "Service Level Agreements", "Legal", "Done", "26", "29", "Assign reviewer"}
  ]

  # Columns the "Customize Columns" menu can hide.
  @hideable_columns ~w(type status target limit reviewer)

  @views [
    {"outline", "Outline", nil},
    {"past-performance", "Past Performance", 3},
    {"key-personnel", "Key Personnel", 2},
    {"focus-documents", "Focus Documents", nil}
  ]

  @impl true
  def mount(_params, _session, socket) do
    rows =
      Enum.map(@rows, fn {id, header, type, status, target, limit, reviewer} ->
        %{id: id, header: header, type: type, status: status, target: target, limit: limit, reviewer: reviewer}
      end)

    {:ok,
     socket
     |> assign(
       rows: rows,
       selected: MapSet.new(),
       hidden_columns: MapSet.new(),
       page_index: 0,
       page_size: 10,
       view: "outline",
       viewing: hd(rows)
     )
     |> assign_time_range("90d")}
  end

  defp assign_time_range(socket, range) do
    {_, _, days} = List.keyfind(@time_ranges, range, 0, hd(@time_ranges))
    start = Date.add(~D[2024-06-30], -days)

    data =
      for {date, desktop, mobile} <- @visitors, Date.compare(Date.from_iso8601!(date), start) != :lt do
        %{date: short_date(date), desktop: desktop, mobile: mobile}
      end

    assign(socket, time_range: range, chart_data: data)
  end

  defp short_date(iso) do
    date = Date.from_iso8601!(iso)
    Calendar.strftime(date, "%b ") <> Integer.to_string(date.day)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.sidebar_provider style={
      %{
        "--sidebar-width": "calc(var(--spacing) * 72)",
        "--header-height": "calc(var(--spacing) * 12)"
      }
    }>
      <.app_sidebar />
      <.sidebar_inset>
        <.site_header />
        <div class="flex flex-1 flex-col">
          <div class="@container/main flex flex-1 flex-col gap-2">
            <div class="flex flex-col gap-4 py-4 md:gap-6 md:py-6">
              <.section_cards />
              <div class="px-4 lg:px-6">
                <.chart_area_interactive time_range={@time_range} data={@chart_data} />
              </div>
              <.data_table
                rows={@rows}
                selected={@selected}
                hidden_columns={@hidden_columns}
                page_index={@page_index}
                page_size={@page_size}
                view={@view}
              />
            </div>
          </div>
        </div>
      </.sidebar_inset>
    </.sidebar_provider>
    <.table_cell_viewer item={@viewing} />
    <.toaster id="toaster" position="bottom-right" />
    """
  end

  # Sidebar

  def app_sidebar(assigns) do
    assigns = assign(assigns, nav_main: @nav_main, documents: @documents, nav_secondary: @nav_secondary, user: @user)

    ~H"""
    <.sidebar id="app-sidebar" collapsible="offcanvas" variant="inset">
      <.sidebar_header>
        <.sidebar_menu>
          <.sidebar_menu_item>
            <.as_child
              tag={&sidebar_menu_button/1}
              child="a"
              href="#"
              class="data-[slot=sidebar-menu-button]:p-1.5!"
            >
              <Lucideicons.aperture class="size-5!" />
              <span class="text-base font-semibold">Acme Inc.</span>
            </.as_child>
          </.sidebar_menu_item>
        </.sidebar_menu>
      </.sidebar_header>
      <.sidebar_content>
        <.nav_main items={@nav_main} />
        <.nav_documents items={@documents} />
        <.nav_secondary items={@nav_secondary} class="mt-auto" />
      </.sidebar_content>
      <.sidebar_footer>
        <.nav_user user={@user} />
      </.sidebar_footer>
    </.sidebar>
    """
  end

  attr :items, :list, required: true

  def nav_main(assigns) do
    ~H"""
    <.sidebar_group>
      <.sidebar_group_content class="flex flex-col gap-2">
        <.sidebar_menu>
          <.sidebar_menu_item class="flex items-center gap-2">
            <.sidebar_menu_button
              tooltip="Quick Create"
              class="min-w-8 bg-primary text-primary-foreground duration-200 ease-linear hover:bg-primary/90 hover:text-primary-foreground active:bg-primary/90 active:text-primary-foreground"
            >
              <Lucideicons.circle_plus />
              <span>Quick Create</span>
            </.sidebar_menu_button>
            <.button
              size="icon"
              class="size-8 group-data-[collapsible=icon]:opacity-0"
              variant="outline"
            >
              <Lucideicons.mail />
              <span class="sr-only">Inbox</span>
            </.button>
          </.sidebar_menu_item>
        </.sidebar_menu>
        <.sidebar_menu>
          <.sidebar_menu_item :for={item <- @items}>
            <.sidebar_menu_button tooltip={item.title}>
              <.dynamic :if={item[:icon]} tag={item.icon} />
              <span>{item.title}</span>
            </.sidebar_menu_button>
          </.sidebar_menu_item>
        </.sidebar_menu>
      </.sidebar_group_content>
    </.sidebar_group>
    """
  end

  attr :items, :list, required: true

  def nav_documents(assigns) do
    ~H"""
    <.sidebar_group class="group-data-[collapsible=icon]:hidden">
      <.sidebar_group_label>Documents</.sidebar_group_label>
      <.sidebar_menu>
        <.sidebar_menu_item :for={item <- @items}>
          <.as_child tag={&sidebar_menu_button/1} child="a" href={item.url}>
            <.dynamic tag={item.icon} />
            <span>{item.name}</span>
          </.as_child>
          <.dropdown_menu id={"document-" <> slug(item.name)} class="contents">
            <.as_child
              tag={&dropdown_menu_trigger/1}
              child={&sidebar_menu_action/1}
              show_on_hover
              class="rounded-sm data-[state=open]:bg-accent"
            >
              <Lucideicons.ellipsis />
              <span class="sr-only">More</span>
            </.as_child>
            <.dropdown_menu_content class="w-24 rounded-lg" side="right" align="start">
              <.dropdown_menu_item>
                <Lucideicons.folder />
                <span>Open</span>
              </.dropdown_menu_item>
              <.dropdown_menu_item>
                <Lucideicons.share_2 />
                <span>Share</span>
              </.dropdown_menu_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_item variant="destructive">
                <Lucideicons.trash_2 />
                <span>Delete</span>
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

  attr :items, :list, required: true
  attr :class, :string, default: nil

  def nav_secondary(assigns) do
    ~H"""
    <.sidebar_group class={@class}>
      <.sidebar_group_content>
        <.sidebar_menu>
          <.sidebar_menu_item :for={item <- @items}>
            <.as_child tag={&sidebar_menu_button/1} child="a" href={item.url}>
              <.dynamic tag={item.icon} />
              <span>{item.title}</span>
            </.as_child>
          </.sidebar_menu_item>
        </.sidebar_menu>
      </.sidebar_group_content>
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
            <.avatar class="h-8 w-8 rounded-lg grayscale">
              <.avatar_image src={@user.avatar} alt={@user.name} />
              <.avatar_fallback class="rounded-lg">CN</.avatar_fallback>
            </.avatar>
            <div class="grid flex-1 text-left text-sm leading-tight">
              <span class="truncate font-medium">{@user.name}</span>
              <span class="truncate text-xs text-muted-foreground">{@user.email}</span>
            </div>
            <Lucideicons.ellipsis_vertical class="ml-auto size-4" />
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
                  <span class="truncate text-xs text-muted-foreground">{@user.email}</span>
                </div>
              </div>
            </.dropdown_menu_label>
            <.dropdown_menu_separator />
            <.dropdown_menu_group>
              <.dropdown_menu_item>
                <Lucideicons.circle_user_round /> Account
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

  # Header and cards

  def site_header(assigns) do
    ~H"""
    <header class="flex h-(--header-height) shrink-0 items-center gap-2 border-b transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-(--header-height)">
      <div class="flex w-full items-center gap-1 px-4 lg:gap-2 lg:px-6">
        <.sidebar_trigger as={&button/1} target="app-sidebar" class="-ml-1" />
        <.separator orientation="vertical" class="mx-2 h-4" />
        <h1 class="text-base font-medium">Documents</h1>
        <div class="ml-auto flex items-center gap-2">
          <.button
            variant="ghost"
            size="sm"
            class="hidden sm:flex dark:text-foreground"
            href="https://github.com/bluzky/salad_ui"
            rel="noopener noreferrer"
            target="_blank"
          >
            GitHub
          </.button>
        </div>
      </div>
    </header>
    """
  end

  def section_cards(assigns) do
    assigns = assign(assigns, :cards, @section_cards)

    ~H"""
    <div class="grid grid-cols-1 gap-4 px-4 *:data-[slot=card]:bg-gradient-to-t *:data-[slot=card]:from-primary/5 *:data-[slot=card]:to-card *:data-[slot=card]:shadow-xs lg:px-6 @xl/main:grid-cols-2 @5xl/main:grid-cols-4 dark:*:data-[slot=card]:bg-card">
      <.card :for={card <- @cards} class="@container/card">
        <.card_header>
          <.card_description>{card.description}</.card_description>
          <.card_title class="text-2xl font-semibold tabular-nums @[250px]/card:text-3xl">
            {card.value}
          </.card_title>
          <.card_action>
            <.badge variant="outline">
              <.trend_icon trend={card.trend} />
              {card.change}
            </.badge>
          </.card_action>
        </.card_header>
        <.card_footer class="flex-col items-start gap-1.5 text-sm">
          <div class="line-clamp-1 flex gap-2 font-medium">
            {card.summary} <.trend_icon trend={card.trend} class="size-4" />
          </div>
          <div class="text-muted-foreground">{card.detail}</div>
        </.card_footer>
      </.card>
    </div>
    """
  end

  attr :trend, :atom, required: true
  attr :class, :string, default: nil

  defp trend_icon(%{trend: :down} = assigns), do: ~H"<Lucideicons.trending_down class={@class} />"
  defp trend_icon(assigns), do: ~H"<Lucideicons.trending_up class={@class} />"

  # Chart

  attr :time_range, :string, required: true
  attr :data, :list, required: true

  def chart_area_interactive(assigns) do
    assigns = assign(assigns, config: @visitors_config, ranges: @time_ranges)

    ~H"""
    <.card class="@container/card">
      <.card_header>
        <.card_title>Total Visitors</.card_title>
        <.card_description>
          <span class="hidden @[540px]/card:block">Total for the last 3 months</span>
          <span class="@[540px]/card:hidden">Last 3 months</span>
        </.card_description>
        <.card_action>
          <form id="time-range-form" phx-change="set_time_range" class="hidden @[767px]/card:flex">
            <.toggle_group
              :let={builder}
              id="time-range-toggle"
              type="single"
              name="time_range"
              value={@time_range}
              variant="outline"
              class="*:data-[slot=toggle-group-item]:px-4!"
            >
              <.toggle_group_item
                :for={{value, label, _days} <- @ranges}
                value={value}
                builder={builder}
              >
                {label}
              </.toggle_group_item>
            </.toggle_group>
          </form>
          <.select id="time-range-select" value={@time_range} on-value-changed="set_time_range">
            <.select_trigger
              size="sm"
              aria-label="Select a value"
              class="flex w-40 **:data-[slot=select-value]:block **:data-[slot=select-value]:truncate @[767px]/card:hidden"
            >
              <.select_value placeholder="Last 3 months" />
            </.select_trigger>
            <.select_content class="rounded-xl">
              <.select_item :for={{value, label, _days} <- @ranges} value={value} class="rounded-lg">
                {label}
              </.select_item>
            </.select_content>
          </.select>
        </.card_action>
      </.card_header>
      <.card_content class="px-2 pt-4 sm:px-6 sm:pt-6">
        <.chart_container id="visitors-chart" config={@config} class="aspect-auto h-[250px] w-full">
          <.chart
            type="area"
            data={@data}
            index="date"
            series={["mobile", "desktop"]}
            stacked
            name="Total visitors"
            options={%{scales: %{x: %{ticks: %{maxRotation: 0, autoSkipPadding: 32}}}}}
          />
          <.chart_tooltip indicator="dot" />
        </.chart_container>
      </.card_content>
    </.card>
    """
  end

  # Data table

  attr :rows, :list, required: true
  attr :selected, :any, required: true
  attr :hidden_columns, :any, required: true
  attr :page_index, :integer, required: true
  attr :page_size, :integer, required: true
  attr :view, :string, required: true

  def data_table(assigns) do
    page_count = max(ceil(length(assigns.rows) / assigns.page_size), 1)
    page_rows = assigns.rows |> Enum.drop(assigns.page_index * assigns.page_size) |> Enum.take(assigns.page_size)
    page_selected = Enum.count(page_rows, &MapSet.member?(assigns.selected, &1.id))

    assigns =
      assign(assigns,
        page_count: page_count,
        page_rows: page_rows,
        all_selected: page_rows != [] and page_selected == length(page_rows),
        some_selected: page_selected > 0 and page_selected < length(page_rows),
        views: @views,
        hideable_columns: @hideable_columns
      )

    ~H"""
    <.tabs
      id="data-table-tabs"
      value={@view}
      on-tab-changed="set_view"
      class="w-full flex-col justify-start gap-6"
    >
      <div class="flex items-center justify-between px-4 lg:px-6">
        <.label for="view-selector" class="sr-only">View</.label>
        <.select id="view-selector" value={@view} on-value-changed="set_view">
          <.select_trigger size="sm" class="flex w-fit @4xl/main:hidden">
            <.select_value placeholder="Select a view" />
          </.select_trigger>
          <.select_content>
            <.select_item :for={{value, label, _count} <- @views} value={value}>{label}</.select_item>
          </.select_content>
        </.select>
        <.tabs_list class="hidden **:data-[slot=badge]:size-5 **:data-[slot=badge]:rounded-full **:data-[slot=badge]:bg-muted-foreground/30 **:data-[slot=badge]:px-1 @4xl/main:flex">
          <.tabs_trigger :for={{value, label, count} <- @views} value={value}>
            {label}
            <.badge :if={count} variant="secondary">{count}</.badge>
          </.tabs_trigger>
        </.tabs_list>
        <div class="flex items-center gap-2">
          <.dropdown_menu id="customize-columns">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline" size="sm">
              <Lucideicons.columns_3 />
              <span class="hidden lg:inline">Customize Columns</span>
              <span class="lg:hidden">Columns</span>
              <Lucideicons.chevron_down />
            </.as_child>
            <.dropdown_menu_content align="end" class="w-56">
              <.dropdown_menu_checkbox_item
                :for={column <- @hideable_columns}
                value={column}
                class="capitalize"
                checked={not MapSet.member?(@hidden_columns, column)}
                on-checked-change="toggle_column"
              >
                {column}
              </.dropdown_menu_checkbox_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
          <.button variant="outline" size="sm">
            <Lucideicons.plus />
            <span class="hidden lg:inline">Add Section</span>
          </.button>
        </div>
      </div>
      <.tabs_content value="outline" class="relative flex flex-col gap-4 overflow-auto px-4 lg:px-6">
        <div class="overflow-hidden rounded-lg border">
          <.table>
            <.table_header class="sticky top-0 z-10 bg-muted">
              <.table_row>
                <.table_head>
                  <div class="flex items-center justify-center">
                    <.checkbox
                      id="select-page"
                      value={@all_selected}
                      indeterminate={@some_selected}
                      phx-click="toggle_page"
                      aria-label="Select all"
                    />
                  </div>
                </.table_head>
                <.table_head>Header</.table_head>
                <.table_head :if={visible?(@hidden_columns, "type")}>Section Type</.table_head>
                <.table_head :if={visible?(@hidden_columns, "status")}>Status</.table_head>
                <.table_head :if={visible?(@hidden_columns, "target")}>
                  <div class="w-full text-right">Target</div>
                </.table_head>
                <.table_head :if={visible?(@hidden_columns, "limit")}>
                  <div class="w-full text-right">Limit</div>
                </.table_head>
                <.table_head :if={visible?(@hidden_columns, "reviewer")}>Reviewer</.table_head>
                <.table_head><span class="sr-only">Actions</span></.table_head>
              </.table_row>
            </.table_header>
            <.table_body class="**:data-[slot=table-cell]:first:w-8">
              <.table_row
                :for={row <- @page_rows}
                id={"row-#{row.id}"}
                data-state={MapSet.member?(@selected, row.id) && "selected"}
              >
                <.table_cell>
                  <div class="flex items-center justify-center">
                    <.checkbox
                      id={"select-row-#{row.id}"}
                      value={MapSet.member?(@selected, row.id)}
                      phx-click="toggle_row"
                      phx-value-id={row.id}
                      aria-label="Select row"
                    />
                  </div>
                </.table_cell>
                <.table_cell>
                  <.button
                    variant="link"
                    class="w-fit px-0 text-left text-foreground"
                    phx-click="view_row"
                    phx-value-id={row.id}
                  >
                    {row.header}
                  </.button>
                </.table_cell>
                <.table_cell :if={visible?(@hidden_columns, "type")}>
                  <div class="w-32">
                    <.badge variant="outline" class="px-1.5 text-muted-foreground">{row.type}</.badge>
                  </div>
                </.table_cell>
                <.table_cell :if={visible?(@hidden_columns, "status")}>
                  <.badge variant="outline" class="px-1.5 text-muted-foreground">
                    <Lucideicons.circle_check
                      :if={row.status == "Done"}
                      class="fill-green-500 stroke-background dark:fill-green-400"
                    />
                    <Lucideicons.loader :if={row.status != "Done"} />
                    {row.status}
                  </.badge>
                </.table_cell>
                <.table_cell :if={visible?(@hidden_columns, "target")}>
                  <.inline_number_form row={row} field="target" label="Target" />
                </.table_cell>
                <.table_cell :if={visible?(@hidden_columns, "limit")}>
                  <.inline_number_form row={row} field="limit" label="Limit" />
                </.table_cell>
                <.table_cell :if={visible?(@hidden_columns, "reviewer")}>
                  <%= if row.reviewer != "Assign reviewer" do %>
                    {row.reviewer}
                  <% else %>
                    <.label for={"#{row.id}-reviewer"} class="sr-only">Reviewer</.label>
                    <.select id={"#{row.id}-reviewer"}>
                      <.select_trigger
                        size="sm"
                        class="w-38 **:data-[slot=select-value]:block **:data-[slot=select-value]:truncate"
                      >
                        <.select_value placeholder="Assign reviewer" />
                      </.select_trigger>
                      <.select_content>
                        <.select_item value="Eddie Lake">Eddie Lake</.select_item>
                        <.select_item value="Jamik Tashpulatov">Jamik Tashpulatov</.select_item>
                      </.select_content>
                    </.select>
                  <% end %>
                </.table_cell>
                <.table_cell>
                  <.dropdown_menu id={"row-actions-#{row.id}"}>
                    <.as_child
                      tag={&dropdown_menu_trigger/1}
                      child={&button/1}
                      variant="ghost"
                      size="icon"
                      class="flex size-8 text-muted-foreground data-[state=open]:bg-muted"
                    >
                      <Lucideicons.ellipsis_vertical />
                      <span class="sr-only">Open menu</span>
                    </.as_child>
                    <.dropdown_menu_content align="end" class="w-32">
                      <.dropdown_menu_item>Edit</.dropdown_menu_item>
                      <.dropdown_menu_item>Make a copy</.dropdown_menu_item>
                      <.dropdown_menu_item>Favorite</.dropdown_menu_item>
                      <.dropdown_menu_separator />
                      <.dropdown_menu_item variant="destructive">Delete</.dropdown_menu_item>
                    </.dropdown_menu_content>
                  </.dropdown_menu>
                </.table_cell>
              </.table_row>
              <.table_row :if={@page_rows == []}>
                <.table_cell class="h-24 text-center" {%{colspan: 8}}>No results.</.table_cell>
              </.table_row>
            </.table_body>
          </.table>
        </div>
        <div class="flex items-center justify-between px-4">
          <div class="hidden flex-1 text-sm text-muted-foreground lg:flex">
            {MapSet.size(@selected)} of {length(@rows)} row(s) selected.
          </div>
          <div class="flex w-full items-center gap-8 lg:w-fit">
            <div class="hidden items-center gap-2 lg:flex">
              <.label for="rows-per-page" class="text-sm font-medium">Rows per page</.label>
              <.select id="rows-per-page" value={"#{@page_size}"} on-value-changed="set_page_size">
                <.select_trigger size="sm" class="w-20">
                  <.select_value placeholder={"#{@page_size}"} />
                </.select_trigger>
                <.select_content side="top">
                  <.select_item :for={size <- [10, 20, 30, 40, 50]} value={"#{size}"}>
                    {size}
                  </.select_item>
                </.select_content>
              </.select>
            </div>
            <div class="flex w-fit items-center justify-center text-sm font-medium">
              Page {@page_index + 1} of {@page_count}
            </div>
            <div class="ml-auto flex items-center gap-2 lg:ml-0">
              <.button
                variant="outline"
                class="hidden h-8 w-8 p-0 lg:flex"
                phx-click="go_to_page"
                phx-value-page={0}
                disabled={@page_index == 0}
              >
                <span class="sr-only">Go to first page</span>
                <Lucideicons.chevrons_left />
              </.button>
              <.button
                variant="outline"
                class="size-8"
                size="icon"
                phx-click="go_to_page"
                phx-value-page={@page_index - 1}
                disabled={@page_index == 0}
              >
                <span class="sr-only">Go to previous page</span>
                <Lucideicons.chevron_left />
              </.button>
              <.button
                variant="outline"
                class="size-8"
                size="icon"
                phx-click="go_to_page"
                phx-value-page={@page_index + 1}
                disabled={@page_index >= @page_count - 1}
              >
                <span class="sr-only">Go to next page</span>
                <Lucideicons.chevron_right />
              </.button>
              <.button
                variant="outline"
                class="hidden size-8 lg:flex"
                size="icon"
                phx-click="go_to_page"
                phx-value-page={@page_count - 1}
                disabled={@page_index >= @page_count - 1}
              >
                <span class="sr-only">Go to last page</span>
                <Lucideicons.chevrons_right />
              </.button>
            </div>
          </div>
        </div>
      </.tabs_content>
      <.tabs_content value="past-performance" class="flex flex-col px-4 lg:px-6">
        <div class="aspect-video w-full flex-1 rounded-lg border border-dashed"></div>
      </.tabs_content>
      <.tabs_content value="key-personnel" class="flex flex-col px-4 lg:px-6">
        <div class="aspect-video w-full flex-1 rounded-lg border border-dashed"></div>
      </.tabs_content>
      <.tabs_content value="focus-documents" class="flex flex-col px-4 lg:px-6">
        <div class="aspect-video w-full flex-1 rounded-lg border border-dashed"></div>
      </.tabs_content>
    </.tabs>
    """
  end

  attr :row, :map, required: true
  attr :field, :string, required: true
  attr :label, :string, required: true

  defp inline_number_form(assigns) do
    ~H"""
    <form id={"#{@row.id}-#{@field}-form"} phx-submit="save_cell">
      <input type="hidden" name="row_id" value={@row.id} />
      <input type="hidden" name="field" value={@field} />
      <.label for={"#{@row.id}-#{@field}"} class="sr-only">{@label}</.label>
      <.input
        id={"#{@row.id}-#{@field}"}
        name="value"
        value={Map.fetch!(@row, String.to_existing_atom(@field))}
        class="h-8 w-16 border-transparent bg-transparent text-right shadow-none hover:bg-input/30 focus-visible:border focus-visible:bg-background dark:bg-transparent dark:hover:bg-input/30 dark:focus-visible:bg-input/30"
      />
    </form>
    """
  end

  attr :item, :map, required: true

  def table_cell_viewer(assigns) do
    assigns = assign(assigns, chart_data: @drawer_chart, chart_config: @drawer_chart_config)

    ~H"""
    <.drawer id="row-viewer" direction="right">
      <.drawer_content>
        <.drawer_header class="gap-1">
          <.drawer_title>{@item.header}</.drawer_title>
          <.drawer_description>Showing total visitors for the last 6 months</.drawer_description>
        </.drawer_header>
        <div class="flex flex-col gap-4 overflow-y-auto px-4 text-sm">
          <.chart_container id="row-viewer-chart" config={@chart_config} class="aspect-video w-full">
            <.chart
              type="area"
              data={@chart_data}
              index="month"
              series={["mobile", "desktop"]}
              stacked
              index_axis={false}
              name="Visitors for the last 6 months"
            />
            <.chart_tooltip indicator="dot" />
          </.chart_container>
          <.separator />
          <div class="grid gap-2">
            <div class="flex gap-2 leading-none font-medium">
              Trending up by 5.2% this month <Lucideicons.trending_up class="size-4" />
            </div>
            <div class="text-muted-foreground">
              Showing total visitors for the last 6 months. This is just some random text to test the
              layout. It spans multiple lines and should wrap around.
            </div>
          </div>
          <.separator />
          <form id={"row-viewer-form-#{@item.id}"} class="flex flex-col gap-4">
            <div class="flex flex-col gap-3">
              <.label for="header">Header</.label>
              <.input id="header" name="header" value={@item.header} />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div class="flex flex-col gap-3">
                <.label for={"type-#{@item.id}"}>Type</.label>
                <.select id={"type-#{@item.id}"} name="type" default-value={@item.type}>
                  <.select_trigger class="w-full">
                    <.select_value placeholder="Select a type" />
                  </.select_trigger>
                  <.select_content>
                    <.select_item
                      :for={
                        type <-
                          ~w(Table\ of\ Contents Executive\ Summary Technical\ Approach Design Capabilities Focus\ Documents Narrative Cover\ Page)
                      }
                      value={type}
                    >
                      {type}
                    </.select_item>
                  </.select_content>
                </.select>
              </div>
              <div class="flex flex-col gap-3">
                <.label for={"status-#{@item.id}"}>Status</.label>
                <.select id={"status-#{@item.id}"} name="status" default-value={@item.status}>
                  <.select_trigger class="w-full">
                    <.select_value placeholder="Select a status" />
                  </.select_trigger>
                  <.select_content>
                    <.select_item
                      :for={status <- ["Done", "In Progress", "Not Started"]}
                      value={status}
                    >
                      {status}
                    </.select_item>
                  </.select_content>
                </.select>
              </div>
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div class="flex flex-col gap-3">
                <.label for="target">Target</.label>
                <.input id="target" name="target" value={@item.target} />
              </div>
              <div class="flex flex-col gap-3">
                <.label for="limit">Limit</.label>
                <.input id="limit" name="limit" value={@item.limit} />
              </div>
            </div>
            <div class="flex flex-col gap-3">
              <.label for={"reviewer-#{@item.id}"}>Reviewer</.label>
              <.select id={"reviewer-#{@item.id}"} name="reviewer" default-value={@item.reviewer}>
                <.select_trigger class="w-full">
                  <.select_value placeholder="Select a reviewer" />
                </.select_trigger>
                <.select_content>
                  <.select_item
                    :for={name <- ["Eddie Lake", "Jamik Tashpulatov", "Emily Whalen"]}
                    value={name}
                  >
                    {name}
                  </.select_item>
                </.select_content>
              </.select>
            </div>
          </form>
        </div>
        <.drawer_footer>
          <.button>Submit</.button>
          <.drawer_close>
            <.button variant="outline" class="w-full">Done</.button>
          </.drawer_close>
        </.drawer_footer>
      </.drawer_content>
    </.drawer>
    """
  end

  # Events

  @impl true
  def handle_event("set_time_range", %{"time_range" => range}, socket), do: {:noreply, assign_time_range(socket, range)}
  def handle_event("set_time_range", %{"value" => range}, socket), do: {:noreply, assign_time_range(socket, range)}
  # Pressing the selected toggle group item releases it, so the form submits no range.
  def handle_event("set_time_range", _params, socket), do: {:noreply, socket}

  def handle_event("set_view", %{"value" => view}, socket), do: {:noreply, assign(socket, :view, view)}

  def handle_event("toggle_column", %{"value" => column, "checked" => checked}, socket)
      when column in @hideable_columns do
    hidden =
      if checked,
        do: MapSet.delete(socket.assigns.hidden_columns, column),
        else: MapSet.put(socket.assigns.hidden_columns, column)

    {:noreply, assign(socket, :hidden_columns, hidden)}
  end

  def handle_event("toggle_row", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected = socket.assigns.selected

    selected = if MapSet.member?(selected, id), do: MapSet.delete(selected, id), else: MapSet.put(selected, id)
    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event("toggle_page", _params, socket) do
    %{rows: rows, selected: selected, page_index: page_index, page_size: page_size} = socket.assigns
    ids = rows |> Enum.drop(page_index * page_size) |> Enum.take(page_size) |> MapSet.new(& &1.id)

    selected =
      if MapSet.subset?(ids, selected),
        do: MapSet.difference(selected, ids),
        else: MapSet.union(selected, ids)

    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event("go_to_page", %{"page" => page}, socket) do
    last = max(ceil(length(socket.assigns.rows) / socket.assigns.page_size) - 1, 0)
    {:noreply, assign(socket, :page_index, page |> String.to_integer() |> max(0) |> min(last))}
  end

  def handle_event("set_page_size", %{"value" => size}, socket) do
    {:noreply, assign(socket, page_size: String.to_integer(size), page_index: 0)}
  end

  def handle_event("view_row", %{"id" => id}, socket) do
    item = Enum.find(socket.assigns.rows, &(&1.id == String.to_integer(id)))

    {:noreply,
     socket
     |> assign(:viewing, item)
     |> LiveView.send_command("row-viewer", "open")}
  end

  def handle_event("save_cell", %{"row_id" => id, "field" => field, "value" => value}, socket)
      when field in ~w(target limit) do
    id = String.to_integer(id)
    key = String.to_existing_atom(field)
    rows = Enum.map(socket.assigns.rows, &if(&1.id == id, do: Map.put(&1, key, value), else: &1))
    row = Enum.find(rows, &(&1.id == id))

    {:noreply, socket |> assign(:rows, rows) |> toast_success("Saved #{row.header}")}
  end

  defp visible?(hidden_columns, column), do: not MapSet.member?(hidden_columns, column)

  defp slug(text), do: text |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")
end
