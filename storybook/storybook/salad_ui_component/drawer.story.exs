defmodule Storybook.SaladUIComponents.Drawer do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladStorybookWeb.CoreComponents
  alias SaladUI.Button
  alias SaladUI.Dialog
  alias SaladUI.Drawer
  alias SaladUI.Input
  alias SaladUI.Label

  def function, do: &Drawer.drawer/1

  def imports,
    do: [
      {Drawer,
       [
         drawer_trigger: 1,
         drawer_content: 1,
         drawer_header: 1,
         drawer_title: 1,
         drawer_description: 1,
         drawer_footer: 1,
         drawer_close: 1
       ]},
      {Dialog,
       [dialog: 1, dialog_trigger: 1, dialog_content: 1, dialog_header: 1, dialog_title: 1, dialog_description: 1]},
      {Button, [button: 1]},
      {Input, [input: 1]},
      {Label, [label: 1]},
      {CoreComponents, [icon: 1]}
    ]

  @lorem """
  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod
  tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
  quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
  consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
  cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
  proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
  """

  @bars [400, 300, 200, 300, 200, 278, 189, 239, 300, 200, 278, 189, 349]

  # The "Move Goal" body shared by the demo and RTL examples. The goal value is
  # static here; in an app it would come from your LiveView assigns.
  defp goal_body(decrease, increase, unit) do
    bars =
      Enum.map_join(@bars, "\n", &~s(<div class="flex-1 rounded-t-sm bg-foreground/90" style="height: #{&1 / 4}%"></div>))

    """
            <div class="p-4 pb-0">
              <div class="flex items-center justify-center space-x-2">
                <.button variant="outline" size="icon" class="h-8 w-8 shrink-0 rounded-full">
                  <.icon name="hero-minus" class="size-4" />
                  <span class="sr-only">#{decrease}</span>
                </.button>
                <div class="flex-1 text-center">
                  <div class="text-7xl font-bold tracking-tighter">350</div>
                  <div class="text-[0.70rem] text-muted-foreground uppercase">#{unit}</div>
                </div>
                <.button variant="outline" size="icon" class="h-8 w-8 shrink-0 rounded-full">
                  <.icon name="hero-plus" class="size-4" />
                  <span class="sr-only">#{increase}</span>
                </.button>
              </div>
              <div class="mt-3 flex h-[120px] items-end gap-1">
                #{bars}
              </div>
            </div>
    """
  end

  defp side_drawer(side) do
    direction = if side == "bottom", do: "", else: ~s(direction="#{side}")

    """
      <.drawer id="drawer-side-#{side}" #{direction}>
        <.drawer_trigger>
          <.button variant="outline" class="capitalize">#{side}</.button>
        </.drawer_trigger>
        <.drawer_content class="data-[vaul-drawer-direction=bottom]:max-h-[50vh] data-[vaul-drawer-direction=top]:max-h-[50vh]">
          <.drawer_header>
            <.drawer_title>Move Goal</.drawer_title>
            <.drawer_description>Set your daily activity goal.</.drawer_description>
          </.drawer_header>
          <div class="overflow-y-auto px-4">
            <p :for={_ <- 1..10} class="mb-4 leading-normal">#{String.trim(@lorem)}</p>
          </div>
          <.drawer_footer>
            <.button>Submit</.button>
            <.drawer_close>
              <.button variant="outline" class="w-full">Cancel</.button>
            </.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </.drawer>
    """
  end

  def variations do
    [
      %Variation{
        id: :demo,
        description: "Drag the drawer down, press Escape or click the overlay to dismiss it.",
        template: """
        <.drawer id="drawer-demo">
          <.drawer_trigger>
            <.button variant="outline">Open Drawer</.button>
          </.drawer_trigger>
          <.drawer_content>
            <div class="mx-auto w-full max-w-sm">
              <.drawer_header>
                <.drawer_title>Move Goal</.drawer_title>
                <.drawer_description>Set your daily activity goal.</.drawer_description>
              </.drawer_header>
        #{goal_body("Decrease", "Increase", "Calories/day")}
              <.drawer_footer>
                <.button>Submit</.button>
                <.drawer_close>
                  <.button variant="outline" class="w-full">Cancel</.button>
                </.drawer_close>
              </.drawer_footer>
            </div>
          </.drawer_content>
        </.drawer>
        """
      },
      %Variation{
        id: :scrollable_content,
        description: "Keep actions visible while the content scrolls.",
        template: """
        <.drawer id="drawer-scrollable" direction="right">
          <.drawer_trigger>
            <.button variant="outline">Scrollable Content</.button>
          </.drawer_trigger>
          <.drawer_content>
            <.drawer_header>
              <.drawer_title>Move Goal</.drawer_title>
              <.drawer_description>Set your daily activity goal.</.drawer_description>
            </.drawer_header>
            <div class="overflow-y-auto px-4">
              <p :for={_ <- 1..10} class="mb-4 leading-normal">#{String.trim(@lorem)}</p>
            </div>
            <.drawer_footer>
              <.button>Submit</.button>
              <.drawer_close>
                <.button variant="outline" class="w-full">Cancel</.button>
              </.drawer_close>
            </.drawer_footer>
          </.drawer_content>
        </.drawer>
        """
      },
      %Variation{
        id: :sides,
        description: "Use `direction` to set the side: `top`, `right`, `bottom` (default) or `left`.",
        template: """
        <div class="flex flex-wrap gap-2">
        #{Enum.map_join(~w(top right bottom left), "\n", &side_drawer/1)}
        </div>
        """
      },
      %Variation{
        id: :responsive_dialog,
        description: """
        A `dialog` on desktop and a `drawer` on mobile: render both and show one
        per breakpoint. Resize the window below 768px to get the drawer.
        """,
        template: """
        <div>
          <div class="hidden md:block">
            <.dialog id="responsive-dialog">
              <.dialog_trigger>
                <.button variant="outline">Edit Profile</.button>
              </.dialog_trigger>
              <.dialog_content class="sm:max-w-[425px]">
                <.dialog_header>
                  <.dialog_title>Edit profile</.dialog_title>
                  <.dialog_description>
                    Make changes to your profile here. Click save when you're done.
                  </.dialog_description>
                </.dialog_header>
                <form class="grid items-start gap-6">
                  <div class="grid gap-3">
                    <.label for="responsive-dialog-email">Email</.label>
                    <.input type="email" id="responsive-dialog-email" value="shadcn@example.com" />
                  </div>
                  <div class="grid gap-3">
                    <.label for="responsive-dialog-username">Username</.label>
                    <.input id="responsive-dialog-username" value="@shadcn" />
                  </div>
                  <.button type="submit">Save changes</.button>
                </form>
              </.dialog_content>
            </.dialog>
          </div>
          <div class="md:hidden">
            <.drawer id="responsive-drawer">
              <.drawer_trigger>
                <.button variant="outline">Edit Profile</.button>
              </.drawer_trigger>
              <.drawer_content>
                <.drawer_header class="text-left">
                  <.drawer_title>Edit profile</.drawer_title>
                  <.drawer_description>
                    Make changes to your profile here. Click save when you're done.
                  </.drawer_description>
                </.drawer_header>
                <form class="grid items-start gap-6 px-4">
                  <div class="grid gap-3">
                    <.label for="responsive-drawer-email">Email</.label>
                    <.input type="email" id="responsive-drawer-email" value="shadcn@example.com" />
                  </div>
                  <div class="grid gap-3">
                    <.label for="responsive-drawer-username">Username</.label>
                    <.input id="responsive-drawer-username" value="@shadcn" />
                  </div>
                  <.button type="submit">Save changes</.button>
                </form>
                <.drawer_footer class="pt-2">
                  <.drawer_close>
                    <.button variant="outline" class="w-full">Cancel</.button>
                  </.drawer_close>
                </.drawer_footer>
              </.drawer_content>
            </.drawer>
          </div>
        </div>
        """
      },
      %Variation{
        id: :rtl,
        description: ~s|Pass `dir="rtl"` to `drawer_content` for right-to-left content.|,
        template: """
        <.drawer id="drawer-rtl">
          <.drawer_trigger>
            <.button variant="outline">فتح الدرج</.button>
          </.drawer_trigger>
          <.drawer_content dir="rtl">
            <div class="mx-auto w-full max-w-sm">
              <.drawer_header>
                <.drawer_title>نقل الهدف</.drawer_title>
                <.drawer_description>حدد هدف نشاطك اليومي.</.drawer_description>
              </.drawer_header>
        #{goal_body("تقليل", "زيادة", "سعرات حرارية/يوم")}
              <.drawer_footer>
                <.button>إرسال</.button>
                <.drawer_close>
                  <.button variant="outline" class="w-full">إلغاء</.button>
                </.drawer_close>
              </.drawer_footer>
            </div>
          </.drawer_content>
        </.drawer>
        """
      },
      %Variation{
        id: :snap_points,
        description: """
        `snap_points` lets the drawer rest part-way open. Drag it up to expand,
        down to shrink or dismiss.
        """,
        template: """
        <.drawer id="drawer-snap-points" snap_points={["148px", "355px", 1]} active_snap_point="148px">
          <.drawer_trigger>
            <.button variant="outline">Snap Points</.button>
          </.drawer_trigger>
          <.drawer_content class="h-full data-[vaul-drawer-direction=bottom]:max-h-[97%]">
            <div class="mx-auto flex w-full max-w-md flex-col overflow-hidden p-4 pt-5">
              <.drawer_header class="px-0">
                <.drawer_title>The Hidden Details</.drawer_title>
                <.drawer_description>
                  Drag the handle up to reveal more, or down to collapse.
                </.drawer_description>
              </.drawer_header>
              <p :for={_ <- 1..6} class="mb-4 text-sm leading-normal">#{String.trim(@lorem)}</p>
            </div>
          </.drawer_content>
        </.drawer>
        """
      },
      %Variation{
        id: :non_dismissible,
        description: """
        `dismissible={false}` ignores drags, Escape and overlay clicks; close it
        from a button.
        """,
        template: """
        <.drawer id="drawer-non-dismissible" dismissible={false}>
          <.drawer_trigger>
            <.button variant="outline">Non-dismissible</.button>
          </.drawer_trigger>
          <.drawer_content>
            <div class="mx-auto w-full max-w-sm">
              <.drawer_header>
                <.drawer_title>Confirm your choice</.drawer_title>
                <.drawer_description>This drawer only closes from its buttons.</.drawer_description>
              </.drawer_header>
              <.drawer_footer>
                <.drawer_close>
                  <.button class="w-full">Confirm</.button>
                </.drawer_close>
              </.drawer_footer>
            </div>
          </.drawer_content>
        </.drawer>
        """
      }
    ]
  end
end
