defmodule Storybook.SaladUIComponents.Direction do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Direction

  def function, do: &Direction.direction_provider/1

  def layout, do: :one_column

  def imports,
    do: [
      {SaladUI.Button, [button: 1]},
      {SaladUI.Card,
       [card: 1, card_header: 1, card_title: 1, card_description: 1, card_action: 1, card_content: 1, card_footer: 1]},
      {SaladUI.Input, [input: 1]},
      {SaladUI.Label, [label: 1]},
      {SaladUI.Popover,
       [popover: 1, popover_trigger: 1, popover_content: 1, popover_header: 1, popover_title: 1, popover_description: 1]},
      {SaladUI.DropdownMenu,
       [
         dropdown_menu: 1,
         dropdown_menu_trigger: 1,
         dropdown_menu_content: 1,
         dropdown_menu_label: 1,
         dropdown_menu_group: 1,
         dropdown_menu_item: 1,
         dropdown_menu_shortcut: 1,
         dropdown_menu_separator: 1,
         dropdown_menu_sub: 1,
         dropdown_menu_sub_trigger: 1,
         dropdown_menu_sub_content: 1
       ]},
      {SaladUI.Menubar,
       [
         menubar: 1,
         menubar_menu: 1,
         menubar_trigger: 1,
         menubar_content: 1,
         menubar_item: 1,
         menubar_separator: 1,
         menubar_shortcut: 1,
         menubar_sub: 1,
         menubar_sub_trigger: 1,
         menubar_sub_content: 1
       ]},
      {SaladUI.Tabs, [tabs: 1, tabs_list: 1, tabs_trigger: 1, tabs_content: 1]},
      {SaladUI.RadioGroup, [radio_group: 1, radio_group_item: 1]},
      {SaladUI.Slider, [slider: 1]},
      {SaladUI.Helpers, [as_child: 1]}
    ]

  def descriptions do
    """
    Sets the reading direction for a subtree (`<html dir="rtl">` does the same
    for a whole page). Use the LTR/RTL switch at the bottom-left of the
    storybook to flip every other story.
    """
  end

  def variations do
    [
      %Variation{
        id: :card_rtl,
        description: "shadcn's card-rtl preview: an Arabic login card",
        template: """
        <.direction_provider direction="rtl">
          <.card class="w-full max-w-sm">
            <.card_header>
              <.card_title>تسجيل الدخول إلى حسابك</.card_title>
              <.card_description>أدخل بريدك الإلكتروني أدناه لتسجيل الدخول إلى حسابك</.card_description>
              <.card_action>
                <.button variant="link">إنشاء حساب</.button>
              </.card_action>
            </.card_header>
            <.card_content>
              <form>
                <div class="flex flex-col gap-6">
                  <div class="grid gap-2">
                    <.label for="email-rtl">البريد الإلكتروني</.label>
                    <.input id="email-rtl" type="email" placeholder="m@example.com" required />
                  </div>
                  <div class="grid gap-2">
                    <div class="flex items-center">
                      <.label for="password-rtl">كلمة المرور</.label>
                      <a href="#" class="ms-auto inline-block text-sm underline-offset-4 hover:underline">
                        نسيت كلمة المرور؟
                      </a>
                    </div>
                    <.input id="password-rtl" type="password" required />
                  </div>
                </div>
              </form>
            </.card_content>
            <.card_footer class="flex-col gap-2">
              <.button type="submit" class="w-full">تسجيل الدخول</.button>
              <.button variant="outline" class="w-full">تسجيل الدخول باستخدام Google</.button>
            </.card_footer>
          </.card>
        </.direction_provider>
        """
      },
      %Variation{
        id: :popover_rtl,
        description: "Popovers: sides stay physical, align=\"start\" lines up with the trigger's right edge",
        template: """
        <.direction_provider direction="rtl">
          <div class="flex flex-wrap justify-center gap-2 py-16">
            <.popover :for={{side, text} <- [{"left", "يسار"}, {"top", "أعلى"}, {"bottom", "أسفل"}, {"right", "يمين"}]} id={"popover-rtl-" <> side}>
              <.popover_trigger as={&button/1} variant="outline">{text}</.popover_trigger>
              <.popover_content side={side} align="start" class="w-64">
                <.popover_header>
                  <.popover_title>الأبعاد</.popover_title>
                  <.popover_description>تعيين الأبعاد للطبقة.</.popover_description>
                </.popover_header>
              </.popover_content>
            </.popover>
          </div>
        </.direction_provider>
        """
      },
      %Variation{
        id: :dropdown_menu_rtl,
        description: "Dropdown menu: the sub-menu opens to the left; ArrowLeft opens it, ArrowRight closes it",
        template: """
        <.direction_provider direction="rtl">
          <div class="flex justify-center p-24">
            <.dropdown_menu id="dropdown-rtl">
              <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">فتح</.as_child>
              <.dropdown_menu_content class="w-56" align="start">
                <.dropdown_menu_label>حسابي</.dropdown_menu_label>
                <.dropdown_menu_group>
                  <.dropdown_menu_item>الملف الشخصي <.dropdown_menu_shortcut>⇧⌘P</.dropdown_menu_shortcut></.dropdown_menu_item>
                  <.dropdown_menu_item>الفوترة <.dropdown_menu_shortcut>⌘B</.dropdown_menu_shortcut></.dropdown_menu_item>
                </.dropdown_menu_group>
                <.dropdown_menu_separator />
                <.dropdown_menu_sub>
                  <.dropdown_menu_sub_trigger>دعوة المستخدمين</.dropdown_menu_sub_trigger>
                  <.dropdown_menu_sub_content>
                    <.dropdown_menu_item>البريد الإلكتروني</.dropdown_menu_item>
                    <.dropdown_menu_item>رسالة</.dropdown_menu_item>
                  </.dropdown_menu_sub_content>
                </.dropdown_menu_sub>
                <.dropdown_menu_separator />
                <.dropdown_menu_item>تسجيل الخروج</.dropdown_menu_item>
              </.dropdown_menu_content>
            </.dropdown_menu>
          </div>
        </.direction_provider>
        """
      },
      %Variation{
        id: :menubar_rtl,
        description: "Menubar: ArrowLeft moves to the next menu; sub-menus open to the left",
        template: """
        <.direction_provider direction="rtl">
          <div class="flex justify-center p-12 pb-64">
            <.menubar id="menubar-rtl" class="w-72">
              <.menubar_menu value="file">
                <.menubar_trigger>ملف</.menubar_trigger>
                <.menubar_content>
                  <.menubar_item>علامة تبويب جديدة <.menubar_shortcut>⌘T</.menubar_shortcut></.menubar_item>
                  <.menubar_separator />
                  <.menubar_sub>
                    <.menubar_sub_trigger>مشاركة</.menubar_sub_trigger>
                    <.menubar_sub_content>
                      <.menubar_item>رابط البريد الإلكتروني</.menubar_item>
                      <.menubar_item>الرسائل</.menubar_item>
                    </.menubar_sub_content>
                  </.menubar_sub>
                </.menubar_content>
              </.menubar_menu>
              <.menubar_menu value="edit">
                <.menubar_trigger>تحرير</.menubar_trigger>
                <.menubar_content>
                  <.menubar_item>تراجع <.menubar_shortcut>⌘Z</.menubar_shortcut></.menubar_item>
                  <.menubar_item>إعادة <.menubar_shortcut>⇧⌘Z</.menubar_shortcut></.menubar_item>
                </.menubar_content>
              </.menubar_menu>
            </.menubar>
          </div>
        </.direction_provider>
        """
      },
      %Variation{
        id: :keyboard_rtl,
        description: "Tabs, radio group and slider: ArrowLeft moves forward; the slider starts at the right",
        template: """
        <.direction_provider direction="rtl">
          <div class="mx-auto grid w-full max-w-sm gap-8">
            <.tabs id="tabs-rtl" default="account">
              <.tabs_list>
                <.tabs_trigger value="account">الحساب</.tabs_trigger>
                <.tabs_trigger value="password">كلمة المرور</.tabs_trigger>
                <.tabs_trigger value="billing">الفوترة</.tabs_trigger>
              </.tabs_list>
              <.tabs_content value="account" class="text-sm">إعدادات الحساب.</.tabs_content>
              <.tabs_content value="password" class="text-sm">تغيير كلمة المرور.</.tabs_content>
              <.tabs_content value="billing" class="text-sm">معلومات الفوترة.</.tabs_content>
            </.tabs>
            <.radio_group id="radio-rtl" name="plan-rtl" default-value="comfortable" class="flex gap-6">
              <div :for={{value, text} <- [{"default", "افتراضي"}, {"comfortable", "مريح"}, {"compact", "مضغوط"}]} class="flex items-center gap-2">
                <.radio_group_item value={value} id={"radio-rtl-" <> value} />
                <.label for={"radio-rtl-" <> value}>{text}</.label>
              </div>
            </.radio_group>
            <.slider id="slider-rtl" value={[25, 75]} max={100} step={1} name="slider-rtl" />
          </div>
        </.direction_provider>
        """
      }
    ]
  end
end
