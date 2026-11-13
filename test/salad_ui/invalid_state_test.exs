defmodule SaladUI.InvalidStateTest do
  @moduledoc """
  shadcn v4 drives form-control error styling from `aria-invalid`. These tests
  cover SaladUI setting it automatically from a `Phoenix.HTML.FormField` with
  errors, and the Tailwind v4 drift fixes that go with it.
  """
  use ComponentCase

  import SaladUI.Badge
  import SaladUI.Button
  import SaladUI.Checkbox
  import SaladUI.Form
  import SaladUI.Input
  import SaladUI.RadioGroup
  import SaladUI.Select
  import SaladUI.Sidebar
  import SaladUI.Switch
  import SaladUI.Textarea
  import SaladUI.Toggle

  alias Phoenix.HTML.FormField
  alias SaladUI.Helpers

  @invalid_classes ~w(aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40)

  defp field(errors, value \\ nil, params \\ %{"email" => ""}) do
    %FormField{
      id: "user_email",
      name: "user[email]",
      value: value,
      errors: errors,
      field: :email,
      form: %Phoenix.HTML.Form{params: params}
    }
  end

  defp invalid_field(value \\ nil), do: field([{"can't be blank", []}], value)
  defp valid_field, do: field([])

  # The first `<input ...>` tag containing `marker`.
  defp input_tag(html, marker) do
    ~r/<input\b[^>]*>/
    |> Regex.scan(html)
    |> List.flatten()
    |> Enum.find(&String.contains?(&1, marker))
  end

  describe "Helpers.invalid?/1" do
    test "is true only when errors are present" do
      assert Helpers.invalid?(%{errors: ["can't be blank"]})
      refute Helpers.invalid?(%{errors: []})
      refute Helpers.invalid?(%{})
    end
  end

  describe "used_input? filtering" do
    test "errors on an input the user has not touched don't mark it invalid" do
      untouched = field([{"can't be blank", []}], nil, %{"email" => "", "_unused_email" => ""})
      assigns = %{field: untouched}
      html = rendered_to_string(~H"<.input field={@field} />")

      refute html =~ ~s(aria-invalid=")
    end

    test "errors on a field missing from the params don't mark it invalid" do
      assigns = %{field: field([{"can't be blank", []}], nil, %{})}
      html = rendered_to_string(~H"<.checkbox field={@field} />")

      refute html =~ ~s(aria-invalid=")
    end

    # LiveView only sends `_unused_<name>` for a field when at least one of its
    # inputs is not type="hidden" and none has been changed or submitted. The
    # select's value inputs are all hidden, so it renders a tracking input.
    test "a select renders a non-hidden-type tracking input named after the field" do
      assigns = %{field: field([])}

      html =
        rendered_to_string(~H"""
        <.select field={@field} id="fruit">
          <.select_trigger><.select_value placeholder="Pick" /></.select_trigger>
        </.select>
        """)

      tracker = input_tag(html, "data-salad-ui-select-tracker")
      assert tracker =~ ~s(type="text")
      assert tracker =~ ~s(name="user[email]")
      assert tracker =~ ~s(value="")
      assert tracker =~ ~r/\shidden[\s>\/]/
      refute tracker =~ "disabled"
    end

    test "a filled multiple select's tracking input is disabled and uses the [] name" do
      assigns = %{field: field([], ["a"])}

      html =
        rendered_to_string(~H"""
        <.select field={@field} id="fruit" multiple>
          <.select_trigger><.select_value placeholder="Pick" /></.select_trigger>
        </.select>
        """)

      tracker = input_tag(html, "data-salad-ui-select-tracker")
      assert tracker =~ ~s(name="user[email][]")
      assert tracker =~ "disabled"
    end

    # An empty multiple select has no hidden value inputs, so without this it
    # would submit nothing and never count as used.
    test "an empty multiple select's tracking input submits the bare name" do
      assigns = %{field: field([])}

      html =
        rendered_to_string(~H"""
        <.select field={@field} id="fruit" multiple>
          <.select_trigger><.select_value placeholder="Pick" /></.select_trigger>
        </.select>
        """)

      tracker = input_tag(html, "data-salad-ui-select-tracker")
      assert tracker =~ ~s(name="user[email]")
      refute tracker =~ "disabled"
    end

    test "an empty multiple select is data-invalid after submit" do
      # On submit the tracking input sends `user[email]=""`.
      submitted = field([{"can't be blank", []}], nil, %{"email" => ""})
      assigns = %{field: submitted}

      html =
        rendered_to_string(~H"""
        <.select field={@field} id="fruit" multiple>
          <.select_trigger><.select_value placeholder="Pick" /></.select_trigger>
        </.select>
        """)

      assert html =~ ~s(data-invalid="true")
    end

    test "an untouched empty multiple select is not data-invalid" do
      untouched = field([{"can't be blank", []}], nil, %{"email" => "", "_unused_email" => ""})
      assigns = %{field: untouched}

      html =
        rendered_to_string(~H"""
        <.select field={@field} id="fruit" multiple>
          <.select_trigger><.select_value placeholder="Pick" /></.select_trigger>
        </.select>
        """)

      refute html =~ "data-invalid"
    end

    test "a disabled select's tracking input is disabled" do
      assigns = %{field: field([])}

      html =
        rendered_to_string(~H"""
        <.select field={@field} id="fruit" disabled>
          <.select_trigger><.select_value placeholder="Pick" /></.select_trigger>
        </.select>
        """)

      assert input_tag(html, "data-salad-ui-select-tracker") =~ "disabled"
    end

    test "the trigger renders aria-invalid on the server through :let" do
      assigns = %{field: invalid_field()}

      html =
        rendered_to_string(~H"""
        <.select :let={select} field={@field} id="fruit">
          <.select_trigger aria-invalid={select.invalid}>
            <.select_value placeholder="Pick" />
          </.select_trigger>
        </.select>
        """)

      assert html =~ ~r/<button[^>]*aria-invalid="true"/

      assigns = %{field: valid_field()}

      html =
        rendered_to_string(~H"""
        <.select :let={select} field={@field} id="fruit">
          <.select_trigger aria-invalid={select.invalid}>
            <.select_value placeholder="Pick" />
          </.select_trigger>
        </.select>
        """)

      refute html =~ ~s(aria-invalid=")
    end

    test "a select without a name renders no tracking input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select id="fruit">
          <.select_trigger><.select_value placeholder="Pick" /></.select_trigger>
        </.select>
        """)

      refute html =~ "data-salad-ui-select-tracker"
    end

    test "a select the user has not touched is not data-invalid" do
      # The params LiveView sends on a phx-change of another field, now that
      # the tracking input makes the select's key visible but unused.
      untouched = field([{"can't be blank", []}], nil, %{"email" => "", "_unused_email" => ""})
      assigns = %{field: untouched}

      html =
        rendered_to_string(~H"""
        <.select field={@field} id="fruit">
          <.select_trigger><.select_value placeholder="Pick" /></.select_trigger>
        </.select>
        """)

      refute html =~ "data-invalid"
    end

    test "an empty select is data-invalid after submit" do
      # On submit every input counts as used and the tracking input submits "".
      submitted = field([{"can't be blank", []}], nil, %{"email" => ""})
      assigns = %{field: submitted}

      html =
        rendered_to_string(~H"""
        <.select field={@field} id="fruit">
          <.select_trigger><.select_value placeholder="Pick" /></.select_trigger>
        </.select>
        """)

      assert html =~ ~s(data-invalid="true")
    end

    test "a radio group renders an empty hidden input ahead of its radios" do
      assigns = %{field: field([])}

      html =
        rendered_to_string(~H"""
        <.radio_group field={@field}>
          <.radio_group_item value="a" id="a" />
        </.radio_group>
        """)

      first = input_tag(html, "")
      assert first =~ ~s(type="hidden")
      assert first =~ ~s(name="user[email]")
      assert first =~ ~s(value="")
    end

    test "a radio group without a name renders no hidden input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.radio_group id="rg">
          <.radio_group_item value="a" id="a" />
        </.radio_group>
        """)

      refute html =~ ~s(type="hidden")
    end

    test "an untouched radio group is not aria-invalid, a submitted empty one is" do
      untouched = field([{"can't be blank", []}], nil, %{"email" => "", "_unused_email" => ""})
      submitted = field([{"can't be blank", []}], nil, %{"email" => ""})

      assigns = %{field: untouched}

      html =
        rendered_to_string(~H"""
        <.radio_group field={@field}><.radio_group_item value="a" id="a" /></.radio_group>
        """)

      refute html =~ ~s(aria-invalid=")

      assigns = %{field: submitted}

      html =
        rendered_to_string(~H"""
        <.radio_group field={@field}><.radio_group_item value="a" id="a" /></.radio_group>
        """)

      assert html =~ ~s(aria-invalid="true")
    end

    test "form_label and form_message follow the same used-input rule as the controls" do
      untouched = field([{"can't be blank", []}], nil, %{"email" => "", "_unused_email" => ""})
      assigns = %{field: untouched}

      html =
        rendered_to_string(~H"""
        <.form_label field={@field}>Email</.form_label>
        <.form_message field={@field} />
        """)

      refute html =~ "text-destructive"
      refute html =~ "can&#39;t be blank"

      assigns = %{field: invalid_field()}

      html =
        rendered_to_string(~H"""
        <.form_label field={@field}>Email</.form_label>
        <.form_message field={@field} />
        """)

      assert html =~ "text-destructive"
      assert html =~ "can&#39;t be blank"
    end

    test "form_message always shows explicitly passed errors" do
      untouched = field([{"can't be blank", []}], nil, %{"email" => "", "_unused_email" => ""})
      assigns = %{field: untouched}

      html = rendered_to_string(~H"<.form_message field={@field} errors={[~s(custom)]} />")

      assert html =~ "custom"
    end

    test "invalid?/1 without :used_input (no field) still reads errors" do
      assert Helpers.invalid?(%{errors: ["bad"]})
      refute Helpers.invalid?(%{errors: ["bad"], used_input: false})
    end
  end

  describe "Helpers.put_aria_invalid/1" do
    test "adds aria-invalid to rest when errors are present" do
      assigns = %{__changed__: %{}, errors: ["bad"], rest: %{}}
      assert %{rest: %{"aria-invalid": "true"}} = Helpers.put_aria_invalid(assigns)
    end

    test "keeps an explicitly passed aria-invalid" do
      assigns = %{__changed__: %{}, errors: ["bad"], rest: %{"aria-invalid": "false"}}
      assert %{rest: %{"aria-invalid": "false"}} = Helpers.put_aria_invalid(assigns)
    end

    test "leaves assigns untouched without errors" do
      assigns = %{__changed__: %{}, errors: [], rest: %{}}
      assert Helpers.put_aria_invalid(assigns) == assigns
    end
  end

  describe "input" do
    test "sets aria-invalid when the field has errors" do
      assigns = %{field: invalid_field()}
      html = rendered_to_string(~H"<.input field={@field} />")

      assert html =~ ~s(aria-invalid="true")
      for class <- @invalid_classes, do: assert(html =~ class)
    end

    test "omits aria-invalid when the field is valid" do
      assigns = %{field: valid_field()}
      html = rendered_to_string(~H"<.input field={@field} />")

      refute html =~ ~s(aria-invalid=")
      assert html =~ "shadow-xs"
    end

    test "an explicit aria-invalid wins over the field" do
      assigns = %{field: invalid_field()}
      html = rendered_to_string(~H|<.input field={@field} aria-invalid="false" />|)

      assert html =~ ~s(aria-invalid="false")
      refute html =~ ~s(aria-invalid="true")
    end

    test "aria-invalid can be set without a field" do
      assigns = %{}
      html = rendered_to_string(~H|<.input aria-invalid="true" />|)
      assert html =~ ~s(aria-invalid="true")
    end
  end

  describe "textarea" do
    test "sets aria-invalid and uses shadcn v4 classes" do
      assigns = %{field: invalid_field()}
      html = rendered_to_string(~H"<.textarea field={@field} />")

      assert html =~ ~s(aria-invalid="true")
      assert html =~ "shadow-xs"
      assert html =~ "min-h-16"
      for class <- @invalid_classes, do: assert(html =~ class)
    end

    test "omits aria-invalid when the field is valid" do
      assigns = %{field: valid_field()}
      html = rendered_to_string(~H"<.textarea field={@field} />")
      refute html =~ ~s(aria-invalid=")
    end
  end

  describe "checkbox" do
    test "sets aria-invalid on the checkbox input, not the hidden input" do
      assigns = %{field: invalid_field()}
      html = rendered_to_string(~H"<.checkbox field={@field} />")

      assert html =~ ~s(<input type="hidden" name="user[email]" value="false">)
      assert html =~ ~r/<input type="checkbox"[^>]*aria-invalid="true"/
      for class <- @invalid_classes, do: assert(html =~ class)
    end

    test "neutralises the @tailwindcss/forms focus ring" do
      assigns = %{}
      html = rendered_to_string(~H|<.checkbox name="terms" />|)

      assert html =~ "focus:ring-0"
      assert html =~ "focus:ring-offset-0"
      assert html =~ "bg-transparent"
    end

    test "replaces the @tailwindcss/forms white tick with a currentColor indicator" do
      assigns = %{}
      html = rendered_to_string(~H|<.checkbox name="terms" />|)

      for class <-
            ~w(appearance-none checked:bg-none indeterminate:bg-none checked:text-primary-foreground before:bg-current checked:before:opacity-100 indeterminate:before:opacity-100) do
        assert html =~ class
      end

      assert html =~ "checked:bg-primary"
      assert html =~ "indeterminate:bg-primary"
      assert html =~ "before:[mask-image:url(data:image/svg+xml,"
      assert html =~ "indeterminate:before:[mask-image:url(data:image/svg+xml,"
      assert html =~ ~s(data-slot="checkbox")
    end
  end

  describe "switch" do
    test "sets aria-invalid on the role=switch root" do
      assigns = %{field: invalid_field(false)}
      html = rendered_to_string(~H|<.switch id="s" field={@field} />|)

      assert html =~ ~r/role="switch"[^>]*aria-invalid="true"|aria-invalid="true"[^>]*role="switch"/s
      for class <- @invalid_classes, do: assert(html =~ class)
    end

    test "uses shadcn v4 geometry and supports size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="a" />
        <.switch id="b" size="sm" />
        """)

      assert html =~ ~s(data-size="default")
      assert html =~ ~s(data-size="sm")
      assert html =~ ~s(data-slot="switch-thumb")
      assert html =~ "data-[size=default]:h-[1.15rem]"
      assert html =~ "data-[state=checked]:translate-x-[calc(100%-2px)]"
      refute html =~ "border-2"
      refute html =~ "shadow-lg"
    end
  end

  describe "radio_group" do
    test "sets aria-invalid on the root and styles items through the named group" do
      assigns = %{field: invalid_field("a")}

      html =
        rendered_to_string(~H"""
        <.radio_group field={@field}>
          <.radio_group_item id="a" value="a" />
        </.radio_group>
        """)

      assert html =~ ~s(aria-invalid="true")
      assert html =~ "group/radio-group"
      assert html =~ "group-aria-invalid/radio-group:not-aria-[invalid=false]:border-destructive"
      for class <- @invalid_classes, do: assert(html =~ class)
    end

    test "omits aria-invalid when the field is valid" do
      assigns = %{field: valid_field()}

      html =
        rendered_to_string(~H"""
        <.radio_group field={@field}>
          <.radio_group_item id="a" value="a" />
        </.radio_group>
        """)

      refute html =~ ~s(aria-invalid=")
    end
  end

  describe "select" do
    test "marks the root data-invalid and styles the trigger through the named group" do
      assigns = %{field: invalid_field()}

      html =
        rendered_to_string(~H"""
        <.select field={@field} id="fruit">
          <.select_trigger>
            <.select_value placeholder="Pick" />
          </.select_trigger>
          <.select_content>
            <.select_item value="apple">Apple</.select_item>
          </.select_content>
        </.select>
        """)

      assert html =~ ~s(data-invalid="true")
      assert html =~ "group/select"
      assert html =~ "group-data-[invalid=true]/select:not-aria-[invalid=false]:border-destructive"
      assert html =~ "shadow-xs"
      for class <- @invalid_classes, do: assert(html =~ class)
    end

    test "omits data-invalid when the field is valid" do
      assigns = %{field: valid_field()}

      html =
        rendered_to_string(~H"""
        <.select field={@field} id="fruit">
          <.select_trigger>
            <.select_value placeholder="Pick" />
          </.select_trigger>
        </.select>
        """)

      refute html =~ "data-invalid"
    end
  end

  describe "select trigger" do
    test "follows shadcn v4: w-fit, data-size, data-slot, muted placeholder" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select_trigger size="sm"><.select_value placeholder="Pick" /></.select_trigger>
        """)

      assert html =~ ~s(data-slot="select-trigger")
      assert html =~ ~s(data-size="sm")
      assert html =~ ~s(data-slot="select-value")
      assert html =~ "w-fit"
      refute html =~ "w-full"
      assert html =~ "data-[placeholder]:text-muted-foreground"
      assert html =~ "data-[size=sm]:h-8"
    end
  end

  describe "sidebar input" do
    test "matches shadcn's sidebar-input classes" do
      assigns = %{}
      html = rendered_to_string(~H"<.sidebar_input />")

      assert html =~ ~s(data-slot="sidebar-input")
      refute html =~ ~s(data-slot="input")
      assert html =~ "shadow-none"
      refute html =~ "ring-sidebar-ring"
    end
  end

  describe "toggle" do
    test "sets aria-invalid on the toggle button, not the hidden checkbox" do
      assigns = %{field: invalid_field(false)}
      html = rendered_to_string(~H|<.toggle field={@field}>B</.toggle>|)

      assert html =~ ~r/<button[^>]*aria-invalid="true"/
      refute input_tag(html, ~s(type="checkbox")) =~ "aria-invalid"
      assert html =~ ~s(data-slot="toggle")
      for class <- @invalid_classes, do: assert(html =~ class)
    end

    test "an explicit aria-invalid moves to the button and wins" do
      assigns = %{field: invalid_field(false)}
      html = rendered_to_string(~H|<.toggle field={@field} aria-invalid="false">B</.toggle>|)

      assert html =~ ~r/<button[^>]*aria-invalid="false"/
      refute html =~ ~s(aria-invalid="true")
    end

    test "omits aria-invalid when the field is valid" do
      assigns = %{field: field([], false)}
      html = rendered_to_string(~H|<.toggle field={@field}>B</.toggle>|)

      refute html =~ "aria-invalid="
    end
  end

  describe "destructive variants" do
    test "button and badge use text-white like shadcn v4" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button variant="destructive">Delete</.button>
        <.badge variant="destructive">Error</.badge>
        """)

      refute html =~ "text-destructive-foreground"
      assert html =~ "text-white"
      assert html =~ "dark:bg-destructive/60"
    end
  end

  describe "sidebar outline menu button" do
    test "uses the oklch token directly instead of wrapping it in hsl()" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_menu_button variant="outline">Item</.sidebar_menu_button>
        """)

      assert html =~ "shadow-[0_0_0_1px_var(--sidebar-border)]"
      assert html =~ "hover:shadow-[0_0_0_1px_var(--sidebar-accent)]"
      refute html =~ "hsl("
    end
  end
end
