defmodule Storybook.SaladUIComponents.Field do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Button
  alias SaladUI.Checkbox
  alias SaladUI.Field
  alias SaladUI.Input
  alias SaladUI.NativeSelect
  alias SaladUI.RadioGroup
  alias SaladUI.Select
  alias SaladUI.Slider
  alias SaladUI.Switch
  alias SaladUI.Textarea

  def function, do: &Field.field/1
  def layout, do: :one_column

  def imports,
    do: [
      {Field,
       [
         field_set: 1,
         field_legend: 1,
         field_group: 1,
         field_content: 1,
         field_label: 1,
         field_title: 1,
         field_description: 1,
         field_separator: 1,
         field_error: 1
       ]},
      {Button, [button: 1]},
      {Checkbox, [checkbox: 1]},
      {Input, [input: 1]},
      {NativeSelect, [native_select: 1, native_select_option: 1]},
      {RadioGroup, [radio_group: 1, radio_group_item: 1]},
      {Select, [select: 1, select_trigger: 1, select_value: 1, select_content: 1, select_item: 1]},
      {Slider, [slider: 1]},
      {Switch, [switch: 1]},
      {Textarea, [textarea: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :demo,
        description: "A checkout form: fieldsets, legends, grouped fields, a separator and a horizontal button row.",
        template: """
        <div class="w-full max-w-md">
          <form>
            <.field_group>
              <.field_set>
                <.field_legend>Payment Method</.field_legend>
                <.field_description>All transactions are secure and encrypted</.field_description>
                <.field_group>
                  <.field>
                    <.field_label for="checkout-card-name">Name on Card</.field_label>
                    <.input id="checkout-card-name" placeholder="Evil Rabbit" required />
                  </.field>
                  <.field>
                    <.field_label for="checkout-card-number">Card Number</.field_label>
                    <.input id="checkout-card-number" placeholder="1234 5678 9012 3456" required />
                    <.field_description>Enter your 16-digit card number</.field_description>
                  </.field>
                  <div class="grid grid-cols-3 gap-4">
                    <.field>
                      <.field_label>Month</.field_label>
                      <.select id="checkout-exp-month" name="month" placeholder="MM">
                        <.select_trigger>
                          <.select_value placeholder="MM" />
                        </.select_trigger>
                        <.select_content>
                          <.select_item :for={m <- ~w(01 02 03 04 05 06 07 08 09 10 11 12)} value={m}>{m}</.select_item>
                        </.select_content>
                      </.select>
                    </.field>
                    <.field>
                      <.field_label>Year</.field_label>
                      <.select id="checkout-exp-year" name="year" placeholder="YYYY">
                        <.select_trigger>
                          <.select_value placeholder="YYYY" />
                        </.select_trigger>
                        <.select_content>
                          <.select_item :for={y <- ~w(2024 2025 2026 2027 2028 2029)} value={y}>{y}</.select_item>
                        </.select_content>
                      </.select>
                    </.field>
                    <.field>
                      <.field_label for="checkout-cvv">CVV</.field_label>
                      <.input id="checkout-cvv" placeholder="123" required />
                    </.field>
                  </div>
                </.field_group>
              </.field_set>
              <.field_separator />
              <.field_set>
                <.field_legend>Billing Address</.field_legend>
                <.field_description>The billing address associated with your payment method</.field_description>
                <.field_group>
                  <.field orientation="horizontal">
                    <.checkbox id="checkout-same-as-shipping" value={true} />
                    <.field_label for="checkout-same-as-shipping" class="font-normal">
                      Same as shipping address
                    </.field_label>
                  </.field>
                </.field_group>
              </.field_set>
              <.field_set>
                <.field_group>
                  <.field>
                    <.field_label for="checkout-comments">Comments</.field_label>
                    <.textarea id="checkout-comments" placeholder="Add any additional comments" class="resize-none" />
                  </.field>
                </.field_group>
              </.field_set>
              <.field orientation="horizontal">
                <.button type="submit">Submit</.button>
                <.button variant="outline" type="button">Cancel</.button>
              </.field>
            </.field_group>
          </form>
        </div>
        """
      },
      %Variation{
        id: :input,
        description: "Descriptions can go before or after the control.",
        template: """
        <div class="w-full max-w-md">
          <.field_set>
            <.field_group>
              <.field>
                <.field_label for="input-username">Username</.field_label>
                <.input id="input-username" type="text" placeholder="Max Leiter" />
                <.field_description>Choose a unique username for your account.</.field_description>
              </.field>
              <.field>
                <.field_label for="input-password">Password</.field_label>
                <.field_description>Must be at least 8 characters long.</.field_description>
                <.input id="input-password" type="password" placeholder="••••••••" />
              </.field>
            </.field_group>
          </.field_set>
        </div>
        """
      },
      %Variation{
        id: :textarea,
        template: """
        <div class="w-full max-w-md">
          <.field_set>
            <.field_group>
              <.field>
                <.field_label for="textarea-feedback">Feedback</.field_label>
                <.textarea id="textarea-feedback" placeholder="Your feedback helps us improve..." rows="4" />
                <.field_description>Share your thoughts about our service.</.field_description>
              </.field>
            </.field_group>
          </.field_set>
        </div>
        """
      },
      %Variation{
        id: :select,
        template: """
        <div class="w-full max-w-md">
          <.field>
            <.field_label>Department</.field_label>
            <.select id="select-department" name="department" placeholder="Choose department">
              <.select_trigger>
                <.select_value placeholder="Choose department" />
              </.select_trigger>
              <.select_content>
                <.select_item value="engineering">Engineering</.select_item>
                <.select_item value="design">Design</.select_item>
                <.select_item value="marketing">Marketing</.select_item>
                <.select_item value="sales">Sales</.select_item>
                <.select_item value="support">Customer Support</.select_item>
                <.select_item value="hr">Human Resources</.select_item>
                <.select_item value="finance">Finance</.select_item>
                <.select_item value="operations">Operations</.select_item>
              </.select_content>
            </.select>
            <.field_description>Select your department or area of work.</.field_description>
          </.field>
        </div>
        """
      },
      %Variation{
        id: :native_select,
        description: "A native select in a field, generated from `options`.",
        template: """
        <div class="w-full max-w-md">
          <.field>
            <.field_label for="native-department">Department</.field_label>
            <.native_select
              id="native-department"
              name="department"
              prompt="Choose department"
              options={[{"Engineering", "engineering"}, {"Design", "design"}, {"Marketing", "marketing"}]}
            />
            <.field_description>Select your department or area of work.</.field_description>
          </.field>
        </div>
        """
      },
      %Variation{
        id: :slider,
        description: "`field_title` labels a control that has no labelable element.",
        template: """
        <div class="w-full max-w-md">
          <.field>
            <.field_title>Price Range</.field_title>
            <.field_description>Set your budget range ($200 - $800).</.field_description>
            <.slider
              id="field-slider-price"
              name="price"
              max={1000}
              step={10}
              value={[200, 800]}
              class="mt-2 w-full"
              aria-label="Price Range"
            />
          </.field>
        </div>
        """
      },
      %Variation{
        id: :fieldset,
        template: """
        <div class="w-full max-w-md space-y-6">
          <.field_set>
            <.field_legend>Address Information</.field_legend>
            <.field_description>We need your address to deliver your order.</.field_description>
            <.field_group>
              <.field>
                <.field_label for="fieldset-street">Street Address</.field_label>
                <.input id="fieldset-street" type="text" placeholder="123 Main St" />
              </.field>
              <div class="grid grid-cols-2 gap-4">
                <.field>
                  <.field_label for="fieldset-city">City</.field_label>
                  <.input id="fieldset-city" type="text" placeholder="New York" />
                </.field>
                <.field>
                  <.field_label for="fieldset-zip">Postal Code</.field_label>
                  <.input id="fieldset-zip" type="text" placeholder="90502" />
                </.field>
              </div>
            </.field_group>
          </.field_set>
        </div>
        """
      },
      %Variation{
        id: :checkbox,
        description: "A `label`-variant legend over a tight checkbox list, then a checkbox with a description.",
        template: """
        <div class="w-full max-w-md">
          <.field_group>
            <.field_set>
              <.field_legend variant="label">Show these items on the desktop</.field_legend>
              <.field_description>Select the items you want to show on the desktop.</.field_description>
              <.field_group class="gap-3">
                <.field orientation="horizontal">
                  <.checkbox id="finder-hard-disks" value={true} />
                  <.field_label for="finder-hard-disks" class="font-normal">Hard disks</.field_label>
                </.field>
                <.field orientation="horizontal">
                  <.checkbox id="finder-external-disks" />
                  <.field_label for="finder-external-disks" class="font-normal">External disks</.field_label>
                </.field>
                <.field orientation="horizontal">
                  <.checkbox id="finder-cds-dvds" />
                  <.field_label for="finder-cds-dvds" class="font-normal">CDs, DVDs, and iPods</.field_label>
                </.field>
                <.field orientation="horizontal">
                  <.checkbox id="finder-connected-servers" />
                  <.field_label for="finder-connected-servers" class="font-normal">Connected servers</.field_label>
                </.field>
              </.field_group>
            </.field_set>
            <.field_separator />
            <.field orientation="horizontal">
              <.checkbox id="finder-sync-folders" value={true} />
              <.field_content>
                <.field_label for="finder-sync-folders">Sync Desktop &amp; Documents folders</.field_label>
                <.field_description>
                  Your Desktop &amp; Documents folders are being synced with iCloud Drive. You can access them from other devices.
                </.field_description>
              </.field_content>
            </.field>
          </.field_group>
        </div>
        """
      },
      %Variation{
        id: :radio,
        template: """
        <div class="w-full max-w-md">
          <.field_set>
            <.field_label>Subscription Plan</.field_label>
            <.field_description>Yearly and lifetime plans offer significant savings.</.field_description>
            <.radio_group id="field-radio-plan" name="plan" default-value="monthly">
              <.field orientation="horizontal">
                <.radio_group_item value="monthly" id="plan-monthly" />
                <.field_label for="plan-monthly" class="font-normal">Monthly ($9.99/month)</.field_label>
              </.field>
              <.field orientation="horizontal">
                <.radio_group_item value="yearly" id="plan-yearly" />
                <.field_label for="plan-yearly" class="font-normal">Yearly ($99.99/year)</.field_label>
              </.field>
              <.field orientation="horizontal">
                <.radio_group_item value="lifetime" id="plan-lifetime" />
                <.field_label for="plan-lifetime" class="font-normal">Lifetime ($299.99)</.field_label>
              </.field>
            </.radio_group>
          </.field_set>
        </div>
        """
      },
      %Variation{
        id: :switch,
        description: "The switch's labelable element is its `<id>-input` checkbox.",
        template: """
        <div class="w-full max-w-md">
          <.field orientation="horizontal">
            <.field_content>
              <.field_label for="field-switch-2fa-input">Multi-factor authentication</.field_label>
              <.field_description>
                Enable multi-factor authentication. If you do not have a two-factor device, you can use a one-time code sent to your email.
              </.field_description>
            </.field_content>
            <.switch id="field-switch-2fa" />
          </.field>
        </div>
        """
      },
      %Variation{
        id: :choice_card,
        description: "Wrap a `field` in `field_label` to make a selectable card.",
        template: """
        <div class="w-full max-w-md">
          <.field_group>
            <.field_set>
              <.field_label>Compute Environment</.field_label>
              <.field_description>Select the compute environment for your cluster.</.field_description>
              <.radio_group id="field-choice-compute" name="compute" default-value="kubernetes">
                <.field_label for="choice-kubernetes">
                  <.field orientation="horizontal">
                    <.field_content>
                      <.field_title>Kubernetes</.field_title>
                      <.field_description>Run GPU workloads on a K8s configured cluster.</.field_description>
                    </.field_content>
                    <.radio_group_item value="kubernetes" id="choice-kubernetes" />
                  </.field>
                </.field_label>
                <.field_label for="choice-vm">
                  <.field orientation="horizontal">
                    <.field_content>
                      <.field_title>Virtual Machine</.field_title>
                      <.field_description>Access a VM configured cluster to run GPU workloads.</.field_description>
                    </.field_content>
                    <.radio_group_item value="vm" id="choice-vm" />
                  </.field>
                </.field_label>
              </.radio_group>
            </.field_set>
          </.field_group>
        </div>
        """
      },
      %Variation{
        id: :field_group,
        description:
          "Stack fieldsets in a group with a separator; `data-slot=\"checkbox-group\"` tightens a checkbox list.",
        template: """
        <div class="w-full max-w-md">
          <.field_group>
            <.field_set>
              <.field_label>Responses</.field_label>
              <.field_description>
                Get notified when ChatGPT responds to requests that take time, like research or image generation.
              </.field_description>
              <.field_group data-slot="checkbox-group">
                <.field orientation="horizontal">
                  <.checkbox id="group-push" value={true} disabled />
                  <.field_label for="group-push" class="font-normal">Push notifications</.field_label>
                </.field>
              </.field_group>
            </.field_set>
            <.field_separator />
            <.field_set>
              <.field_label>Tasks</.field_label>
              <.field_description>
                Get notified when tasks you've created have updates. <a href="#">Manage tasks</a>
              </.field_description>
              <.field_group data-slot="checkbox-group">
                <.field orientation="horizontal">
                  <.checkbox id="group-push-tasks" />
                  <.field_label for="group-push-tasks" class="font-normal">Push notifications</.field_label>
                </.field>
                <.field orientation="horizontal">
                  <.checkbox id="group-email-tasks" />
                  <.field_label for="group-email-tasks" class="font-normal">Email notifications</.field_label>
                </.field>
              </.field_group>
            </.field_set>
          </.field_group>
        </div>
        """
      },
      %Variation{
        id: :responsive,
        description: "`orientation=\"responsive\"` stacks until the field group is `@md` wide.",
        template: """
        <div class="w-full max-w-4xl">
          <form>
            <.field_set>
              <.field_legend>Profile</.field_legend>
              <.field_description>Fill in your profile information.</.field_description>
              <.field_separator />
              <.field_group>
                <.field orientation="responsive">
                  <.field_content>
                    <.field_label for="responsive-name">Name</.field_label>
                    <.field_description>Provide your full name for identification</.field_description>
                  </.field_content>
                  <.input id="responsive-name" placeholder="Evil Rabbit" required />
                </.field>
                <.field_separator />
                <.field orientation="responsive">
                  <.field_content>
                    <.field_label for="responsive-message">Message</.field_label>
                    <.field_description>
                      You can write your message here. Keep it short, preferably under 100 characters.
                    </.field_description>
                  </.field_content>
                  <.textarea
                    id="responsive-message"
                    placeholder="Hello, world!"
                    required
                    class="min-h-[100px] resize-none sm:min-w-[300px]"
                  />
                </.field>
                <.field_separator />
                <.field orientation="responsive">
                  <.button type="submit">Submit</.button>
                  <.button type="button" variant="outline">Cancel</.button>
                </.field>
              </.field_group>
            </.field_set>
          </form>
        </div>
        """
      },
      %Variation{
        id: :validation,
        description: "`invalid` (or `data-invalid`) on the field, `aria-invalid` on the control.",
        template: """
        <div class="w-full max-w-md">
          <.field_group>
            <.field invalid>
              <.field_label for="validation-email">Email</.field_label>
              <.input id="validation-email" type="email" aria-invalid="true" />
              <.field_error>Enter a valid email address.</.field_error>
            </.field>
            <.field data-invalid>
              <.field_label for="validation-password">Password</.field_label>
              <.input id="validation-password" type="password" aria-invalid="true" />
              <.field_error errors={["Must be at least 8 characters.", "Must contain a number."]} />
            </.field>
          </.field_group>
        </div>
        """
      },
      %Variation{
        id: :form_field,
        description:
          "Pass the same form field to `field`, `field_label`, the control and `field_error`: error state, `for`, `aria-invalid` and messages follow the form.",
        template: """
        <.form
          :let={f}
          for={to_form(%{"email" => "rabbit", "role" => ""}, errors: [email: {"must have the @ sign and no spaces", []}, role: {"can't be blank", []}])}
          class="w-full max-w-md"
        >
          <.field_group>
            <.field field={f[:email]}>
              <.field_label field={f[:email]}>Email</.field_label>
              <.input field={f[:email]} type="email" />
              <.field_description>We never share your email.</.field_description>
              <.field_error field={f[:email]} />
            </.field>
            <.field field={f[:role]}>
              <.field_label field={f[:role]}>Role</.field_label>
              <.native_select field={f[:role]} prompt="Select role" options={[{"Admin", "admin"}, {"Editor", "editor"}]} />
              <.field_error field={f[:role]} />
            </.field>
            <.field orientation="horizontal">
              <.button type="submit">Save</.button>
            </.field>
          </.field_group>
        </.form>
        """
      },
      %Variation{
        id: :separator,
        template: """
        <div class="w-full max-w-md">
          <.field_group>
            <.field>
              <.button variant="outline" type="button">Login with GitHub</.button>
            </.field>
            <.field_separator>Or continue with</.field_separator>
            <.field>
              <.field_label for="separator-email">Email</.field_label>
              <.input id="separator-email" type="email" placeholder="m@example.com" />
            </.field>
          </.field_group>
        </div>
        """
      }
    ]
  end
end
