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
      {SaladUI.Switch, [switch: 1]},
      {SaladUI.Helpers, [as_child: 1]},
      {SaladUI.Dialog,
       [
         dialog: 1,
         dialog_trigger: 1,
         dialog_content: 1,
         dialog_header: 1,
         dialog_title: 1,
         dialog_description: 1,
         dialog_footer: 1,
         dialog_close: 1
       ]},
      {SaladUI.Sheet,
       [
         sheet: 1,
         sheet_trigger: 1,
         sheet_content: 1,
         sheet_header: 1,
         sheet_title: 1,
         sheet_description: 1,
         sheet_footer: 1,
         sheet_close: 1
       ]},
      {SaladUI.InputGroup,
       [input_group: 1, input_group_input: 1, input_group_addon: 1, input_group_text: 1, input_group_button: 1]},
      {SaladUI.NavigationMenu,
       [
         navigation_menu: 1,
         navigation_menu_list: 1,
         navigation_menu_item: 1,
         navigation_menu_trigger: 1,
         navigation_menu_content: 1,
         navigation_menu_link: 1,
         navigation_menu_trigger_style: 0
       ]},
      {SaladUI.Sidebar,
       [
         sidebar_provider: 1,
         sidebar: 1,
         sidebar_content: 1,
         sidebar_group: 1,
         sidebar_group_label: 1,
         sidebar_group_action: 1,
         sidebar_group_content: 1,
         sidebar_menu: 1,
         sidebar_menu_item: 1,
         sidebar_menu_button: 1,
         sidebar_menu_action: 1,
         sidebar_menu_badge: 1,
         sidebar_menu_sub: 1,
         sidebar_menu_sub_item: 1,
         sidebar_menu_sub_button: 1,
         sidebar_rail: 1,
         sidebar_inset: 1,
         sidebar_trigger: 1
       ]},
      {SaladUI.Pagination,
       [
         pagination: 1,
         pagination_content: 1,
         pagination_item: 1,
         pagination_link: 1,
         pagination_previous: 1,
         pagination_next: 1,
         pagination_ellipsis: 1
       ]},
      {SaladUI.Toast, [toaster: 1]}
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
      },
      %Variation{
        id: :dialog_sheet_rtl,
        description:
          "Dialog and sheet: the close button sits at the top-left (inline end) and text aligns to the right. " <>
            "The sheet's `side` is physical, so an RTL page picks `side=\"left\"`, as shadcn's sheet-rtl does.",
        template: """
        <.direction_provider direction="rtl">
          <div class="flex justify-center gap-2">
            <.dialog id="dialog-rtl">
              <.dialog_trigger>
                <.button variant="outline">مشاركة</.button>
              </.dialog_trigger>
              <.dialog_content class="sm:max-w-md">
                <.dialog_header>
                  <.dialog_title>مشاركة الرابط</.dialog_title>
                  <.dialog_description>يمكن لأي شخص لديه هذا الرابط عرض هذا المحتوى.</.dialog_description>
                </.dialog_header>
                <.input id="dialog-rtl-link" value="https://ui.shadcn.com/docs/installation" readonly />
                <.dialog_footer>
                  <.dialog_close>
                    <.button type="button" variant="outline">إغلاق</.button>
                  </.dialog_close>
                </.dialog_footer>
              </.dialog_content>
            </.dialog>
            <.sheet id="sheet-rtl">
              <.sheet_trigger>
                <.button variant="outline">فتح</.button>
              </.sheet_trigger>
              <.sheet_content side="left">
                <.sheet_header>
                  <.sheet_title>تعديل الملف الشخصي</.sheet_title>
                  <.sheet_description>قم بإجراء تغييرات على ملفك الشخصي هنا.</.sheet_description>
                </.sheet_header>
                <div class="grid flex-1 auto-rows-min gap-6 px-4">
                  <div class="grid gap-3">
                    <.label for="sheet-rtl-name">الاسم</.label>
                    <.input id="sheet-rtl-name" value="بيدرو دوارتي" />
                  </div>
                </div>
                <.sheet_footer>
                  <.button type="submit">حفظ التغييرات</.button>
                  <.sheet_close>
                    <.button variant="outline" class="w-full">إغلاق</.button>
                  </.sheet_close>
                </.sheet_footer>
              </.sheet_content>
            </.sheet>
          </div>
        </.direction_provider>
        """
      },
      %Variation{
        id: :input_group_rtl,
        description:
          "Input group: `inline-start` addons sit on the right, `inline-end` on the left; the input's padding follows.",
        template: """
        <.direction_provider direction="rtl">
          <div class="mx-auto grid w-full max-w-sm gap-6">
            <.input_group id="ig-rtl-search">
              <.input_group_input placeholder="بحث..." />
              <.input_group_addon>
                <Lucideicons.search />
              </.input_group_addon>
              <.input_group_addon align="inline-end">١٢ نتيجة</.input_group_addon>
            </.input_group>
            <.input_group id="ig-rtl-copy">
              <.input_group_input value="https://example.com" readonly />
              <.input_group_addon align="inline-end">
                <.input_group_button size="icon-xs" aria-label="نسخ">
                  <Lucideicons.copy />
                </.input_group_button>
              </.input_group_addon>
            </.input_group>
            <div class="flex items-center gap-2">
              <.switch id="switch-rtl" checked />
              <.label for="switch-rtl">وضع الطيران</.label>
            </div>
          </div>
        </.direction_provider>
        """
      },
      %Variation{
        id: :navigation_menu_rtl,
        description:
          "Navigation menu: ArrowLeft moves to the next item; the shared viewport lines up with the right edge.",
        template: """
        <.direction_provider direction="rtl">
          <div class="flex h-80 justify-center p-4">
            <.navigation_menu id="navigation-menu-rtl">
              <.navigation_menu_list>
                <.navigation_menu_item value="start">
                  <.navigation_menu_trigger>البداية</.navigation_menu_trigger>
                  <.navigation_menu_content>
                    <ul class="grid w-[300px] gap-2">
                      <li :for={{title, text} <- [{"مقدمة", "مكونات قابلة لإعادة الاستخدام."}, {"التثبيت", "كيفية تثبيت التبعيات."}]}>
                        <.navigation_menu_link href="#">
                          <div class="text-sm leading-none font-medium">{title}</div>
                          <p class="line-clamp-2 text-sm leading-snug text-muted-foreground">{text}</p>
                        </.navigation_menu_link>
                      </li>
                    </ul>
                  </.navigation_menu_content>
                </.navigation_menu_item>
                <.navigation_menu_item value="components">
                  <.navigation_menu_trigger>المكونات</.navigation_menu_trigger>
                  <.navigation_menu_content>
                    <ul class="grid w-[400px] grid-cols-2 gap-2">
                      <li :for={title <- ["حوار التنبيه", "بطاقة التمرير", "التقدم", "منطقة التمرير"]}>
                        <.navigation_menu_link href="#">
                          <div class="text-sm leading-none font-medium">{title}</div>
                        </.navigation_menu_link>
                      </li>
                    </ul>
                  </.navigation_menu_content>
                </.navigation_menu_item>
                <.navigation_menu_item>
                  <.navigation_menu_link href="#" class={navigation_menu_trigger_style()}>الوثائق</.navigation_menu_link>
                </.navigation_menu_item>
              </.navigation_menu_list>
            </.navigation_menu>
          </div>
        </.direction_provider>
        """
      },
      %Variation{
        id: :sidebar_rtl,
        description:
          "Sidebar: `side` is physical, so an RTL page uses `side=\"right\"`. Badges, actions and the " <>
            "sub-menu line sit on the inline end/start; the trigger icon flips.",
        template: """
        <.direction_provider direction="rtl">
          <div class="relative h-[420px] w-full overflow-hidden rounded-lg border [transform:translateZ(0)]">
            <.sidebar_provider id="sidebar-rtl" class="h-full min-h-0" keyboard_shortcut={false} cookie={nil}>
              <.sidebar id="sidebar-rtl-sb" side="right" collapsible="icon" class="h-full">
                <.sidebar_content>
                  <.sidebar_group>
                    <.sidebar_group_label>التطبيق</.sidebar_group_label>
                    <.sidebar_group_action title="إضافة مشروع"><Lucideicons.plus /></.sidebar_group_action>
                    <.sidebar_group_content>
                      <.sidebar_menu>
                        <.sidebar_menu_item>
                          <.sidebar_menu_button as="a" href="#" is_active tooltip="الرئيسية">
                            <Lucideicons.home /> <span>الرئيسية</span>
                          </.sidebar_menu_button>
                          <.sidebar_menu_badge>٢٤</.sidebar_menu_badge>
                        </.sidebar_menu_item>
                        <.sidebar_menu_item>
                          <.sidebar_menu_button as="a" href="#" tooltip="البريد">
                            <Lucideicons.inbox /> <span>البريد</span>
                          </.sidebar_menu_button>
                          <.sidebar_menu_action><Lucideicons.ellipsis /></.sidebar_menu_action>
                          <.sidebar_menu_sub>
                            <.sidebar_menu_sub_item>
                              <.sidebar_menu_sub_button href="#">الوارد</.sidebar_menu_sub_button>
                            </.sidebar_menu_sub_item>
                            <.sidebar_menu_sub_item>
                              <.sidebar_menu_sub_button href="#">المؤرشف</.sidebar_menu_sub_button>
                            </.sidebar_menu_sub_item>
                          </.sidebar_menu_sub>
                        </.sidebar_menu_item>
                        <.sidebar_menu_item>
                          <.sidebar_menu_button as="a" href="#" tooltip="الإعدادات">
                            <Lucideicons.settings /> <span>الإعدادات</span>
                          </.sidebar_menu_button>
                        </.sidebar_menu_item>
                      </.sidebar_menu>
                    </.sidebar_group_content>
                  </.sidebar_group>
                </.sidebar_content>
                <.sidebar_rail />
              </.sidebar>
              <.sidebar_inset class="min-h-0">
                <header class="flex h-12 shrink-0 items-center gap-2 border-b px-4">
                  <.sidebar_trigger class="-ms-1" />
                  <span class="text-sm text-muted-foreground">لوحة التحكم</span>
                </header>
              </.sidebar_inset>
            </.sidebar_provider>
          </div>
        </.direction_provider>
        """
      },
      %Variation{
        id: :slider_rtl,
        description:
          "Sliders that only inherit RTL: the server-rendered thumbs already start at the right " <>
            "(logical insets), so nothing jumps when the hook mounts.",
        template: """
        <.direction_provider direction="rtl">
          <div class="mx-auto grid w-full max-w-sm gap-8">
            <.slider id="slider-rtl-single" value={30} max={100} step={1} aria-label="الصوت" />
            <.slider id="slider-rtl-range" value={[20, 60]} max={100} step={5} />
            <.slider id="slider-rtl-inverted" value={30} max={100} step={1} inverted aria-label="معكوس" />
          </div>
        </.direction_provider>
        """
      },
      %Variation{
        id: :toast_rtl,
        description:
          "Toast: positions stay physical, as in Sonner. `swipe-direction=\"end\"` dismisses towards the end of " <>
            "the line: to the left here. The close button sits on the card's inline-end corner.",
        template: """
        <.direction_provider direction="rtl">
          <.toaster id="toaster-rtl" position="bottom-center" swipe-direction="end" />
          <.button
            variant="outline"
            phx-click={
              SaladUI.JS.dispatch_command("add",
                to: "#toaster-rtl",
                detail: %{
                  title: "تم إنشاء الحدث",
                  description: "الأحد، ٣ ديسمبر ٢٠٢٣ الساعة ٩:٠٠ صباحًا",
                  action: %{label: "تراجع"}
                }
              )
            }
          >
            إظهار الإشعار
          </.button>
        </.direction_provider>
        """
      },
      %Variation{
        id: :pagination_rtl,
        description: "Pagination: previous sits on the right and the chevrons flip.",
        template: """
        <.direction_provider direction="rtl">
          <.pagination>
            <.pagination_content>
              <.pagination_item>
                <.pagination_previous href="#" text="السابق" />
              </.pagination_item>
              <.pagination_item>
                <.pagination_link href="#">١</.pagination_link>
              </.pagination_item>
              <.pagination_item>
                <.pagination_link href="#" is-active="true">٢</.pagination_link>
              </.pagination_item>
              <.pagination_item>
                <.pagination_link href="#">٣</.pagination_link>
              </.pagination_item>
              <.pagination_item>
                <.pagination_ellipsis />
              </.pagination_item>
              <.pagination_item>
                <.pagination_next href="#" text="التالي" />
              </.pagination_item>
            </.pagination_content>
          </.pagination>
        </.direction_provider>
        """
      }
    ]
  end
end
