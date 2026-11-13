defmodule Storybook.Examples.InputOTPLive do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Button
  import SaladUI.Form
  import SaladUI.InputOTP

  def doc do
    "Input OTP driven by LiveView: shadcn's controlled example via `on-value-changed`, " <>
      "a `phx-change`/`phx-submit` form bound with `field`, and `send_command/4`."
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, value: "", submitted: nil, form: to_form(%{"code" => ""}, as: :otp))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto grid max-w-sm gap-10 py-8">
      <div class="space-y-2">
        <.input_otp id="otp-live-controlled" maxlength={6} on-value-changed="otp_changed">
          <.input_otp_group>
            <.input_otp_slot :for={i <- 0..5} index={i} />
          </.input_otp_group>
        </.input_otp>
        <div class="text-center text-sm">
          <%= if @value == "" do %>
            Enter your one-time password.
          <% else %>
            You entered: {@value}
          <% end %>
        </div>
        <div class="flex gap-2">
          <.button variant="outline" size="sm" phx-click="fill">Fill 123456</.button>
          <.button variant="outline" size="sm" phx-click="clear">Clear</.button>
        </div>
      </div>

      <.form
        for={@form}
        id="otp-live-form"
        phx-change="validate"
        phx-submit="verify"
        class="space-y-3"
      >
        <.form_item>
          <.form_label for="otp_code-input">Verification code</.form_label>
          <.input_otp field={@form[:code]} maxlength={6} pattern={regexp_only_digits()}>
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
          <.form_message field={@form[:code]} />
        </.form_item>
        <.button type="submit">Verify</.button>
        <p :if={@submitted} class="text-sm text-muted-foreground">Verified {@submitted}.</p>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("otp_changed", %{"value" => value}, socket) do
    {:noreply, assign(socket, value: value)}
  end

  def handle_event("fill", _params, socket) do
    socket = SaladUI.LiveView.send_command(socket, "otp-live-controlled", "setValue", %{value: "123456"})
    {:noreply, assign(socket, value: "123456")}
  end

  def handle_event("clear", _params, socket) do
    socket = SaladUI.LiveView.send_command(socket, "otp-live-controlled", "clear")
    {:noreply, assign(socket, value: "")}
  end

  def handle_event("validate", %{"otp" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: :otp))}
  end

  def handle_event("verify", %{"otp" => %{"code" => code} = params}, socket) do
    if String.length(code) == 6 do
      {:noreply, assign(socket, submitted: code, form: to_form(%{"code" => ""}, as: :otp))}
    else
      errors = [code: {"Enter the 6-digit code we sent you.", []}]
      {:noreply, assign(socket, submitted: nil, form: to_form(params, as: :otp, errors: errors, action: :insert))}
    end
  end
end
