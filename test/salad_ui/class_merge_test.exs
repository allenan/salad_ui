defmodule SaladUI.ClassMergeTest do
  use ExUnit.Case, async: true

  alias SaladUI.ClassMerge

  doctest ClassMerge

  defp merge(input), do: ClassMerge.merge(input)

  describe "Tailwind v4 conflicts TwMerge 0.1 misses" do
    test "the (--var) shorthand conflicts like [var(--var)]" do
      assert merge("w-(--x) w-full") == "w-full"
      assert merge("w-full w-(--x)") == "w-(--x)"
      assert merge("w-[var(--x)] w-(--x)") == "w-(--x)"
      assert merge("h-(--cell-size) h-9") == "h-9"
      assert merge("max-h-(--radix-available-height) max-h-96") == "max-h-96"
      assert merge("size-(--cell-size) size-4") == "size-4"
      assert merge("gap-(--gap) gap-2") == "gap-2"
      assert merge("z-10 z-(--z)") == "z-(--z)"
      assert merge("origin-(--transform-origin) origin-center") == "origin-center"
      assert merge("translate-x-(--x) translate-x-2") == "translate-x-2"
      assert merge("-mx-(--card-spacing) mx-2") == "mx-2"
      assert merge("bg-(--brand) bg-red-500") == "bg-red-500"
    end

    test "a type hint in the shorthand picks the group" do
      assert merge("text-(length:--size) text-sm") == "text-sm"
      assert merge("text-(--color) text-red-500") == "text-red-500"
      # size and color are different groups
      assert merge("text-(length:--size) text-red-500") == "text-(length:--size) text-red-500"
    end

    test "arbitrary variants containing = are compared as modifiers" do
      assert merge("data-[orientation=vertical]:h-full data-[orientation=vertical]:h-auto") ==
               "data-[orientation=vertical]:h-auto"

      assert merge("data-[state=open]:bg-accent data-[state=open]:bg-red-500") == "data-[state=open]:bg-red-500"

      assert merge("group-data-[collapsible=icon]:hidden group-data-[collapsible=icon]:block") ==
               "group-data-[collapsible=icon]:block"

      assert merge("*:data-[slot=x]:p-2 *:data-[slot=x]:p-4") == "*:data-[slot=x]:p-4"

      assert merge("[&_svg:not([class*='size-'])]:size-4 [&_svg:not([class*='size-'])]:size-6") ==
               "[&_svg:not([class*='size-'])]:size-6"
    end

    test "different variant values don't conflict" do
      assert merge("data-[a=b]:p-2 data-[a=c]:p-4") == "data-[a=b]:p-2 data-[a=c]:p-4"
      assert merge("data-[orientation=vertical]:h-full h-auto") == "data-[orientation=vertical]:h-full h-auto"
    end

    test "named group variants" do
      assert merge("group-data-[size=sm]/card:text-sm group-data-[size=sm]/card:text-xs") ==
               "group-data-[size=sm]/card:text-xs"

      assert merge("group-hover/item:opacity-0 group-hover/item:opacity-100") == "group-hover/item:opacity-100"

      assert merge("group-hover/a:opacity-0 group-hover/b:opacity-100") ==
               "group-hover/a:opacity-0 group-hover/b:opacity-100"
    end

    test "variant order doesn't matter, as in tailwind-merge" do
      assert merge("hover:data-[state=open]:p-2 data-[state=open]:hover:p-4") == "data-[state=open]:hover:p-4"
    end

    test "outline-hidden is an outline style" do
      assert merge("outline-hidden outline-none") == "outline-none"
      assert merge("outline-none outline-hidden") == "outline-hidden"
      assert merge("focus-visible:outline-hidden focus-visible:outline-dashed") == "focus-visible:outline-dashed"
      # style and width are different groups
      assert merge("outline-hidden outline-2") == "outline-hidden outline-2"
    end

    test "v4 sizes join their v3 group" do
      assert merge("shadow-2xs shadow-lg") == "shadow-lg"
      assert merge("shadow-xs shadow-sm") == "shadow-sm"
      assert merge("shadow-2xs shadow-red-500") == "shadow-2xs shadow-red-500"
      assert merge("rounded-xs rounded-md") == "rounded-md"
    end

    test "v4 gradients are background images" do
      assert merge("bg-linear-to-r bg-gradient-to-l") == "bg-gradient-to-l"
      assert merge("bg-linear-to-r bg-radial") == "bg-radial"
      assert merge("bg-conic-45 bg-none") == "bg-none"
      assert merge("bg-linear-to-r bg-red-500") == "bg-linear-to-r bg-red-500"
    end

    test "text-shadow has a size group and a color group" do
      assert merge("text-shadow-sm text-shadow-lg") == "text-shadow-lg"
      assert merge("text-shadow-red-500 text-shadow-blue-500/50") == "text-shadow-blue-500/50"
      assert merge("text-shadow-lg text-shadow-red-500") == "text-shadow-lg text-shadow-red-500"
      # not text color (TwMerge alone drops text-shadow-lg here)
      assert merge("text-shadow-lg text-red-500") == "text-shadow-lg text-red-500"
      assert merge("text-shadow-sm text-sm") == "text-shadow-sm text-sm"
    end

    test "inset-shadow and inset-ring" do
      assert merge("inset-shadow-sm inset-shadow-2xs") == "inset-shadow-2xs"
      assert merge("inset-shadow-sm inset-shadow-red-500") == "inset-shadow-sm inset-shadow-red-500"
      assert merge("inset-ring inset-ring-2") == "inset-ring-2"
      assert merge("inset-ring-2 inset-ring-red-500") == "inset-ring-2 inset-ring-red-500"
      assert merge("inset-ring-ring inset-ring-red-500") == "inset-ring-red-500"
      assert merge("inset-0 inset-shadow-sm") == "inset-0 inset-shadow-sm"
    end

    test "other v4-only groups" do
      assert merge("wrap-break-word wrap-anywhere") == "wrap-anywhere"
      assert merge("field-sizing-fixed field-sizing-content") == "field-sizing-content"
      assert merge("scheme-light scheme-dark") == "scheme-dark"
      assert merge("perspective-near perspective-distant") == "perspective-distant"
      assert merge("transform-3d transform-flat") == "transform-flat"
      assert merge("backface-hidden backface-visible") == "backface-visible"
      assert merge("rotate-x-12 rotate-x-45 rotate-y-12") == "rotate-x-45 rotate-y-12"
      assert merge("md:scheme-light md:scheme-dark scheme-light") == "md:scheme-dark scheme-light"
    end

    test "trailing ! is the same as leading !" do
      assert merge("m-0! m-2!") == "m-2!"
      assert merge("p-0! !p-2") == "!p-2"
      assert merge("hover:p-0! hover:p-2!") == "hover:p-2!"
      assert merge("bg-transparent! bg-red-500!") == "bg-red-500!"
      # important and plain classes don't conflict
      assert merge("p-0! p-2") == "p-0! p-2"
    end

    test "arbitrary opacity modifiers" do
      assert merge("bg-red-500/[0.5] bg-blue-500") == "bg-blue-500"
      assert merge("bg-red-500/(--alpha) bg-blue-500") == "bg-blue-500"
    end

    test "arbitrary values with characters TwMerge can't parse" do
      assert merge("after:content-['+'] after:content-['−']") == "after:content-['−']"

      assert merge("min-w-[calc(var(--w)+--spacing(7))] min-w-0") == "min-w-0"
    end
  end

  describe "Tailwind v3 behaviour is unchanged" do
    test "padding" do
      assert merge("p-2 px-4 p-3") == "p-3"
      assert merge("px-2 p-3") == "p-3"
      assert merge("p-3 px-2") == "p-3 px-2"
      assert merge("py-1 p-0") == "p-0"
      assert merge("px-2 py-1 px-4") == "py-1 px-4"
      assert merge("has-[>svg]:px-3 has-[>svg]:px-2.5") == "has-[>svg]:px-2.5"
    end

    test "background colors" do
      assert merge("bg-red-500 bg-blue-300") == "bg-blue-300"
      assert merge("bg-primary bg-primary/90") == "bg-primary/90"
      assert merge("bg-red-500 hover:bg-blue-500") == "bg-red-500 hover:bg-blue-500"
      assert merge("bg-[#B91C1C] bg-background") == "bg-background"
    end

    test "sizes" do
      assert merge("h-9 h-12") == "h-12"
      assert merge("w-1/2 w-full") == "w-full"
      assert merge("size-4 size-6") == "size-6"
      assert merge("h-6 size-4") == "size-4"
      assert merge("size-4 h-6") == "size-4 h-6"
      assert merge("max-w-xs max-w-sm") == "max-w-sm"
      assert merge("w-[200px] w-full") == "w-full"
    end

    test "other groups" do
      assert merge("text-sm text-red-500") == "text-sm text-red-500"
      assert merge("leading-6 text-sm") == "text-sm"
      assert merge("rounded-t-lg rounded-md") == "rounded-md"
      assert merge("ring-[3px] ring-2") == "ring-2"
      assert merge("ring-ring/50 ring-red-500") == "ring-red-500"
      assert merge("outline outline-2") == "outline outline-2"
      assert merge("!m-0 m-2") == "!m-0 m-2"
      assert merge("[--x:1] [--x:2]") == "[--x:2]"
      assert merge("shrink-0 shrink") == "shrink"
    end

    test "non-Tailwind classes are kept in place" do
      assert merge("my-class p-2 other p-4") == "my-class other p-4"
      assert merge("group/card peer/menu-button") == "group/card peer/menu-button"
    end
  end

  describe "input" do
    test "joins nested lists and skips nil/false" do
      assert merge(["px-2", nil, ["py-1", false, ["p-3"]]]) == "p-3"
      assert merge(["a", ["b"], "a"]) == "a b a"
    end

    test "collapses whitespace" do
      assert merge("  p-2 \n  p-4  ") == "p-4"
      assert merge("") == ""
      assert merge([]) == ""
      assert merge(nil) == ""
    end

    test "classes TwMerge 0.1 crashes on are kept, the rest still merge" do
      assert_raise Protocol.UndefinedError, fn -> TwMerge.merge("no-scrollbar") end

      assert merge("no-scrollbar p-2 p-4") == "no-scrollbar p-4"
      assert merge("p-2 no-scrollbar p-4 no-scrollbar") == "no-scrollbar p-4 no-scrollbar"
    end

    test "results are cached in TwMerge.Cache" do
      input = "p-1 p-2 cache-#{System.unique_integer([:positive])}"
      result = merge(input)

      assert TwMerge.Cache.retrieve({ClassMerge, input}) == result
      assert merge(input) == result
    end
  end
end
