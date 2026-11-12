defmodule SaladUI.Slider do
  @moduledoc """
  An input where the user selects a value, or a range of values, from within a
  given range.

  Pass a single number as `value` for a classic one-thumb slider, or a list of
  numbers to render one thumb per value (two values make a range slider).
  Every thumb is focusable, carries `role="slider"`, and is driven from the
  keyboard independently. Each thumb also renders its own hidden form input.

  ## Examples

  Single value:

      <.slider id="volume" value={75} max={100} step={1} class="mx-auto w-full max-w-xs" />

  Range (two thumbs):

      <.slider id="price" value={[25, 50]} max={100} step={5} name="price" />

  Multiple thumbs:

      <.slider id="stops" value={[10, 20, 70]} max={100} step={10} />

  Vertical:

      <.slider id="eq-low" value={50} orientation="vertical" class="h-40" />

  Fractional steps:

      <.slider id="temperature" value={[0.3, 0.7]} min={0} max={1} step={0.1} />

  Bound to a form field (a list value posts as `name[]`):

      <.slider field={@form[:budget]} value={[200, 800]} max={1000} step={50} />

  ## Form submission

  Each thumb renders an `<input type="hidden">`. With one thumb the input uses
  `name` as-is; with several thumbs `[]` is appended so the form posts a list,
  e.g. `%{"price" => ["25", "50"]}`.

  ## Keyboard

  On a focused thumb:

  * `ArrowRight` / `ArrowUp` - increase by `step` (`ArrowLeft`/`ArrowRight`
    flip when `dir="rtl"` or `inverted`).
  * `ArrowLeft` / `ArrowDown` - decrease by `step`.
  * `Shift` + arrow, `PageUp` / `PageDown` - change by `10 * step`.
  * `Home` / `End` - jump to `min` / `max`.

  Thumbs may pass each other; values stay sorted and focus follows the
  moved thumb (Radix behaviour).

  ## Component events

  * `:on-value-changed` - Maps the `value-changed` event, fired when a drag
    ends or a key changes the value. The payload has `value` (a number with one
    thumb, a list with several) and `values` (always a list).

  ## Server commands

  * `"setValue"` - Sets the slider value. Requires a `:value` param (a number
    or a list of numbers).
  """
  use SaladUI, :component

  # Width/height of the thumb in px (`size-4`). Used to pre-compute the
  # in-bounds offset on the server; the JS refines it with the measured size.
  @thumb_size 16

  @doc """
  Renders a slider.

  ## Options

  * `:id` - Required unique identifier for the slider.
  * `:value` - Current value: a number for one thumb, or a list of numbers for
    one thumb per value. Defaults to `default-value`, then `min`.
  * `:default-value` - Value used when `value` is not provided.
  * `:min` / `:max` - Range bounds (defaults 0 and 100). Integers or floats.
  * `:step` - Step size (defaults to 1). Fractional steps like `0.1` work.
  * `:min-steps-between-thumbs` - Minimum number of steps kept between
    neighbouring thumbs (defaults to 0).
  * `:orientation` - `"horizontal"` (default) or `"vertical"`.
  * `:dir` - `"ltr"` or `"rtl"`; `"rtl"` makes a horizontal slider start at the right.
  * `:inverted` - Reverse the visual direction.
  * `:disabled` - Disable the slider.
  * `:name` / `:field` - Form binding.
  * `:thumb-labels` - Optional list of `aria-label`s, one per thumb.
  * `:on-value-changed` - Handler for the `value-changed` event.
  * `:class` - Additional CSS classes for the root.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the slider"
  attr :name, :any, default: nil, doc: "Name of the slider for form submission (`[]` is appended with several thumbs)"

  attr :min, :any, default: 0, doc: "Minimum value (number)"
  attr :max, :any, default: 100, doc: "Maximum value (number)"
  attr :step, :any, default: 1, doc: "Step size for value changes (number, may be fractional)"

  attr :value, :any,
    default: nil,
    doc: "Current value: a number for one thumb, or a list of numbers for one thumb per value"

  attr :"default-value", :any, default: nil, doc: "Value used when `value` is not provided (number or list)"

  attr :"min-steps-between-thumbs", :integer,
    default: 0,
    doc: "Minimum number of steps kept between neighbouring thumbs"

  attr :orientation, :string,
    default: "horizontal",
    values: ~w(horizontal vertical),
    doc: "Slider orientation"

  attr :dir, :string, default: nil, values: [nil, "ltr", "rtl"], doc: "Reading direction"
  attr :inverted, :boolean, default: false, doc: "Reverse the visual direction of the slider"
  attr :disabled, :boolean, default: false, doc: "Whether the slider is disabled"

  attr :"thumb-labels", :list,
    default: nil,
    doc: "aria-labels, one per thumb. Defaults to Minimum/Maximum for two thumbs and \"Value i of n\" for more"

  attr :"on-value-changed", :any, default: nil, doc: "Handler for value changed event"
  attr :field, Phoenix.HTML.FormField, doc: "A form field struct retrieved from the form, for example: @form[:volume]"
  attr :class, :string, default: nil
  attr :rest, :global

  def slider(assigns) do
    assigns = prepare_assign(assigns)

    min = to_number(assigns.min, 0)
    max = to_number(assigns.max, 100)
    step = normalize_step(to_number(assigns.step, 1))
    decimals = Enum.max([decimal_count(step), decimal_count(min)])

    values =
      assigns.value
      |> List.wrap()
      |> case do
        [] -> [min]
        list -> list
      end
      |> Enum.map(&(&1 |> to_number(min) |> snap_to_step(min, max, step, decimals)))
      |> Enum.sort()

    start_edge = start_edge(assigns.orientation != "vertical", assigns.dir == "rtl", assigns.inverted)
    percents = Enum.map(values, &percent(&1, min, max))

    options = %{
      min: min,
      max: max,
      step: step,
      minStepsBetweenThumbs: assigns[:"min-steps-between-thumbs"],
      orientation: assigns.orientation,
      dir: assigns.dir || "ltr",
      inverted: assigns.inverted,
      defaultValue: assigns[:"default-value"],
      disabled: assigns.disabled
    }

    assigns =
      assign(assigns,
        min: min,
        max: max,
        thumbs: build_thumbs(values, percents, start_edge, assigns[:"thumb-labels"] || []),
        input_name: input_name(assigns.name, length(values)),
        data_value: Enum.map_join(values, ",", &format_number/1),
        range_style: range_style(start_edge, percents),
        event_map: json(event_mappings(assigns)),
        options: json(options)
      )

    ~H"""
    <div
      data-slot="slider"
      id={@id}
      class={
        classes([
          "relative flex w-full touch-none items-center select-none data-[disabled]:opacity-50 data-[orientation=vertical]:h-full data-[orientation=vertical]:min-h-44 data-[orientation=vertical]:w-auto data-[orientation=vertical]:flex-col",
          @class
        ])
      }
      data-component="slider"
      data-state="idle"
      data-value={@data_value}
      data-orientation={@orientation}
      data-disabled={@disabled && ""}
      aria-disabled={@disabled && "true"}
      dir={@dir}
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      data-part="root"
      {@rest}
    >
      <span
        data-slot="slider-track"
        data-part="track"
        data-orientation={@orientation}
        data-disabled={@disabled && ""}
        class="relative grow overflow-hidden rounded-full bg-muted data-[orientation=horizontal]:h-1.5 data-[orientation=horizontal]:w-full data-[orientation=vertical]:h-full data-[orientation=vertical]:w-1.5"
      >
        <span
          data-slot="slider-range"
          data-part="range"
          data-orientation={@orientation}
          data-disabled={@disabled && ""}
          class="absolute bg-primary data-[orientation=horizontal]:h-full data-[orientation=vertical]:w-full"
          style={@range_style}
        />
      </span>
      <span
        :for={thumb <- @thumbs}
        data-slot="slider-thumb"
        data-part="thumb"
        data-index={thumb.index}
        data-orientation={@orientation}
        data-disabled={@disabled && ""}
        role="slider"
        tabindex={if @disabled, do: nil, else: "0"}
        aria-label={thumb.label}
        aria-valuemin={format_number(@min)}
        aria-valuemax={format_number(@max)}
        aria-valuenow={thumb.value}
        aria-orientation={@orientation}
        aria-disabled={@disabled && "true"}
        class="absolute block size-4 shrink-0 rounded-full border border-primary bg-white shadow-sm ring-ring/50 transition-[color,box-shadow] hover:ring-4 focus-visible:ring-4 focus-visible:outline-hidden data-[disabled]:pointer-events-none"
        style={thumb.style}
      />
      <input
        :for={thumb <- @thumbs}
        type="hidden"
        data-index={thumb.index}
        name={@input_name}
        value={thumb.value}
      />
    </div>
    """
  end

  # Edge the value grows away from, mirroring Radix:
  # horizontal LTR -> left, RTL or inverted -> right; vertical -> bottom, inverted -> top.
  defp start_edge(true = _horizontal, rtl?, inverted?), do: if(rtl? == inverted?, do: "left", else: "right")
  defp start_edge(false, _rtl?, inverted?), do: if(inverted?, do: "top", else: "bottom")

  defp end_edge("left"), do: "right"
  defp end_edge("right"), do: "left"
  defp end_edge("bottom"), do: "top"
  defp end_edge("top"), do: "bottom"

  defp normalize_step(step) when step > 0, do: step
  defp normalize_step(_step), do: 1

  defp build_thumbs(values, percents, start_edge, labels) do
    count = length(values)

    values
    |> Enum.zip(percents)
    |> Enum.with_index()
    |> Enum.map(fn {{value, pct}, index} ->
      %{
        index: index,
        value: format_number(value),
        style: thumb_style(start_edge, pct),
        label: Enum.at(labels, index) || default_label(index, count)
      }
    end)
  end

  # Radix appends `[]` with several thumbs so the form posts a list.
  defp input_name(nil, _count), do: nil

  defp input_name(name, count) when count > 1 do
    name = to_string(name)
    if String.ends_with?(name, "[]"), do: name, else: name <> "[]"
  end

  defp input_name(name, _count), do: name

  # A single thumb fills from the start edge; several span min..max thumb.
  defp range_style(edge, [pct]), do: range_style(edge, 0, 100 - pct)
  defp range_style(edge, percents), do: range_style(edge, Enum.min(percents), 100 - Enum.max(percents))

  defp range_style(edge, start_pct, end_pct) do
    "#{edge}: #{format_number(start_pct)}%; #{end_edge(edge)}: #{format_number(end_pct)}%;"
  end

  # Keeps the thumb inside the track: the centre sits at `half` at 0% and at
  # `100% - half` at 100% (same in-bounds offset Radix computes).
  defp thumb_style(edge, pct) do
    half = @thumb_size / 2
    offset = Float.round(half * (1 - pct / 50), 4)

    "#{edge}: calc(#{format_number(pct)}% + #{format_number(offset)}px); transform: #{thumb_transform(edge)};"
  end

  defp thumb_transform("left"), do: "translateX(-50%)"
  defp thumb_transform("right"), do: "translateX(50%)"
  defp thumb_transform("bottom"), do: "translateY(50%)"
  defp thumb_transform("top"), do: "translateY(-50%)"

  defp default_label(_index, 1), do: nil
  defp default_label(0, 2), do: "Minimum"
  defp default_label(1, 2), do: "Maximum"
  defp default_label(index, count), do: "Value #{index + 1} of #{count}"

  defp percent(_value, min, max) when max == min, do: 0

  defp percent(value, min, max) do
    Float.round((value - min) / (max - min) * 100, 4)
  end

  # Snap a value to the nearest step while preserving exact boundaries.
  defp snap_to_step(value, min, max, step, decimals) do
    cond do
      value <= min ->
        min

      value >= max ->
        max

      true ->
        snapped = min + step * round((value - min) / step)
        snapped |> round_to(decimals) |> max(min) |> min(max)
    end
  end

  defp round_to(value, _decimals) when is_integer(value), do: value
  defp round_to(value, decimals), do: Float.round(value * 1.0, decimals)

  defp decimal_count(number) when is_integer(number), do: 0

  defp decimal_count(number) when is_float(number) do
    case number |> Float.to_string() |> String.split(".") do
      [_int, "0"] -> 0
      [_int, frac] -> if String.contains?(frac, "e"), do: 10, else: String.length(frac)
      _ -> 0
    end
  end

  defp to_number(value, _default) when is_number(value), do: value

  defp to_number(value, default) when is_binary(value) do
    case Float.parse(value) do
      {number, _rest} -> number
      :error -> default
    end
  end

  defp to_number(_value, default), do: default

  # Render integral floats without a trailing ".0" so `31.0` posts as "31".
  defp format_number(number) when is_integer(number), do: Integer.to_string(number)

  defp format_number(number) when is_float(number) do
    if number == Float.round(number), do: number |> trunc() |> Integer.to_string(), else: Float.to_string(number)
  end
end
