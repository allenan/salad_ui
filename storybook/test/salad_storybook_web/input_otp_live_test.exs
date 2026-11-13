defmodule SaladStorybookWeb.InputOTPLiveTest do
  @moduledoc """
  Drives the Input OTP LiveView example: the real input takes part in
  phx-change/phx-submit, field errors reach the input and slots, and the
  server value re-renders into the input.
  """
  use SaladStorybookWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @path SaladStorybookWeb.Storybook.leaves()
        |> Enum.map(& &1.path)
        |> Enum.find(&String.ends_with?(&1, "input_otp_live"))

  # Storybook mounts the example as a child LiveView.
  defp mount_example(conn) do
    {:ok, page, _html} = live(conn, @path)
    view = page |> live_children() |> Enum.find(&has_element?(&1, "#otp-live-form"))
    {view, render(view)}
  end

  defp otp_input(view), do: element(view, "#otp_code-input")

  test "submitting a short code marks the input invalid", %{conn: conn} do
    {view, _html} = mount_example(conn)

    view |> element("#otp-live-form") |> render_change(%{"otp" => %{"code" => "12"}})
    assert render(otp_input(view)) =~ ~s(value="12")
    refute render(otp_input(view)) =~ ~s(aria-invalid="true")

    html = view |> element("#otp-live-form") |> render_submit(%{"otp" => %{"code" => "12"}})

    assert html =~ "Enter the 6-digit code we sent you."
    assert render(otp_input(view)) =~ ~s(aria-invalid="true")
    assert render(element(view, "#otp_code")) =~ ~s(data-invalid="true")
  end

  test "submitting a full code clears the field", %{conn: conn} do
    {view, _html} = mount_example(conn)

    html = view |> element("#otp-live-form") |> render_submit(%{"otp" => %{"code" => "123456"}})

    assert html =~ "Verified 123456."
    assert render(otp_input(view)) =~ ~s(value="")
    refute render(otp_input(view)) =~ ~s(aria-invalid="true")
  end

  test "value-changed events reach the server", %{conn: conn} do
    {view, html} = mount_example(conn)
    assert html =~ "Enter your one-time password."

    html = render_hook(view, "otp_changed", %{"value" => "42"})
    assert html =~ "You entered: 42"

    view |> element("button", "Clear") |> render_click()
    assert_push_event(view, "saladui:command", %{command: "clear", target: "otp-live-controlled"})
    assert render(view) =~ "Enter your one-time password."
  end
end
