defmodule SaladUI.SliderTest do
  use ComponentCase

  import SaladUI.Slider

  defp thumbs(html), do: Regex.scan(~r/<span[^>]*data-slot="slider-thumb"[^>]*>/, html)
  defp inputs(html), do: Regex.scan(~r/<input type="hidden"[^>]*>/, html)

  describe "slider/1 single value" do
    test "renders root, one thumb and one hidden input with snapped value" do
      assigns = %{}

      html =
        ~H"""
        <.slider id="volume" name="volume" min={10} max={50} step={7} value="32" />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(id="volume")
      assert html =~ ~s(data-slot="slider")
      assert html =~ ~s(data-component="slider")
      assert html =~ ~s(data-part="root")
      assert html =~ ~s(data-orientation="horizontal")
      assert html =~ ~s(data-value="31")
      assert html =~ ~s(data-slot="slider-track")
      assert html =~ ~s(data-slot="slider-range")
      assert length(thumbs(html)) == 1
      assert [[input]] = inputs(html)
      assert input =~ ~s(name="volume")
      assert input =~ ~s(value="31")
      assert html =~ ~s(role="slider")
      assert html =~ ~s(aria-valuenow="31")
      assert html =~ ~s(aria-valuemin="10")
      assert html =~ ~s(aria-valuemax="50")
      refute html =~ "data-disabled"
    end

    test "preserves exact max boundary when step does not divide range" do
      assigns = %{}

      html =
        ~H"""
        <.slider id="boundary" min={0} max={10} step={3} value={10} />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(data-value="10")
      assert html =~ ~s(value="10")
    end

    test "falls back to default-value then min" do
      assigns = %{}

      html =
        ~H"""
        <.slider id="a" default-value={40} />
        <.slider id="b" min={5} />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(data-value="40")
      assert html =~ ~s(data-value="5")
    end

    test "single thumb range fills from the start edge" do
      assigns = %{}

      html =
        ~H"""
        <.slider id="fill" value={30} />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "left: 0%; right: 70%;"
      # 16px thumb: offset = 8 * (1 - 30 / 50) = 3.2px
      assert html =~ "left: calc(30% + 3.2px); transform: translateX(-50%);"
    end

    test "renders disabled state on root and thumbs" do
      assigns = %{}

      html =
        ~H"""
        <.slider id="disabled-volume" disabled value={20} />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(aria-disabled="true")
      assert html =~ ~s(data-disabled="")
      assert html =~ "data-[disabled]:opacity-50"
      assert [[thumb]] = thumbs(html)
      refute thumb =~ "tabindex"
      refute html =~ ~s(<div disabled)
    end
  end

  describe "slider/1 multiple values" do
    test "renders one thumb and one input per value, sorted, with [] name" do
      assigns = %{}

      html =
        ~H"""
        <.slider id="price" name="price" value={[50, 25]} step={5} />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(data-value="25,50")
      assert [[t0], [t1]] = thumbs(html)
      assert t0 =~ ~s(aria-valuenow="25")
      assert t0 =~ ~s(aria-label="Minimum")
      assert t0 =~ ~s(tabindex="0")
      assert t1 =~ ~s(aria-valuenow="50")
      assert t1 =~ ~s(aria-label="Maximum")

      assert [[i0], [i1]] = inputs(html)
      assert i0 =~ ~s(name="price[]")
      assert i0 =~ ~s(value="25")
      assert i1 =~ ~s(name="price[]")
      assert i1 =~ ~s(value="50")

      assert html =~ "left: 25%; right: 50%;"
    end

    test "labels three or more thumbs as Value i of n, overridable" do
      assigns = %{}

      html =
        ~H"""
        <.slider id="multi" value={[10, 20, 70]} step={10} />
        <.slider id="labelled" value={[10, 90]} thumb-labels={["Low", "High"]} />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(aria-label="Value 1 of 3")
      assert html =~ ~s(aria-label="Value 3 of 3")
      assert html =~ ~s(aria-label="Low")
      assert html =~ ~s(aria-label="High")
    end

    test "a single thumb takes its accessible name from the root's aria-label/labelledby" do
      assigns = %{}

      named = rendered_to_string(~H|<.slider id="vol" value={50} aria-label="Volume" />|)
      labelled = rendered_to_string(~H|<.slider id="tmp" value={50} aria-labelledby="tmp-label" />|)
      range = rendered_to_string(~H|<.slider id="rng" value={[1, 9]} aria-labelledby="rng-label" />|)

      assert [[thumb]] = thumbs(named)
      assert thumb =~ ~s(role="slider")
      assert thumb =~ ~s(aria-label="Volume")

      assert [[thumb]] = thumbs(labelled)
      assert thumb =~ ~s(aria-labelledby="tmp-label")

      # Several thumbs keep their own Minimum/Maximum names.
      assert [[min], [max]] = thumbs(range)
      assert min =~ ~s(aria-label="Minimum")
      refute min =~ "aria-labelledby"
      assert max =~ ~s(aria-label="Maximum")
    end

    test "supports fractional steps without float noise" do
      assigns = %{}

      html =
        ~H"""
        <.slider id="temp" value={[0.3, 0.7]} min={0} max={1} step={0.1} />
        <.slider id="noisy" value={0.30000000000000004} min={0} max={1} step={0.1} />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(data-value="0.3,0.7")
      assert html =~ ~s(aria-valuemax="1")
      assert html =~ ~s(data-value="0.3")
      assert html =~ "&quot;step&quot;:0.1"
    end

    test "reads list values from a form field" do
      assigns = %{form: Phoenix.Component.to_form(%{"budget" => ["200", "800"]}, as: :filters)}

      html =
        ~H"""
        <.slider field={@form[:budget]} max={1000} step={50} />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(id="filters_budget")
      assert html =~ ~s(data-value="200,800")
      assert html =~ ~s(name="filters[budget][]")
    end
  end

  describe "slider/1 orientation and direction" do
    test "vertical positions from the bottom" do
      assigns = %{}

      html =
        ~H"""
        <.slider id="eq" value={50} orientation="vertical" class="h-40" />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(data-orientation="vertical")
      assert html =~ ~s(aria-orientation="vertical")
      assert html =~ "data-[orientation=vertical]:flex-col"
      assert html =~ "bottom: 0%; top: 50%;"
      assert html =~ "bottom: calc(50% + 0px); transform: translateY(50%);"
      assert html =~ "h-40"
    end

    test "rtl and inverted flip the start edge" do
      assigns = %{}

      html =
        ~H"""
        <.slider id="rtl" value={75} dir="rtl" />
        <.slider id="inv" value={50} orientation="vertical" inverted />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(dir="rtl")
      assert html =~ "right: 0%; left: 25%;"
      assert html =~ "top: 0%; bottom: 50%;"
      assert html =~ "&quot;dir&quot;:&quot;rtl&quot;"
      assert html =~ "&quot;inverted&quot;:true"
    end

    test "without dir the hook is left to inherit the page direction" do
      assigns = %{}

      html =
        ~H"""
        <.slider id="inherit" value={50} />
        """
        |> rendered_to_string()
        |> clean_string()

      # No `dir` attribute and a null `dir` option: the JS reads the nearest
      # ancestor's `dir` (e.g. `<html dir="rtl">`) instead of forcing ltr.
      refute html =~ ~s(dir=")
      assert html =~ "&quot;dir&quot;:null"
    end
  end
end
