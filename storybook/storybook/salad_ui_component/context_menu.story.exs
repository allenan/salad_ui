defmodule Storybook.SaladUIComponents.ContextMenu do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.ContextMenu

  def function, do: &ContextMenu.context_menu/1

  def imports,
    do: [
      {ContextMenu,
       [
         context_menu_trigger: 1,
         context_menu_content: 1,
         context_menu_group: 1,
         context_menu_label: 1,
         context_menu_item: 1,
         context_menu_checkbox_item: 1,
         context_menu_radio_group: 1,
         context_menu_radio_item: 1,
         context_menu_sub: 1,
         context_menu_sub_trigger: 1,
         context_menu_sub_content: 1,
         context_menu_separator: 1,
         context_menu_shortcut: 1
       ]},
      {SaladStorybookWeb.CoreComponents, [icon: 1]}
    ]

  def descriptions do
    """
    Displays a menu of actions at the pointer, opened by a right click or, on
    touch devices, a long press. Items, checkbox and radio items and sub-menus
    work as in the dropdown menu.
    """
  end

  def variations do
    [
      %Variation{
        id: :demo,
        description: "A context menu with a sub-menu, shortcuts, checkbox items and a radio group (shadcn's demo).",
        template: """
        <div class="p-12 flex justify-center">
          <.context_menu id="context-menu-demo">
            <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
              <span class="hidden pointer-fine:inline-block">Right click here</span>
              <span class="hidden pointer-coarse:inline-block">Long press here</span>
            </.context_menu_trigger>
            <.context_menu_content class="w-48">
              <.context_menu_group>
                <.context_menu_item>
                  Back <.context_menu_shortcut>⌘[</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_item disabled>
                  Forward <.context_menu_shortcut>⌘]</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_item>
                  Reload <.context_menu_shortcut>⌘R</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_sub>
                  <.context_menu_sub_trigger>More Tools</.context_menu_sub_trigger>
                  <.context_menu_sub_content class="w-44">
                    <.context_menu_group>
                      <.context_menu_item>Save Page...</.context_menu_item>
                      <.context_menu_item>Create Shortcut...</.context_menu_item>
                      <.context_menu_item>Name Window...</.context_menu_item>
                    </.context_menu_group>
                    <.context_menu_separator />
                    <.context_menu_group>
                      <.context_menu_item>Developer Tools</.context_menu_item>
                    </.context_menu_group>
                    <.context_menu_separator />
                    <.context_menu_group>
                      <.context_menu_item variant="destructive">Delete</.context_menu_item>
                    </.context_menu_group>
                  </.context_menu_sub_content>
                </.context_menu_sub>
              </.context_menu_group>
              <.context_menu_separator />
              <.context_menu_group>
                <.context_menu_checkbox_item checked>Show Bookmarks</.context_menu_checkbox_item>
                <.context_menu_checkbox_item>Show Full URLs</.context_menu_checkbox_item>
              </.context_menu_group>
              <.context_menu_separator />
              <.context_menu_group>
                <.context_menu_radio_group value="pedro">
                  <.context_menu_label>People</.context_menu_label>
                  <.context_menu_radio_item value="pedro">Pedro Duarte</.context_menu_radio_item>
                  <.context_menu_radio_item value="colm">Colm Tuite</.context_menu_radio_item>
                </.context_menu_radio_group>
              </.context_menu_group>
            </.context_menu_content>
          </.context_menu>
        </div>
        """
      },
      %Variation{
        id: :basic,
        description: "A simple context menu with a few actions.",
        template: """
        <div class="p-12 flex justify-center">
          <.context_menu id="context-menu-basic">
            <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
              <span class="hidden pointer-fine:inline-block">Right click here</span>
              <span class="hidden pointer-coarse:inline-block">Long press here</span>
            </.context_menu_trigger>
            <.context_menu_content>
              <.context_menu_group>
                <.context_menu_item>Back</.context_menu_item>
                <.context_menu_item disabled>Forward</.context_menu_item>
                <.context_menu_item>Reload</.context_menu_item>
              </.context_menu_group>
            </.context_menu_content>
          </.context_menu>
        </div>
        """
      },
      %Variation{
        id: :submenu,
        description: "Use `context_menu_sub` to nest secondary actions.",
        template: """
        <div class="p-12 flex justify-center">
          <.context_menu id="context-menu-submenu">
            <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
              <span class="hidden pointer-fine:inline-block">Right click here</span>
              <span class="hidden pointer-coarse:inline-block">Long press here</span>
            </.context_menu_trigger>
            <.context_menu_content>
              <.context_menu_group>
                <.context_menu_item>
                  Copy <.context_menu_shortcut>⌘C</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_item>
                  Cut <.context_menu_shortcut>⌘X</.context_menu_shortcut>
                </.context_menu_item>
              </.context_menu_group>
              <.context_menu_sub>
                <.context_menu_sub_trigger>More Tools</.context_menu_sub_trigger>
                <.context_menu_sub_content>
                  <.context_menu_group>
                    <.context_menu_item>Save Page...</.context_menu_item>
                    <.context_menu_item>Create Shortcut...</.context_menu_item>
                    <.context_menu_item>Name Window...</.context_menu_item>
                  </.context_menu_group>
                  <.context_menu_separator />
                  <.context_menu_group>
                    <.context_menu_item>Developer Tools</.context_menu_item>
                  </.context_menu_group>
                  <.context_menu_separator />
                  <.context_menu_group>
                    <.context_menu_item variant="destructive">Delete</.context_menu_item>
                  </.context_menu_group>
                </.context_menu_sub_content>
              </.context_menu_sub>
            </.context_menu_content>
          </.context_menu>
        </div>
        """
      },
      %Variation{
        id: :shortcuts,
        description: "Add `context_menu_shortcut` to show keyboard hints.",
        template: """
        <div class="p-12 flex justify-center">
          <.context_menu id="context-menu-shortcuts">
            <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
              <span class="hidden pointer-fine:inline-block">Right click here</span>
              <span class="hidden pointer-coarse:inline-block">Long press here</span>
            </.context_menu_trigger>
            <.context_menu_content>
              <.context_menu_group>
                <.context_menu_item>
                  Back <.context_menu_shortcut>⌘[</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_item disabled>
                  Forward <.context_menu_shortcut>⌘]</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_item>
                  Reload <.context_menu_shortcut>⌘R</.context_menu_shortcut>
                </.context_menu_item>
              </.context_menu_group>
              <.context_menu_separator />
              <.context_menu_group>
                <.context_menu_item>
                  Save <.context_menu_shortcut>⌘S</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_item>
                  Save As... <.context_menu_shortcut>⇧⌘S</.context_menu_shortcut>
                </.context_menu_item>
              </.context_menu_group>
            </.context_menu_content>
          </.context_menu>
        </div>
        """
      },
      %Variation{
        id: :groups,
        description: "Group related actions and separate them with dividers.",
        template: """
        <div class="p-12 flex justify-center">
          <.context_menu id="context-menu-groups">
            <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
              <span class="hidden pointer-fine:inline-block">Right click here</span>
              <span class="hidden pointer-coarse:inline-block">Long press here</span>
            </.context_menu_trigger>
            <.context_menu_content>
              <.context_menu_group>
                <.context_menu_label>File</.context_menu_label>
                <.context_menu_item>
                  New File <.context_menu_shortcut>⌘N</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_item>
                  Open File <.context_menu_shortcut>⌘O</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_item>
                  Save <.context_menu_shortcut>⌘S</.context_menu_shortcut>
                </.context_menu_item>
              </.context_menu_group>
              <.context_menu_separator />
              <.context_menu_group>
                <.context_menu_label>Edit</.context_menu_label>
                <.context_menu_item>
                  Undo <.context_menu_shortcut>⌘Z</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_item>
                  Redo <.context_menu_shortcut>⇧⌘Z</.context_menu_shortcut>
                </.context_menu_item>
              </.context_menu_group>
              <.context_menu_separator />
              <.context_menu_group>
                <.context_menu_item>
                  Cut <.context_menu_shortcut>⌘X</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_item>
                  Copy <.context_menu_shortcut>⌘C</.context_menu_shortcut>
                </.context_menu_item>
                <.context_menu_item>
                  Paste <.context_menu_shortcut>⌘V</.context_menu_shortcut>
                </.context_menu_item>
              </.context_menu_group>
              <.context_menu_separator />
              <.context_menu_group>
                <.context_menu_item variant="destructive">
                  Delete <.context_menu_shortcut>⌫</.context_menu_shortcut>
                </.context_menu_item>
              </.context_menu_group>
            </.context_menu_content>
          </.context_menu>
        </div>
        """
      },
      %Variation{
        id: :icons,
        description: "Combine icons with labels for quick scanning.",
        template: """
        <div class="p-12 flex justify-center">
          <.context_menu id="context-menu-icons">
            <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
              <span class="hidden pointer-fine:inline-block">Right click here</span>
              <span class="hidden pointer-coarse:inline-block">Long press here</span>
            </.context_menu_trigger>
            <.context_menu_content>
              <.context_menu_group>
                <.context_menu_item><.icon name="hero-document-duplicate" class="size-4" /> Copy</.context_menu_item>
                <.context_menu_item><.icon name="hero-scissors" class="size-4" /> Cut</.context_menu_item>
                <.context_menu_item><.icon name="hero-clipboard" class="size-4" /> Paste</.context_menu_item>
              </.context_menu_group>
              <.context_menu_separator />
              <.context_menu_group>
                <.context_menu_item variant="destructive">
                  <.icon name="hero-trash" class="size-4" /> Delete
                </.context_menu_item>
              </.context_menu_group>
            </.context_menu_content>
          </.context_menu>
        </div>
        """
      },
      %Variation{
        id: :checkboxes,
        description: "Use `context_menu_checkbox_item` for toggles.",
        template: """
        <div class="p-12 flex justify-center">
          <.context_menu id="context-menu-checkboxes">
            <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
              <span class="hidden pointer-fine:inline-block">Right click here</span>
              <span class="hidden pointer-coarse:inline-block">Long press here</span>
            </.context_menu_trigger>
            <.context_menu_content>
              <.context_menu_group>
                <.context_menu_checkbox_item checked>Show Bookmarks Bar</.context_menu_checkbox_item>
                <.context_menu_checkbox_item>Show Full URLs</.context_menu_checkbox_item>
                <.context_menu_checkbox_item checked>Show Developer Tools</.context_menu_checkbox_item>
              </.context_menu_group>
            </.context_menu_content>
          </.context_menu>
        </div>
        """
      },
      %Variation{
        id: :radio,
        description: "Use `context_menu_radio_item` for exclusive choices.",
        template: """
        <div class="p-12 flex justify-center">
          <.context_menu id="context-menu-radio">
            <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
              <span class="hidden pointer-fine:inline-block">Right click here</span>
              <span class="hidden pointer-coarse:inline-block">Long press here</span>
            </.context_menu_trigger>
            <.context_menu_content>
              <.context_menu_group>
                <.context_menu_label>People</.context_menu_label>
                <.context_menu_radio_group value="pedro">
                  <.context_menu_radio_item value="pedro">Pedro Duarte</.context_menu_radio_item>
                  <.context_menu_radio_item value="colm">Colm Tuite</.context_menu_radio_item>
                </.context_menu_radio_group>
              </.context_menu_group>
              <.context_menu_separator />
              <.context_menu_group>
                <.context_menu_label>Theme</.context_menu_label>
                <.context_menu_radio_group value="light">
                  <.context_menu_radio_item value="light">Light</.context_menu_radio_item>
                  <.context_menu_radio_item value="dark">Dark</.context_menu_radio_item>
                  <.context_menu_radio_item value="system">System</.context_menu_radio_item>
                </.context_menu_radio_group>
              </.context_menu_group>
            </.context_menu_content>
          </.context_menu>
        </div>
        """
      },
      %Variation{
        id: :destructive,
        description: "Use `variant=\"destructive\"` to style the menu item as destructive.",
        template: """
        <div class="p-12 flex justify-center">
          <.context_menu id="context-menu-destructive">
            <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
              <span class="hidden pointer-fine:inline-block">Right click here</span>
              <span class="hidden pointer-coarse:inline-block">Long press here</span>
            </.context_menu_trigger>
            <.context_menu_content>
              <.context_menu_group>
                <.context_menu_item><.icon name="hero-pencil" class="size-4" /> Edit</.context_menu_item>
                <.context_menu_item><.icon name="hero-share" class="size-4" /> Share</.context_menu_item>
              </.context_menu_group>
              <.context_menu_separator />
              <.context_menu_group>
                <.context_menu_item variant="destructive">
                  <.icon name="hero-trash" class="size-4" /> Delete
                </.context_menu_item>
              </.context_menu_group>
            </.context_menu_content>
          </.context_menu>
        </div>
        """
      },
      %Variation{
        id: :sides,
        description: "Use `side` on `context_menu_content` to open the menu above, below or beside the pointer.",
        template: """
        <div class="p-12 flex justify-center">
          <div class="grid w-full max-w-sm grid-cols-2 gap-4">
            <.context_menu id="context-menu-side-top">
              <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
                <span class="hidden pointer-fine:inline-block">Right click (top)</span>
                <span class="hidden pointer-coarse:inline-block">Long press (top)</span>
              </.context_menu_trigger>
              <.context_menu_content side="top">
                <.context_menu_group>
                  <.context_menu_item>Back</.context_menu_item>
                  <.context_menu_item>Forward</.context_menu_item>
                  <.context_menu_item>Reload</.context_menu_item>
                </.context_menu_group>
              </.context_menu_content>
            </.context_menu>
            <.context_menu id="context-menu-side-right">
              <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
                <span class="hidden pointer-fine:inline-block">Right click (right)</span>
                <span class="hidden pointer-coarse:inline-block">Long press (right)</span>
              </.context_menu_trigger>
              <.context_menu_content side="right">
                <.context_menu_group>
                  <.context_menu_item>Back</.context_menu_item>
                  <.context_menu_item>Forward</.context_menu_item>
                  <.context_menu_item>Reload</.context_menu_item>
                </.context_menu_group>
              </.context_menu_content>
            </.context_menu>
            <.context_menu id="context-menu-side-bottom">
              <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
                <span class="hidden pointer-fine:inline-block">Right click (bottom)</span>
                <span class="hidden pointer-coarse:inline-block">Long press (bottom)</span>
              </.context_menu_trigger>
              <.context_menu_content side="bottom">
                <.context_menu_group>
                  <.context_menu_item>Back</.context_menu_item>
                  <.context_menu_item>Forward</.context_menu_item>
                  <.context_menu_item>Reload</.context_menu_item>
                </.context_menu_group>
              </.context_menu_content>
            </.context_menu>
            <.context_menu id="context-menu-side-left">
              <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
                <span class="hidden pointer-fine:inline-block">Right click (left)</span>
                <span class="hidden pointer-coarse:inline-block">Long press (left)</span>
              </.context_menu_trigger>
              <.context_menu_content side="left">
                <.context_menu_group>
                  <.context_menu_item>Back</.context_menu_item>
                  <.context_menu_item>Forward</.context_menu_item>
                  <.context_menu_item>Reload</.context_menu_item>
                </.context_menu_group>
              </.context_menu_content>
            </.context_menu>
          </div>
        </div>
        """
      },
      %Variation{
        id: :rtl,
        description: "Under `dir=\"rtl\"` the menu opens to the left of the pointer and sub-menus open leftwards.",
        template: """
        <div class="p-12 flex justify-center" dir="rtl">
          <.context_menu id="context-menu-rtl">
            <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
              <span class="hidden pointer-fine:inline-block">انقر بزر الماوس الأيمن هنا</span>
              <span class="hidden pointer-coarse:inline-block">اضغط مطولاً هنا</span>
            </.context_menu_trigger>
            <.context_menu_content class="w-48">
              <.context_menu_group>
                <.context_menu_label>التنقل</.context_menu_label>
                <.context_menu_item><.icon name="hero-arrow-right" class="size-4" /> رجوع</.context_menu_item>
                <.context_menu_item disabled><.icon name="hero-arrow-left" class="size-4" /> تقدم</.context_menu_item>
                <.context_menu_item><.icon name="hero-arrow-path" class="size-4" /> إعادة تحميل</.context_menu_item>
                <.context_menu_sub>
                  <.context_menu_sub_trigger>المزيد من الأدوات</.context_menu_sub_trigger>
                  <.context_menu_sub_content class="w-44">
                    <.context_menu_item>حفظ الصفحة...</.context_menu_item>
                    <.context_menu_item>إنشاء اختصار...</.context_menu_item>
                    <.context_menu_separator />
                    <.context_menu_item variant="destructive">حذف</.context_menu_item>
                  </.context_menu_sub_content>
                </.context_menu_sub>
              </.context_menu_group>
              <.context_menu_separator />
              <.context_menu_checkbox_item checked>إظهار الإشارات المرجعية</.context_menu_checkbox_item>
              <.context_menu_separator />
              <.context_menu_radio_group value="pedro">
                <.context_menu_label>الأشخاص</.context_menu_label>
                <.context_menu_radio_item value="pedro">Pedro Duarte</.context_menu_radio_item>
                <.context_menu_radio_item value="colm">Colm Tuite</.context_menu_radio_item>
              </.context_menu_radio_group>
            </.context_menu_content>
          </.context_menu>
        </div>
        """
      }
    ]
  end
end
