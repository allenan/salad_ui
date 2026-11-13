defmodule Storybook.SaladUIComponents.NavigationMenu do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.NavigationMenu

  def function, do: &NavigationMenu.navigation_menu/1

  def imports,
    do: [
      {NavigationMenu,
       [
         navigation_menu_list: 1,
         navigation_menu_item: 1,
         navigation_menu_trigger: 1,
         navigation_menu_content: 1,
         navigation_menu_link: 1,
         navigation_menu_indicator: 1,
         navigation_menu_trigger_style: 0
       ]}
    ]

  def descriptions do
    """
    A collection of links for navigating websites. Triggers open on hover (with a
    short delay), click, or `Enter`/`Space`; arrow keys move between top-level
    items and into an open panel; `Escape` closes.

    By default open panels render in a shared viewport that animates its size
    between panels. Pass `viewport={false}` to render each panel under its own
    trigger, as shadcn's desktop demo does.
    """
  end

  @components [
    {"Alert Dialog", "A modal dialog that interrupts the user with important content and expects a response."},
    {"Hover Card", "For sighted users to preview content available behind a link."},
    {"Progress",
     "Displays an indicator showing the completion progress of a task, typically displayed as a progress bar."},
    {"Scroll-area", "Visually or semantically separates content."},
    {"Tabs", "A set of layered sections of content—known as tab panels—that are displayed one at a time."},
    {"Tooltip",
     "A popup that displays information related to an element when the element receives keyboard focus or the mouse hovers over it."}
  ]

  defp list_item(title, href, description) do
    """
    <li>
      <.navigation_menu_link href="#{href}">
        <div class="text-sm leading-none font-medium">#{title}</div>
        <p class="line-clamp-2 text-sm leading-snug text-muted-foreground">#{description}</p>
      </.navigation_menu_link>
    </li>
    """
  end

  defp home_item do
    """
    <.navigation_menu_item value="home">
      <.navigation_menu_trigger>Home</.navigation_menu_trigger>
      <.navigation_menu_content>
        <ul class="grid gap-2 md:w-[400px] lg:w-[500px] lg:grid-cols-[.75fr_1fr]">
          <li class="row-span-3">
            <.navigation_menu_link
              href="#"
              class="flex h-full w-full flex-col justify-end rounded-md bg-linear-to-b from-muted/50 to-muted p-4 no-underline outline-hidden transition-all duration-200 select-none focus:shadow-md md:p-6"
            >
              <div class="mb-2 text-lg font-medium sm:mt-4">salad_ui</div>
              <p class="text-sm leading-tight text-muted-foreground">
                Beautifully designed components built with Tailwind CSS.
              </p>
            </.navigation_menu_link>
          </li>
          #{list_item("Introduction", "#introduction", "Re-usable components built using Phoenix LiveView and Tailwind CSS.")}
          #{list_item("Installation", "#installation", "How to install dependencies and structure your app.")}
          #{list_item("Typography", "#typography", "Styles for headings, paragraphs, lists...etc")}
        </ul>
      </.navigation_menu_content>
    </.navigation_menu_item>
    """
  end

  defp components_item do
    items = Enum.map_join(@components, "\n", fn {title, desc} -> list_item(title, "#", desc) end)

    """
    <.navigation_menu_item value="components">
      <.navigation_menu_trigger>Components</.navigation_menu_trigger>
      <.navigation_menu_content>
        <ul class="grid gap-2 sm:w-[400px] md:w-[500px] md:grid-cols-2 lg:w-[600px]">
          #{items}
        </ul>
      </.navigation_menu_content>
    </.navigation_menu_item>
    """
  end

  defp docs_item do
    """
    <.navigation_menu_item>
      <.navigation_menu_link href="#docs" class={navigation_menu_trigger_style()}>
        Docs
      </.navigation_menu_link>
    </.navigation_menu_item>
    """
  end

  @circle_help ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10" /><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" /><path d="M12 17h.01" /></svg>)
  @circle ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10" /></svg>)
  @circle_check ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10" /><path d="m9 12 2 2 4-4" /></svg>)

  defp desktop_items do
    """
    <.navigation_menu_item value="list" class="hidden md:block">
      <.navigation_menu_trigger>List</.navigation_menu_trigger>
      <.navigation_menu_content>
        <ul class="grid w-[300px] gap-4">
          <li>
            <.navigation_menu_link href="#">
              <div class="font-medium">Components</div>
              <div class="text-muted-foreground">Browse all components in the library.</div>
            </.navigation_menu_link>
            <.navigation_menu_link href="#">
              <div class="font-medium">Documentation</div>
              <div class="text-muted-foreground">Learn how to use the library.</div>
            </.navigation_menu_link>
            <.navigation_menu_link href="#">
              <div class="font-medium">Blog</div>
              <div class="text-muted-foreground">Read our latest blog posts.</div>
            </.navigation_menu_link>
          </li>
        </ul>
      </.navigation_menu_content>
    </.navigation_menu_item>
    <.navigation_menu_item value="simple" class="hidden md:block">
      <.navigation_menu_trigger>Simple</.navigation_menu_trigger>
      <.navigation_menu_content>
        <ul class="grid w-[200px] gap-4">
          <li>
            <.navigation_menu_link href="#">Components</.navigation_menu_link>
            <.navigation_menu_link href="#">Documentation</.navigation_menu_link>
            <.navigation_menu_link href="#">Blocks</.navigation_menu_link>
          </li>
        </ul>
      </.navigation_menu_content>
    </.navigation_menu_item>
    <.navigation_menu_item value="with-icon" class="hidden md:block">
      <.navigation_menu_trigger>With Icon</.navigation_menu_trigger>
      <.navigation_menu_content>
        <ul class="grid w-[200px] gap-4">
          <li>
            <.navigation_menu_link href="#" class="flex-row items-center gap-2">
              #{@circle_help} Backlog
            </.navigation_menu_link>
            <.navigation_menu_link href="#" class="flex-row items-center gap-2">
              #{@circle} To Do
            </.navigation_menu_link>
            <.navigation_menu_link href="#" class="flex-row items-center gap-2">
              #{@circle_check} Done
            </.navigation_menu_link>
          </li>
        </ul>
      </.navigation_menu_content>
    </.navigation_menu_item>
    """
  end

  def variations do
    [
      %Variation{
        id: :demo,
        description:
          "shadcn's demo: panels render under their own trigger (`viewport={false}`), a trigger-styled link, and list / simple / icon panels.",
        template: """
        <div class="flex h-96 justify-center p-4">
          <.navigation_menu id="navigation-menu-demo" viewport={false}>
            <.navigation_menu_list class="flex-wrap">
              #{home_item()}
              #{components_item()}
              #{docs_item()}
              #{desktop_items()}
            </.navigation_menu_list>
          </.navigation_menu>
        </div>
        """
      },
      %Variation{
        id: :viewport,
        description:
          "Default shared viewport: it resizes with an animation as you move between triggers, and content slides in from the side you came from. Includes the indicator.",
        template: """
        <div class="flex h-[28rem] justify-center p-4">
          <.navigation_menu id="navigation-menu-viewport">
            <.navigation_menu_list>
              #{home_item()}
              #{components_item()}
              #{docs_item()}
            </.navigation_menu_list>
            <.navigation_menu_indicator />
          </.navigation_menu>
        </div>
        """
      },
      %Variation{
        id: :link_component,
        description:
          "A top-level link styled like a trigger via `navigation_menu_trigger_style/0`. `navigation_menu_link` renders `Phoenix.Component.link/1`, so `href`, `navigate` and `patch` all work; `active` marks the current page.",
        template: """
        <div class="flex justify-center p-4">
          <.navigation_menu id="navigation-menu-links" viewport={false}>
            <.navigation_menu_list>
              <.navigation_menu_item>
                <.navigation_menu_link href="#documentation" class={navigation_menu_trigger_style()} active>
                  Documentation
                </.navigation_menu_link>
              </.navigation_menu_item>
              <.navigation_menu_item>
                <.navigation_menu_link href="#blog" class={navigation_menu_trigger_style()}>
                  Blog
                </.navigation_menu_link>
              </.navigation_menu_item>
            </.navigation_menu_list>
          </.navigation_menu>
        </div>
        """
      },
      %Variation{
        id: :rtl,
        description: "Right-to-left: inside a `dir=\"rtl\"` container the arrow keys follow the reading direction.",
        template: """
        <div dir="rtl" class="flex h-96 justify-center p-4">
          <.navigation_menu id="navigation-menu-rtl" viewport={false}>
            <.navigation_menu_list>
              #{home_item()}
              #{components_item()}
              #{docs_item()}
            </.navigation_menu_list>
          </.navigation_menu>
        </div>
        """
      }
    ]
  end
end
