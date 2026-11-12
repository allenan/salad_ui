defmodule SaladStorybookWeb.Blocks.Signup03 do
  @moduledoc """
  shadcn/ui block `signup-03`: a signup page with a muted background, a logo
  above the card and a name, email and password form.
  """
  use SaladStorybookWeb, :demo_view

  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Field
  import SaladUI.Input

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-svh flex-col items-center justify-center gap-6 bg-muted p-6 md:p-10">
      <div class="flex w-full max-w-sm flex-col gap-6">
        <a href="#" class="flex items-center gap-2 self-center font-medium">
          <div class="flex size-6 items-center justify-center rounded-md bg-primary text-primary-foreground">
            <Lucideicons.gallery_vertical_end class="size-4" />
          </div>
          Acme Inc.
        </a>
        <.signup_form />
      </div>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global

  def signup_form(assigns) do
    ~H"""
    <div class={["flex flex-col gap-6", @class]} {@rest}>
      <.card>
        <.card_header class="text-center">
          <.card_title class="text-xl">Create your account</.card_title>
          <.card_description>
            Enter your email below to create your account
          </.card_description>
        </.card_header>
        <.card_content>
          <form>
            <.field_group>
              <.field>
                <.field_label for="name">Full Name</.field_label>
                <.input id="name" type="text" placeholder="John Doe" required />
              </.field>
              <.field>
                <.field_label for="email">Email</.field_label>
                <.input id="email" type="email" placeholder="m@example.com" required />
              </.field>
              <.field>
                <.field class="grid grid-cols-2 gap-4">
                  <.field>
                    <.field_label for="password">Password</.field_label>
                    <.input id="password" type="password" required />
                  </.field>
                  <.field>
                    <.field_label for="confirm-password">
                      Confirm Password
                    </.field_label>
                    <.input id="confirm-password" type="password" required />
                  </.field>
                </.field>
                <.field_description>
                  Must be at least 8 characters long.
                </.field_description>
              </.field>
              <.field>
                <.button type="submit">Create Account</.button>
                <.field_description class="text-center">
                  Already have an account? <a href="#">Sign in</a>
                </.field_description>
              </.field>
            </.field_group>
          </form>
        </.card_content>
      </.card>
      <.field_description class="px-6 text-center">
        By clicking continue, you agree to our <a href="#">Terms of Service</a>
        and <a href="#">Privacy Policy</a>.
      </.field_description>
    </div>
    """
  end
end
