defmodule SaladUI.AspectRatio do
  @moduledoc """
  Displays content within a desired ratio.

  Mirrors Radix's AspectRatio: an outer wrapper reserves the height with
  `padding-bottom`, and the `data-slot="aspect-ratio"` element fills it
  absolutely, so children sized `h-full w-full` (or `absolute inset-0`) always
  match the ratio.

  ## Examples

      <.aspect_ratio ratio={16 / 9} class="rounded-lg bg-muted">
        <img src="/photo.jpg" alt="Photo" class="h-full w-full rounded-lg object-cover" />
      </.aspect_ratio>

      <.aspect_ratio ratio={1} class="rounded-lg bg-muted">...</.aspect_ratio>

      <.aspect_ratio ratio="9/16" class="rounded-lg bg-muted">...</.aspect_ratio>
  """
  use SaladUI, :component

  @doc """
  Renders an aspect-ratio box.

  ## Attributes

  * `:ratio` - Width divided by height. A number (`16 / 9`, `1`, `0.5625`) or
    a `"width/height"` / `"width:height"` string (`"16/9"`, `"4:3"`).
  * `:class` - CSS classes for the ratio element (the one with `data-slot`).
  """
  attr :ratio, :any, required: true, doc: "width / height, as a number or a \"16/9\" string"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def aspect_ratio(assigns) do
    assigns = assign(assigns, :padding, padding_bottom(assigns.ratio))

    ~H"""
    <div
      style={"position: relative; width: 100%; padding-bottom: #{@padding}%;"}
      data-radix-aspect-ratio-wrapper=""
    >
      <div data-slot="aspect-ratio" style="position: absolute; inset: 0;" class={@class} {@rest}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp padding_bottom(ratio) do
    ratio
    |> to_ratio()
    |> then(&(100 / &1))
    |> Float.round(4)
  end

  defp to_ratio(ratio) when is_number(ratio) and ratio > 0, do: ratio

  defp to_ratio(ratio) when is_binary(ratio) do
    case String.split(ratio, ["/", ":"], parts: 2) do
      [w, h] -> parse_number(w) / parse_number(h)
      [n] -> parse_number(n)
    end
  end

  defp to_ratio(ratio), do: raise(ArgumentError, "invalid aspect ratio: #{inspect(ratio)}")

  defp parse_number(str) do
    case Float.parse(String.trim(str)) do
      {n, ""} when n > 0 -> n
      _ -> raise ArgumentError, "invalid aspect ratio part: #{inspect(str)}"
    end
  end
end
