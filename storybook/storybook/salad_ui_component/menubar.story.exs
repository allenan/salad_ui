defmodule Storybook.SaladUIComponents.Menubar do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Menubar

  def function, do: &Menubar.menubar/1

  def imports,
    do: [
      {Menubar,
       [
         menubar_menu: 1,
         menubar_trigger: 1,
         menubar_content: 1,
         menubar_group: 1,
         menubar_label: 1,
         menubar_item: 1,
         menubar_checkbox_item: 1,
         menubar_radio_group: 1,
         menubar_radio_item: 1,
         menubar_sub: 1,
         menubar_sub_trigger: 1,
         menubar_sub_content: 1,
         menubar_separator: 1,
         menubar_shortcut: 1
       ]},
      {SaladStorybookWeb.CoreComponents, [icon: 1]}
    ]

  def descriptions do
    """
    A visually persistent menu common in desktop applications. Click a trigger
    to open its menu; while one is open, hovering another trigger switches to
    it. `ArrowLeft`/`ArrowRight` move between menus, `ArrowDown` opens one.
    """
  end

  def variations do
    [
      %Variation{
        id: :demo,
        description: "shadcn's demo: shortcuts, sub-menus, checkbox items, inset items and a radio group.",
        template: """
        <div class="p-12 pb-80 flex justify-center">
          <.menubar id="menubar-demo" class="w-72">
            <.menubar_menu value="file">
              <.menubar_trigger>File</.menubar_trigger>
              <.menubar_content>
                <.menubar_group>
                  <.menubar_item>New Tab <.menubar_shortcut>⌘T</.menubar_shortcut></.menubar_item>
                  <.menubar_item>New Window <.menubar_shortcut>⌘N</.menubar_shortcut></.menubar_item>
                  <.menubar_item disabled>New Incognito Window</.menubar_item>
                </.menubar_group>
                <.menubar_separator />
                <.menubar_group>
                  <.menubar_sub>
                    <.menubar_sub_trigger>Share</.menubar_sub_trigger>
                    <.menubar_sub_content>
                      <.menubar_group>
                        <.menubar_item>Email link</.menubar_item>
                        <.menubar_item>Messages</.menubar_item>
                        <.menubar_item>Notes</.menubar_item>
                      </.menubar_group>
                    </.menubar_sub_content>
                  </.menubar_sub>
                </.menubar_group>
                <.menubar_separator />
                <.menubar_group>
                  <.menubar_item>Print... <.menubar_shortcut>⌘P</.menubar_shortcut></.menubar_item>
                </.menubar_group>
              </.menubar_content>
            </.menubar_menu>
            <.menubar_menu value="edit">
              <.menubar_trigger>Edit</.menubar_trigger>
              <.menubar_content>
                <.menubar_group>
                  <.menubar_item>Undo <.menubar_shortcut>⌘Z</.menubar_shortcut></.menubar_item>
                  <.menubar_item>Redo <.menubar_shortcut>⇧⌘Z</.menubar_shortcut></.menubar_item>
                </.menubar_group>
                <.menubar_separator />
                <.menubar_group>
                  <.menubar_sub>
                    <.menubar_sub_trigger>Find</.menubar_sub_trigger>
                    <.menubar_sub_content>
                      <.menubar_group>
                        <.menubar_item>Search the web</.menubar_item>
                      </.menubar_group>
                      <.menubar_separator />
                      <.menubar_group>
                        <.menubar_item>Find...</.menubar_item>
                        <.menubar_item>Find Next</.menubar_item>
                        <.menubar_item>Find Previous</.menubar_item>
                      </.menubar_group>
                    </.menubar_sub_content>
                  </.menubar_sub>
                </.menubar_group>
                <.menubar_separator />
                <.menubar_group>
                  <.menubar_item>Cut</.menubar_item>
                  <.menubar_item>Copy</.menubar_item>
                  <.menubar_item>Paste</.menubar_item>
                </.menubar_group>
              </.menubar_content>
            </.menubar_menu>
            <.menubar_menu value="view">
              <.menubar_trigger>View</.menubar_trigger>
              <.menubar_content class="w-44">
                <.menubar_group>
                  <.menubar_checkbox_item>Bookmarks Bar</.menubar_checkbox_item>
                  <.menubar_checkbox_item checked>Full URLs</.menubar_checkbox_item>
                </.menubar_group>
                <.menubar_separator />
                <.menubar_group>
                  <.menubar_item inset>Reload <.menubar_shortcut>⌘R</.menubar_shortcut></.menubar_item>
                  <.menubar_item disabled inset>
                    Force Reload <.menubar_shortcut>⇧⌘R</.menubar_shortcut>
                  </.menubar_item>
                </.menubar_group>
                <.menubar_separator />
                <.menubar_group>
                  <.menubar_item inset>Toggle Fullscreen</.menubar_item>
                </.menubar_group>
                <.menubar_separator />
                <.menubar_group>
                  <.menubar_item inset>Hide Sidebar</.menubar_item>
                </.menubar_group>
              </.menubar_content>
            </.menubar_menu>
            <.menubar_menu value="profiles">
              <.menubar_trigger>Profiles</.menubar_trigger>
              <.menubar_content>
                <.menubar_radio_group value="benoit">
                  <.menubar_radio_item value="andy">Andy</.menubar_radio_item>
                  <.menubar_radio_item value="benoit">Benoit</.menubar_radio_item>
                  <.menubar_radio_item value="Luis">Luis</.menubar_radio_item>
                </.menubar_radio_group>
                <.menubar_separator />
                <.menubar_group>
                  <.menubar_item inset>Edit...</.menubar_item>
                </.menubar_group>
                <.menubar_separator />
                <.menubar_group>
                  <.menubar_item inset>Add Profile...</.menubar_item>
                </.menubar_group>
              </.menubar_content>
            </.menubar_menu>
          </.menubar>
        </div>
        """
      },
      %Variation{
        id: :checkbox,
        description: "Use `menubar_checkbox_item` for toggleable options.",
        template: """
        <div class="p-12 pb-64 flex justify-center">
          <.menubar id="menubar-checkbox" class="w-72">
            <.menubar_menu value="view">
              <.menubar_trigger>View</.menubar_trigger>
              <.menubar_content class="w-64">
                <.menubar_checkbox_item>Always Show Bookmarks Bar</.menubar_checkbox_item>
                <.menubar_checkbox_item checked>Always Show Full URLs</.menubar_checkbox_item>
                <.menubar_separator />
                <.menubar_item inset>Reload <.menubar_shortcut>⌘R</.menubar_shortcut></.menubar_item>
                <.menubar_item disabled inset>
                  Force Reload <.menubar_shortcut>⇧⌘R</.menubar_shortcut>
                </.menubar_item>
              </.menubar_content>
            </.menubar_menu>
            <.menubar_menu value="format">
              <.menubar_trigger>Format</.menubar_trigger>
              <.menubar_content>
                <.menubar_checkbox_item checked>Strikethrough</.menubar_checkbox_item>
                <.menubar_checkbox_item>Code</.menubar_checkbox_item>
                <.menubar_checkbox_item>Superscript</.menubar_checkbox_item>
              </.menubar_content>
            </.menubar_menu>
          </.menubar>
        </div>
        """
      },
      %Variation{
        id: :radio,
        description: "Use `menubar_radio_group` and `menubar_radio_item` for single-select options.",
        template: """
        <div class="p-12 pb-64 flex justify-center">
          <.menubar id="menubar-radio" class="w-72">
            <.menubar_menu value="profiles">
              <.menubar_trigger>Profiles</.menubar_trigger>
              <.menubar_content>
                <.menubar_radio_group value="benoit">
                  <.menubar_radio_item value="andy">Andy</.menubar_radio_item>
                  <.menubar_radio_item value="benoit">Benoit</.menubar_radio_item>
                  <.menubar_radio_item value="luis">Luis</.menubar_radio_item>
                </.menubar_radio_group>
                <.menubar_separator />
                <.menubar_item inset>Edit...</.menubar_item>
                <.menubar_item inset>Add Profile...</.menubar_item>
              </.menubar_content>
            </.menubar_menu>
            <.menubar_menu value="theme">
              <.menubar_trigger>Theme</.menubar_trigger>
              <.menubar_content>
                <.menubar_radio_group value="system">
                  <.menubar_radio_item value="light">Light</.menubar_radio_item>
                  <.menubar_radio_item value="dark">Dark</.menubar_radio_item>
                  <.menubar_radio_item value="system">System</.menubar_radio_item>
                </.menubar_radio_group>
              </.menubar_content>
            </.menubar_menu>
          </.menubar>
        </div>
        """
      },
      %Variation{
        id: :submenu,
        description: "Use `menubar_sub`, `menubar_sub_trigger` and `menubar_sub_content` for nested menus.",
        template: """
        <div class="p-12 pb-72 flex justify-center">
          <.menubar id="menubar-submenu" class="w-72">
            <.menubar_menu value="file">
              <.menubar_trigger>File</.menubar_trigger>
              <.menubar_content>
                <.menubar_sub>
                  <.menubar_sub_trigger>Share</.menubar_sub_trigger>
                  <.menubar_sub_content>
                    <.menubar_item>Email link</.menubar_item>
                    <.menubar_item>Messages</.menubar_item>
                    <.menubar_item>Notes</.menubar_item>
                  </.menubar_sub_content>
                </.menubar_sub>
                <.menubar_separator />
                <.menubar_item>Print... <.menubar_shortcut>⌘P</.menubar_shortcut></.menubar_item>
              </.menubar_content>
            </.menubar_menu>
            <.menubar_menu value="edit">
              <.menubar_trigger>Edit</.menubar_trigger>
              <.menubar_content>
                <.menubar_item>Undo <.menubar_shortcut>⌘Z</.menubar_shortcut></.menubar_item>
                <.menubar_item>Redo <.menubar_shortcut>⇧⌘Z</.menubar_shortcut></.menubar_item>
                <.menubar_separator />
                <.menubar_sub>
                  <.menubar_sub_trigger>Find</.menubar_sub_trigger>
                  <.menubar_sub_content>
                    <.menubar_item>Find...</.menubar_item>
                    <.menubar_item>Find Next</.menubar_item>
                    <.menubar_item>Find Previous</.menubar_item>
                  </.menubar_sub_content>
                </.menubar_sub>
                <.menubar_separator />
                <.menubar_item>Cut</.menubar_item>
                <.menubar_item>Copy</.menubar_item>
                <.menubar_item>Paste</.menubar_item>
              </.menubar_content>
            </.menubar_menu>
          </.menubar>
        </div>
        """
      },
      %Variation{
        id: :icons,
        description: "Icons next to item labels.",
        template: """
        <div class="p-12 pb-64 flex justify-center">
          <.menubar id="menubar-icons" class="w-72">
            <.menubar_menu value="file">
              <.menubar_trigger>File</.menubar_trigger>
              <.menubar_content>
                <.menubar_item>
                  <.icon name="hero-document" class="size-4" /> New File
                  <.menubar_shortcut>⌘N</.menubar_shortcut>
                </.menubar_item>
                <.menubar_item><.icon name="hero-folder" class="size-4" /> Open Folder</.menubar_item>
                <.menubar_separator />
                <.menubar_item>
                  <.icon name="hero-arrow-down-tray" class="size-4" /> Save
                  <.menubar_shortcut>⌘S</.menubar_shortcut>
                </.menubar_item>
              </.menubar_content>
            </.menubar_menu>
            <.menubar_menu value="more">
              <.menubar_trigger>More</.menubar_trigger>
              <.menubar_content>
                <.menubar_group>
                  <.menubar_item><.icon name="hero-cog-6-tooth" class="size-4" /> Settings</.menubar_item>
                  <.menubar_item><.icon name="hero-question-mark-circle" class="size-4" /> Help</.menubar_item>
                  <.menubar_separator />
                  <.menubar_item variant="destructive">
                    <.icon name="hero-trash" class="size-4" /> Delete
                  </.menubar_item>
                </.menubar_group>
              </.menubar_content>
            </.menubar_menu>
          </.menubar>
        </div>
        """
      },
      %Variation{
        id: :rtl,
        description: "Under `dir=\"rtl\"` the arrow keys and sub-menus are mirrored.",
        template: """
        <div class="p-12 pb-72 flex justify-center" dir="rtl">
          <.menubar id="menubar-rtl" class="w-72">
            <.menubar_menu value="file">
              <.menubar_trigger>ملف</.menubar_trigger>
              <.menubar_content>
                <.menubar_group>
                  <.menubar_item>علامة تبويب جديدة <.menubar_shortcut>⌘T</.menubar_shortcut></.menubar_item>
                  <.menubar_item>نافذة جديدة <.menubar_shortcut>⌘N</.menubar_shortcut></.menubar_item>
                  <.menubar_item disabled>نافذة خاصة جديدة</.menubar_item>
                </.menubar_group>
                <.menubar_separator />
                <.menubar_sub>
                  <.menubar_sub_trigger>مشاركة</.menubar_sub_trigger>
                  <.menubar_sub_content>
                    <.menubar_item>رابط البريد الإلكتروني</.menubar_item>
                    <.menubar_item>الرسائل</.menubar_item>
                    <.menubar_item>الملاحظات</.menubar_item>
                  </.menubar_sub_content>
                </.menubar_sub>
                <.menubar_separator />
                <.menubar_item>طباعة... <.menubar_shortcut>⌘P</.menubar_shortcut></.menubar_item>
              </.menubar_content>
            </.menubar_menu>
            <.menubar_menu value="edit">
              <.menubar_trigger>تعديل</.menubar_trigger>
              <.menubar_content>
                <.menubar_item>تراجع <.menubar_shortcut>⌘Z</.menubar_shortcut></.menubar_item>
                <.menubar_item>إعادة <.menubar_shortcut>⇧⌘Z</.menubar_shortcut></.menubar_item>
                <.menubar_separator />
                <.menubar_item>قص</.menubar_item>
                <.menubar_item>نسخ</.menubar_item>
                <.menubar_item>لصق</.menubar_item>
              </.menubar_content>
            </.menubar_menu>
            <.menubar_menu value="view">
              <.menubar_trigger>عرض</.menubar_trigger>
              <.menubar_content class="w-44">
                <.menubar_checkbox_item>شريط الإشارات</.menubar_checkbox_item>
                <.menubar_checkbox_item checked>عناوين URL الكاملة</.menubar_checkbox_item>
                <.menubar_separator />
                <.menubar_radio_group value="benoit">
                  <.menubar_radio_item value="andy">Andy</.menubar_radio_item>
                  <.menubar_radio_item value="benoit">Benoit</.menubar_radio_item>
                </.menubar_radio_group>
              </.menubar_content>
            </.menubar_menu>
          </.menubar>
        </div>
        """
      }
    ]
  end
end
