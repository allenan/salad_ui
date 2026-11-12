defmodule Storybook.SaladUIComponents.InputOTP do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Button
  alias SaladUI.Card
  alias SaladUI.Form
  alias SaladUI.InputOTP

  def function, do: &InputOTP.input_otp/1

  def imports,
    do: [
      {InputOTP, [input_otp_group: 1, input_otp_slot: 1, input_otp_separator: 1]},
      {Button, [button: 1]},
      {Card, [card: 1, card_header: 1, card_title: 1, card_description: 1, card_content: 1, card_footer: 1]},
      {Form, [form_item: 1, form_label: 1, form_description: 1]},
      {SaladStorybookWeb.CoreComponents, [icon: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :demo,
        description: "Six slots in two groups of three.",
        template: """
        <.input_otp id="otp-demo" maxlength={6} name="code">
          <.input_otp_group>
            <.input_otp_slot index={0} />
            <.input_otp_slot index={1} />
            <.input_otp_slot index={2} />
          </.input_otp_group>
          <.input_otp_separator />
          <.input_otp_group>
            <.input_otp_slot index={3} />
            <.input_otp_slot index={4} />
            <.input_otp_slot index={5} />
          </.input_otp_group>
        </.input_otp>
        """
      },
      %Variation{
        id: :pattern,
        description: ~s|`pattern={SaladUI.InputOTP.regexp_only_digits_and_chars()}` accepts letters and digits.|,
        template: """
        <.input_otp id="otp-pattern" maxlength={6} pattern={SaladUI.InputOTP.regexp_only_digits_and_chars()}>
          <.input_otp_group>
            <.input_otp_slot :for={i <- 0..5} index={i} />
          </.input_otp_group>
        </.input_otp>
        """
      },
      %Variation{
        id: :separator,
        description: "`input_otp_separator` between three groups of two.",
        template: """
        <.input_otp id="otp-separator" maxlength={6}>
          <.input_otp_group>
            <.input_otp_slot index={0} />
            <.input_otp_slot index={1} />
          </.input_otp_group>
          <.input_otp_separator />
          <.input_otp_group>
            <.input_otp_slot index={2} />
            <.input_otp_slot index={3} />
          </.input_otp_group>
          <.input_otp_separator />
          <.input_otp_group>
            <.input_otp_slot index={4} />
            <.input_otp_slot index={5} />
          </.input_otp_group>
        </.input_otp>
        """
      },
      %Variation{
        id: :disabled,
        description: "`disabled` disables the input.",
        template: """
        <.input_otp id="otp-disabled" maxlength={6} disabled value="123456">
          <.input_otp_group>
            <.input_otp_slot index={0} />
            <.input_otp_slot index={1} />
            <.input_otp_slot index={2} />
          </.input_otp_group>
          <.input_otp_separator />
          <.input_otp_group>
            <.input_otp_slot index={3} />
            <.input_otp_slot index={4} />
            <.input_otp_slot index={5} />
          </.input_otp_group>
        </.input_otp>
        """
      },
      %Variation{
        id: :controlled,
        description:
          ~s|`value` sets the value from the server; `on-value-changed` pushes `%{"value" => value}` on every change and `on-complete` once every slot is filled (see the event log). `SaladUI.LiveView.send_command(socket, id, "setValue", %{value: "..."})` replaces it.|,
        template: """
        <div class="space-y-2">
          <.input_otp
            id="otp-controlled"
            maxlength={6}
            value="12"
            on-value-changed="otp_changed"
            on-complete="otp_complete"
          >
            <.input_otp_group>
              <.input_otp_slot :for={i <- 0..5} index={i} />
            </.input_otp_group>
          </.input_otp>
          <div class="text-center text-sm">Enter your one-time password.</div>
        </div>
        """
      },
      %Variation{
        id: :invalid,
        description: ~s|`aria-invalid` on the slots shows the error state.|,
        template: """
        <.input_otp id="otp-invalid" maxlength={6} value="000000">
          <.input_otp_group>
            <.input_otp_slot index={0} aria-invalid />
            <.input_otp_slot index={1} aria-invalid />
          </.input_otp_group>
          <.input_otp_separator />
          <.input_otp_group>
            <.input_otp_slot index={2} aria-invalid />
            <.input_otp_slot index={3} aria-invalid />
          </.input_otp_group>
          <.input_otp_separator />
          <.input_otp_group>
            <.input_otp_slot index={4} aria-invalid />
            <.input_otp_slot index={5} aria-invalid />
          </.input_otp_group>
        </.input_otp>
        """
      },
      %Variation{
        id: :four_digits,
        description: ~s|A PIN code: `maxlength={4}` and `pattern={SaladUI.InputOTP.regexp_only_digits()}`.|,
        template: """
        <.input_otp id="otp-four-digits" maxlength={4} pattern={SaladUI.InputOTP.regexp_only_digits()}>
          <.input_otp_group>
            <.input_otp_slot index={0} />
            <.input_otp_slot index={1} />
            <.input_otp_slot index={2} />
            <.input_otp_slot index={3} />
          </.input_otp_group>
        </.input_otp>
        """
      },
      %Variation{
        id: :alphanumeric,
        description: ~s|`SaladUI.InputOTP.regexp_only_digits_and_chars()` accepts letters and numbers.|,
        template: """
        <.input_otp id="otp-alphanumeric" maxlength={6} pattern={SaladUI.InputOTP.regexp_only_digits_and_chars()}>
          <.input_otp_group>
            <.input_otp_slot index={0} />
            <.input_otp_slot index={1} />
            <.input_otp_slot index={2} />
          </.input_otp_group>
          <.input_otp_separator />
          <.input_otp_group>
            <.input_otp_slot index={3} />
            <.input_otp_slot index={4} />
            <.input_otp_slot index={5} />
          </.input_otp_group>
        </.input_otp>
        """
      },
      %Variation{
        id: :form,
        description: ~s|A verification card. The label points at the real input, `"\#{id}-input"`.|,
        template: """
        <.card class="mx-auto max-w-md">
          <.card_header>
            <.card_title>Verify your login</.card_title>
            <.card_description>
              Enter the verification code we sent to your email address:
              <span class="font-medium">m@example.com</span>.
            </.card_description>
          </.card_header>
          <.card_content>
            <.form_item class="grid gap-3 space-y-0">
              <div class="flex items-center justify-between">
                <.form_label for="otp-verification-input">Verification code</.form_label>
                <.button variant="outline" size="xs" type="button">
                  <.icon name="hero-arrow-path" /> Resend Code
                </.button>
              </div>
              <.input_otp id="otp-verification" maxlength={6} name="code" required>
                <.input_otp_group class="*:data-[slot=input-otp-slot]:h-12 *:data-[slot=input-otp-slot]:w-11 *:data-[slot=input-otp-slot]:text-xl">
                  <.input_otp_slot index={0} />
                  <.input_otp_slot index={1} />
                  <.input_otp_slot index={2} />
                </.input_otp_group>
                <.input_otp_separator class="mx-2" />
                <.input_otp_group class="*:data-[slot=input-otp-slot]:h-12 *:data-[slot=input-otp-slot]:w-11 *:data-[slot=input-otp-slot]:text-xl">
                  <.input_otp_slot index={3} />
                  <.input_otp_slot index={4} />
                  <.input_otp_slot index={5} />
                </.input_otp_group>
              </.input_otp>
              <.form_description>
                <a href="#" class="underline underline-offset-4">I no longer have access to this email address.</a>
              </.form_description>
            </.form_item>
          </.card_content>
          <.card_footer>
            <div class="grid w-full gap-3">
              <.button type="submit" class="w-full">Verify</.button>
              <div class="text-sm text-muted-foreground">
                Having trouble signing in?
                <a href="#" class="underline underline-offset-4 transition-colors hover:text-primary">Contact support</a>
              </div>
            </div>
          </.card_footer>
        </.card>
        """
      },
      %Variation{
        id: :rtl,
        description: ~s|`dir="rtl"` lays the slots out right to left.|,
        template: """
        <div class="mx-auto grid max-w-xs gap-3" dir="rtl">
          <.form_label for="otp-rtl-input">رمز التحقق</.form_label>
          <.input_otp id="otp-rtl" maxlength={6} value="123456" dir="rtl">
            <.input_otp_group>
              <.input_otp_slot :for={i <- 0..5} index={i} />
            </.input_otp_group>
          </.input_otp>
        </div>
        """
      }
    ]
  end
end
