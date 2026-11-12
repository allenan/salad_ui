defmodule SaladUI.InputOTPTest do
  use ComponentCase

  import SaladUI.InputOTP

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField

  defp render_otp(assigns) do
    ~H"""
    <.input_otp {@attrs}>
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
    |> rendered_to_string()
    |> clean_string()
  end

  defp inputs(html), do: Regex.scan(~r/<input[^>]*>/, html)

  describe "input_otp/1" do
    test "renders a hooked container with one real input" do
      html = render_otp(%{attrs: %{id: "otp", maxlength: 6, name: "code", value: "123"}})

      assert html =~ ~s(id="otp")
      assert html =~ ~s(data-component="input-otp")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-input-otp-container)
      assert html =~ "flex items-center gap-2 has-disabled:opacity-50"

      assert [[input]] = inputs(html)
      assert input =~ ~s(type="text")
      assert input =~ ~s(id="otp-input")
      assert input =~ ~s(name="code")
      assert input =~ ~s(value="123")
      assert input =~ ~s(maxlength="6")
      assert input =~ ~s(autocomplete="one-time-code")
      assert input =~ ~s(inputmode="numeric")
      assert input =~ ~s(data-slot="input-otp")
      assert input =~ ~s(data-part="input")
      assert input =~ "disabled:cursor-not-allowed"
      assert input =~ "text-transparent caret-transparent"
    end

    test "encodes maxlength and pattern for the JS component" do
      html =
        render_otp(%{
          attrs: %{id: "otp", maxlength: 6, pattern: regexp_only_digits_and_chars()}
        })

      assert html =~ ~s(&quot;maxLength&quot;:6)
      assert html =~ ~s(&quot;pattern&quot;:&quot;^[a-zA-Z0-9]+$&quot;)
      assert html =~ ~s(pattern="^[a-zA-Z0-9]+$")
      # Letters are allowed, so mobile keyboards should not be numeric-only.
      assert html =~ ~s(inputmode="text")
    end

    test "digit-only pattern keeps the numeric keyboard" do
      html = render_otp(%{attrs: %{id: "otp", maxlength: 4, pattern: regexp_only_digits()}})
      assert html =~ ~s(inputmode="numeric")
      assert html =~ ~S(pattern="^\d+$")
    end

    test "truncates the value to maxlength" do
      html = render_otp(%{attrs: %{id: "otp", maxlength: 4, value: "1234567"}})
      assert html =~ ~s(value="1234")
    end

    test "uses default-value when value is empty" do
      html = render_otp(%{attrs: %{id: "otp", maxlength: 6, "default-value": "42"}})
      assert html =~ ~s(value="42")
    end

    test "disabled disables the real input" do
      html = render_otp(%{attrs: %{id: "otp", maxlength: 6, disabled: true}})

      assert [[input]] = inputs(html)
      assert input =~ "disabled"
      assert html =~ ~s(data-disabled)
      assert html =~ "cursor-default"
    end

    test "global attributes go on the real input, class on the container" do
      html =
        render_otp(%{
          attrs: %{
            id: "otp",
            maxlength: 6,
            required: true,
            "aria-label": "Code",
            class: "gap-4",
            "input-class": "custom-input"
          }
        })

      assert [[input]] = inputs(html)
      assert input =~ "required"
      assert input =~ ~s(aria-label="Code")
      assert input =~ "custom-input"
      assert html =~ ~r/id="otp"[^>]*class="[^"]*gap-4/
      refute html =~ "gap-2 gap-4"
    end

    test "event handlers are encoded as event mappings" do
      html =
        render_otp(%{
          attrs: %{id: "otp", maxlength: 6, "on-value-changed": "changed", "on-complete": "done"}
        })

      assert html =~ ~s(&quot;value-changed&quot;:&quot;changed&quot;)
      assert html =~ ~s(&quot;complete&quot;:&quot;done&quot;)
    end

    test "dir is set on the container and the input" do
      html = render_otp(%{attrs: %{id: "otp", maxlength: 6, dir: "rtl"}})
      assert length(Regex.scan(~r/dir="rtl"/, html)) == 2
    end

    test "form field binds id, name, value and errors" do
      field = %FormField{
        id: "user_code",
        name: "user[code]",
        value: "999",
        errors: [{"is invalid", []}],
        field: :code,
        form: %Form{params: %{"code" => "999"}}
      }

      html = render_otp(%{attrs: %{field: field, maxlength: 6}})

      assert html =~ ~s(id="user_code")
      assert html =~ ~s(id="user_code-input")
      assert html =~ ~s(name="user[code]")
      assert html =~ ~s(value="999")
      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(data-invalid="true")
    end

    test "requires an id or a field" do
      assert_raise ArgumentError, ~r/requires an :id/, fn ->
        render_otp(%{attrs: %{maxlength: 6}})
      end
    end

    test "errors on a field the user has not touched don't mark it invalid" do
      field = %FormField{
        id: "user_code",
        name: "user[code]",
        value: nil,
        errors: [{"can't be blank", []}],
        field: :code,
        form: %Form{params: %{"code" => "", "_unused_code" => ""}}
      }

      html = render_otp(%{attrs: %{field: field, maxlength: 6}})

      refute html =~ ~s(aria-invalid=")
      refute html =~ ~s(data-invalid=")
      assert html =~ ~s(value="")
    end

    test "an integer field value is rendered as text" do
      field = %FormField{
        id: "pin",
        name: "pin",
        value: 1234,
        errors: [],
        field: :pin,
        form: %Form{params: %{}}
      }

      html = render_otp(%{attrs: %{field: field, maxlength: 6}})
      assert html =~ ~s(value="1234")
    end
  end

  describe "input_otp_slot/1" do
    test "renders shadcn classes, index and an empty character and caret" do
      assigns = %{}

      html =
        ~H"""
        <.input_otp_slot index={2} class="h-12" />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(data-slot="input-otp-slot")
      assert html =~ ~s(data-index="2")
      assert html =~ ~s(data-active="false")
      assert html =~ "data-[active=true]:ring-[3px]"
      assert html =~ "aria-invalid:border-destructive"
      assert html =~ "h-12"
      refute html =~ "h-9"
      assert html =~ ~s(data-part="caret" hidden)
      assert html =~ "animate-caret-blink"
    end

    test "a bare aria-invalid renders as \"true\"" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.input_otp_slot index={0} aria-invalid />
        """)

      assert html =~ ~s(aria-invalid="true")
    end
  end

  describe "input_otp_group/1 and input_otp_separator/1" do
    test "group renders its slot name and classes" do
      assigns = %{}

      html =
        ~H"""
        <.input_otp_group class="gap-1">x</.input_otp_group>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(data-slot="input-otp-group")
      assert html =~ "flex items-center gap-1"
    end

    test "separator defaults to a minus icon and accepts custom content" do
      assigns = %{}

      default =
        rendered_to_string(~H"""
        <.input_otp_separator />
        """)

      custom =
        rendered_to_string(~H"""
        <.input_otp_separator class="mx-2">·</.input_otp_separator>
        """)

      assert default =~ ~s(role="separator")
      assert default =~ ~s(data-slot="input-otp-separator")
      assert default =~ ~s(d="M5 12h14")
      assert custom =~ "·"
      assert custom =~ "mx-2"
      refute custom =~ "<svg"
    end
  end
end
