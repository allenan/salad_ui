defmodule SaladUI.ClassMergeTest do
  use ExUnit.Case, async: true

  alias SaladUI.ClassMerge

  doctest ClassMerge

  defp merge(input), do: ClassMerge.merge(input)

  describe "Tailwind v4 syntax" do
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
      assert merge("bg-linear-to-r bg-linear-45") == "bg-linear-45"
      assert merge("bg-linear-to-r bg-radial") == "bg-radial"
      assert merge("bg-conic-45 bg-none") == "bg-none"
      assert merge("bg-linear-to-r bg-red-500") == "bg-linear-to-r bg-red-500"
    end

    test "text-shadow has a size group and a color group" do
      assert merge("text-shadow-sm text-shadow-lg") == "text-shadow-lg"
      assert merge("text-shadow-red-500 text-shadow-blue-500/50") == "text-shadow-blue-500/50"
      assert merge("text-shadow-lg text-shadow-red-500") == "text-shadow-lg text-shadow-red-500"
      # not text color
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

    test "arbitrary values with any characters" do
      assert merge("after:content-['+'] after:content-['−']") == "after:content-['−']"

      assert merge("min-w-[calc(var(--w)+--spacing(7))] min-w-0") == "min-w-0"
    end
  end

  describe "Tailwind v3 classes" do
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
      # as in tailwind-merge v3, bare `outline` is an outline width
      assert merge("outline outline-2") == "outline-2"
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

    test "unknown classes are kept in place, the rest still merge" do
      assert merge("not-typeset not-prose p-2 p-4") == "not-typeset not-prose p-4"
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

  # Expected values checked against tailwind-merge 3.7.0's twMerge.
  @v4_groups [
    mask: [
      {"mask-linear-from-10% mask-linear-from-50%", "mask-linear-from-50%"},
      {"mask-linear-from-10% mask-linear-from-red-500", "mask-linear-from-10% mask-linear-from-red-500"},
      {"mask-[url(a.png)] mask-none", "mask-none"},
      {"mask-(--m) mask-[url(a.png)]", "mask-[url(a.png)]"},
      {"mask-radial-at-top mask-radial-at-center", "mask-radial-at-center"},
      {"mask-radial-circle mask-radial-ellipse", "mask-radial-ellipse"},
      {"mask-radial-closest-side mask-radial-farthest-corner", "mask-radial-farthest-corner"},
      {"mask-t-from-50% mask-b-from-50%", "mask-t-from-50% mask-b-from-50%"},
      {"mask-add mask-intersect", "mask-intersect"},
      {"mask-alpha mask-luminance", "mask-luminance"},
      {"mask-type-alpha mask-type-luminance", "mask-type-luminance"},
      {"mask-clip-border mask-no-clip", "mask-no-clip"},
      {"mask-top mask-position-[1px]", "mask-position-[1px]"},
      {"mask-cover mask-size-(--s)", "mask-size-(--s)"},
      {"mask-no-repeat mask-repeat-x", "mask-repeat-x"}
    ],
    "bg size and position": [
      {"bg-cover bg-size-(--x)", "bg-size-(--x)"},
      {"bg-contain bg-size-[10px]", "bg-size-[10px]"},
      {"bg-auto bg-(size:--x)", "bg-(size:--x)"},
      {"bg-size-[10px] bg-red-500", "bg-size-[10px] bg-red-500"},
      {"bg-red-500 bg-(size:--x)", "bg-red-500 bg-(size:--x)"},
      {"bg-position-[1px] bg-top", "bg-top"},
      {"bg-center bg-(position:--p)", "bg-(position:--p)"},
      {"bg-top bg-red-500", "bg-top bg-red-500"},
      {"bg-[url(a.png)] bg-(image:--i)", "bg-(image:--i)"},
      {"bg-(--brand) bg-red-500", "bg-red-500"}
    ],
    "font size with line height": [
      {"text-sm/6 leading-7", "text-sm/6 leading-7"},
      {"leading-7 text-sm/6", "text-sm/6"},
      {"leading-none text-sm", "text-sm"},
      {"text-sm/6 text-lg", "text-lg"},
      {"text-lg/7 text-lg/8", "text-lg/8"},
      {"text-red-500 text-sm/6", "text-red-500 text-sm/6"},
      {"text-sm/[1.5] text-base", "text-base"}
    ],
    "logical and physical sides": [
      {"ps-2 pl-4", "ps-2 pl-4"},
      {"pl-4 ps-2", "pl-4 ps-2"},
      {"ps-4 px-2", "px-2"},
      {"px-2 ps-4", "px-2 ps-4"},
      {"ps-0 pe-0 p-2", "p-2"},
      {"-ms-2 ms-4", "ms-4"},
      {"ms-2 mx-4", "mx-4"},
      {"inset-s-2 start-4", "start-4"},
      {"start-0 inset-x-2", "inset-x-2"},
      {"start-0 end-0 inset-0", "inset-0"},
      {"border-s-2 border-l-4", "border-s-2 border-l-4"},
      {"border-s-2 border-x-4", "border-x-4"},
      {"border-s-red-500 border-x-blue-500", "border-x-blue-500"},
      {"rounded-ss-lg rounded-s-md", "rounded-s-md"},
      {"rounded-s-md rounded-ss-lg", "rounded-s-md rounded-ss-lg"},
      {"rounded-ee-lg rounded-md", "rounded-md"},
      {"scroll-ms-2 scroll-mx-4", "scroll-mx-4"},
      {"scroll-ps-2 scroll-p-4", "scroll-p-4"}
    ],
    sizes: [
      {"w-6 size-4", "size-4"},
      {"size-4 w-6", "size-4 w-6"},
      {"w-5 h-3 size-10 w-12", "size-10 w-12"},
      {"min-h-4 min-h-(--x)", "min-h-(--x)"},
      {"max-h-none max-h-96", "max-h-96"},
      {"inline-full inline-auto", "inline-auto"},
      {"h-svh h-dvh w-svw w-dvw", "h-dvh w-dvw"}
    ],
    "shadows, rings and outlines": [
      {"shadow-xs shadow-2xs", "shadow-2xs"},
      {"shadow-inner shadow-lg", "shadow-lg"},
      {"shadow-(--s) shadow-md", "shadow-md"},
      {"shadow-(color:--c) shadow-md", "shadow-(color:--c) shadow-md"},
      {"inset-shadow-xs inset-shadow-sm", "inset-shadow-sm"},
      {"inset-shadow-xs inset-shadow-red-500", "inset-shadow-xs inset-shadow-red-500"},
      {"text-shadow-none text-shadow-2xl", "text-shadow-2xl"},
      {"drop-shadow-sm drop-shadow-red-500", "drop-shadow-sm drop-shadow-red-500"},
      {"outline-hidden outline-none", "outline-none"},
      {"outline-hidden outline-2", "outline-hidden outline-2"},
      {"ring-[3px] ring-(--w)", "ring-[3px] ring-(--w)"},
      {"ring-[3px] ring-(length:--w)", "ring-(length:--w)"}
    ],
    "other v4 groups": [
      {"field-sizing-content field-sizing-fixed", "field-sizing-fixed"},
      {"wrap-anywhere wrap-break-word", "wrap-break-word"},
      {"scheme-light scheme-only-dark", "scheme-only-dark"},
      {"font-(family-name:--f) font-sans", "font-sans"},
      {"font-(--w) font-bold", "font-bold"},
      {"font-stretch-50% font-stretch-expanded", "font-stretch-expanded"},
      {"items-baseline items-baseline-last", "items-baseline-last"},
      {"justify-center justify-center-safe", "justify-center-safe"},
      {"@container @container/main", "@container/main"},
      {"@container/a @container/b", "@container/b"}
    ],
    "variants and important": [
      {"*:p-2 *:p-4", "*:p-4"},
      {"*:p-2 **:p-4", "*:p-2 **:p-4"},
      {"before:*:p-2 *:before:p-4", "before:*:p-2 *:before:p-4"},
      {"hover:focus:p-2 focus:hover:p-4", "focus:hover:p-4"},
      {"[&>svg]:size-4 [&>svg]:size-6", "[&>svg]:size-6"},
      {"bg-red-500! bg-blue-500!", "bg-blue-500!"},
      {"bg-red-500! !bg-blue-500", "!bg-blue-500"},
      {"hover:bg-red-500! hover:bg-blue-500", "hover:bg-red-500! hover:bg-blue-500"}
    ]
  ]

  describe "Tailwind v4 groups callers override" do
    for {group, cases} <- @v4_groups do
      test "#{group}" do
        for {input, expected} <- unquote(Macro.escape(cases)) do
          assert merge(input) == expected, "merge(#{inspect(input)})"
        end
      end
    end
  end

  describe "differences from tailwind-merge" do
    test "the Tailwind v3 bg-gradient-to-* is a background image, not a color" do
      # tailwind-merge 3.7.0 gives "bg-gradient-to-b" (it reads it as a color)
      assert merge("bg-muted bg-gradient-to-b") == "bg-muted bg-gradient-to-b"
      assert merge("bg-linear-to-r bg-gradient-to-l") == "bg-gradient-to-l"
      assert merge("bg-gradient-to-l bg-none") == "bg-none"
    end
  end

  # tailwind-merge 3.7.0's own twMerge test cases (packages/tailwind-merge/tests),
  # as {input, expected}. The important-modifier cases with a leading `!` and a
  # postfix (`!text-lg/7 !text-sm`) follow its main branch, which fixed them.
  @tailwind_merge_cases [
    {"arbitrary-properties.test.ts",
     [
       {"[paint-order:markers] [paint-order:normal]", "[paint-order:normal]"},
       {"[paint-order:markers] [--my-var:2rem] [paint-order:normal] [--my-var:4px]",
        "[paint-order:normal] [--my-var:4px]"},
       {"[paint-order:markers] hover:[paint-order:normal]", "[paint-order:markers] hover:[paint-order:normal]"},
       {"hover:[paint-order:markers] hover:[paint-order:normal]", "hover:[paint-order:normal]"},
       {"hover:focus:[paint-order:markers] focus:hover:[paint-order:normal]", "focus:hover:[paint-order:normal]"},
       {"[paint-order:markers] [paint-order:normal] [--my-var:2rem] lg:[--my-var:4px]",
        "[paint-order:normal] [--my-var:2rem] lg:[--my-var:4px]"},
       {"bg-[#B91C1C] bg-radial-[at_50%_75%] bg-radial-[at_25%_25%]", "bg-[#B91C1C] bg-radial-[at_25%_25%]"},
       {"[-unknown-prop:::123:::] [-unknown-prop:url(https://hi.com)]", "[-unknown-prop:url(https://hi.com)]"},
       {"![some:prop] [some:other]", "![some:prop] [some:other]"},
       {"![some:prop] [some:other] [some:one] ![some:another]", "[some:one] ![some:another]"}
     ]},
    {"arbitrary-values.test.ts",
     [
       {"m-[2px] m-[10px]", "m-[10px]"},
       {"m-[2px] m-[11svmin] m-[12in] m-[13lvi] m-[14vb] m-[15vmax] m-[16mm] m-[17%] m-[18em] m-[19px] m-[10dvh]",
        "m-[10dvh]"},
       {"h-[10px] h-[11cqw] h-[12cqh] h-[13cqi] h-[14cqb] h-[15cqmin] h-[16cqmax]", "h-[16cqmax]"},
       {"z-20 z-[99]", "z-[99]"},
       {"my-[2px] m-[10rem]", "m-[10rem]"},
       {"cursor-pointer cursor-[grab]", "cursor-[grab]"},
       {"m-[2px] m-[calc(100%-var(--arbitrary))]", "m-[calc(100%-var(--arbitrary))]"},
       {"m-[2px] m-[length:var(--mystery-var)]", "m-[length:var(--mystery-var)]"},
       {"opacity-10 opacity-[0.025]", "opacity-[0.025]"},
       {"scale-75 scale-[1.7]", "scale-[1.7]"},
       {"brightness-90 brightness-[1.75]", "brightness-[1.75]"},
       {"min-h-[0.5px] min-h-[0]", "min-h-[0]"},
       {"text-[0.5px] text-[color:0]", "text-[0.5px] text-[color:0]"},
       {"text-[0.5px] text-(--my-0)", "text-[0.5px] text-(--my-0)"},
       {"hover:m-[2px] hover:m-[length:var(--c)]", "hover:m-[length:var(--c)]"},
       {"hover:focus:m-[2px] focus:hover:m-[length:var(--c)]", "focus:hover:m-[length:var(--c)]"},
       {"border-b border-[color:rgb(var(--color-gray-500-rgb)/50%))]",
        "border-b border-[color:rgb(var(--color-gray-500-rgb)/50%))]"},
       {"border-[color:rgb(var(--color-gray-500-rgb)/50%))] border-b",
        "border-[color:rgb(var(--color-gray-500-rgb)/50%))] border-b"},
       {"border-b border-[color:rgb(var(--color-gray-500-rgb)/50%))] border-some-coloooor",
        "border-b border-some-coloooor"},
       {"grid-rows-[1fr,auto] grid-rows-2", "grid-rows-2"},
       {"grid-rows-[repeat(20,minmax(0,1fr))] grid-rows-3", "grid-rows-3"},
       {"mt-2 mt-[calc(theme(fontSize.4xl)/1.125)]", "mt-[calc(theme(fontSize.4xl)/1.125)]"},
       {"p-2 p-[calc(theme(fontSize.4xl)/1.125)_10px]", "p-[calc(theme(fontSize.4xl)/1.125)_10px]"},
       {"mt-2 mt-[length:theme(someScale.someValue)]", "mt-[length:theme(someScale.someValue)]"},
       {"mt-2 mt-[theme(someScale.someValue)]", "mt-[theme(someScale.someValue)]"},
       {"text-2xl text-[length:theme(someScale.someValue)]", "text-[length:theme(someScale.someValue)]"},
       {"text-2xl text-[calc(theme(fontSize.4xl)/1.125)]", "text-[calc(theme(fontSize.4xl)/1.125)]"},
       {"bg-cover bg-[percentage:30%] bg-[size:200px_100px] bg-[length:200px_100px]",
        "bg-[percentage:30%] bg-[length:200px_100px]"},
       {"bg-none bg-[url(.)] bg-[image:.] bg-[url:.] bg-[linear-gradient(.)] bg-linear-to-r", "bg-linear-to-r"},
       {"border-[color-mix(in_oklab,var(--background),var(--calendar-color)_30%)] border",
        "border-[color-mix(in_oklab,var(--background),var(--calendar-color)_30%)] border"},
       {"font-[400] font-[600]", "font-[600]"},
       {"font-[var(--a)] font-[var(--b)]", "font-[var(--b)]"},
       {"font-[weight:var(--a)] font-[var(--b)]", "font-[var(--b)]"},
       {"font-[400] font-[weight:var(--b)]", "font-[weight:var(--b)]"},
       {"font-[weight:var(--a)] font-[weight:var(--b)]", "font-[weight:var(--b)]"},
       {"font-[family-name:var(--a)] font-[var(--b)]", "font-[family-name:var(--a)] font-[var(--b)]"},
       {"bg-red bg-(--other-red) bg-bottom bg-(position:-my-pos)", "bg-(--other-red) bg-(position:-my-pos)"},
       {"shadow-xs shadow-(shadow:--something) shadow-red shadow-(--some-other-shadow) shadow-(color:--some-color)",
        "shadow-(--some-other-shadow) shadow-(color:--some-color)"},
       {"font-(--a) font-(--b)", "font-(--b)"},
       {"font-(weight:--a) font-(--b)", "font-(--b)"},
       {"font-(family-name:--a) font-(--b)", "font-(family-name:--a) font-(--b)"}
     ]},
    {"arbitrary-variants.test.ts",
     [
       {"[p]:underline [p]:line-through", "[p]:line-through"},
       {"[&>*]:underline [&>*]:line-through", "[&>*]:line-through"},
       {"[&>*]:underline [&>*]:line-through [&_div]:line-through", "[&>*]:line-through [&_div]:line-through"},
       {"supports-[display:grid]:flex supports-[display:grid]:grid", "supports-[display:grid]:grid"},
       {"dark:lg:hover:[&>*]:underline dark:lg:hover:[&>*]:line-through", "dark:lg:hover:[&>*]:line-through"},
       {"dark:lg:hover:[&>*]:underline dark:hover:lg:[&>*]:line-through", "dark:hover:lg:[&>*]:line-through"},
       {"hover:[&>*]:underline [&>*]:hover:line-through", "hover:[&>*]:underline [&>*]:hover:line-through"},
       {"hover:dark:[&>*]:underline dark:hover:[&>*]:underline dark:[&>*]:hover:line-through",
        "dark:hover:[&>*]:underline dark:[&>*]:hover:line-through"},
       {"[@media_screen{@media(hover:hover)}]:underline [@media_screen{@media(hover:hover)}]:line-through",
        "[@media_screen{@media(hover:hover)}]:line-through"},
       {"hover:[@media_screen{@media(hover:hover)}]:underline hover:[@media_screen{@media(hover:hover)}]:line-through",
        "hover:[@media_screen{@media(hover:hover)}]:line-through"},
       {"[&[data-open]]:underline [&[data-open]]:line-through", "[&[data-open]]:line-through"},
       {"[&[data-foo][data-bar]:not([data-baz])]:underline [&[data-foo][data-bar]:not([data-baz])]:line-through",
        "[&[data-foo][data-bar]:not([data-baz])]:line-through"},
       {"[&>*]:[&_div]:underline [&>*]:[&_div]:line-through", "[&>*]:[&_div]:line-through"},
       {"[&>*]:[&_div]:underline [&_div]:[&>*]:line-through", "[&>*]:[&_div]:underline [&_div]:[&>*]:line-through"},
       {"hover:dark:[&>*]:focus:disabled:[&_div]:underline dark:hover:[&>*]:disabled:focus:[&_div]:line-through",
        "dark:hover:[&>*]:disabled:focus:[&_div]:line-through"},
       {"hover:dark:[&>*]:focus:[&_div]:disabled:underline dark:hover:[&>*]:disabled:focus:[&_div]:line-through",
        "hover:dark:[&>*]:focus:[&_div]:disabled:underline dark:hover:[&>*]:disabled:focus:[&_div]:line-through"},
       {"[&>*]:[color:red] [&>*]:[color:blue]", "[&>*]:[color:blue]"},
       {"[&[data-foo][data-bar]:not([data-baz])]:nod:noa:[color:red] [&[data-foo][data-bar]:not([data-baz])]:noa:nod:[color:blue]",
        "[&[data-foo][data-bar]:not([data-baz])]:noa:nod:[color:blue]"}
     ]},
    {"class-group-conflicts.test.ts",
     [
       {"overflow-x-auto overflow-x-hidden", "overflow-x-hidden"},
       {"basis-full basis-auto", "basis-auto"},
       {"w-full w-fit", "w-fit"},
       {"overflow-x-auto overflow-x-hidden overflow-x-scroll", "overflow-x-scroll"},
       {"overflow-x-auto hover:overflow-x-hidden overflow-x-scroll", "hover:overflow-x-hidden overflow-x-scroll"},
       {"overflow-x-auto hover:overflow-x-hidden hover:overflow-x-auto overflow-x-scroll",
        "hover:overflow-x-auto overflow-x-scroll"},
       {"col-span-1 col-span-full", "col-span-full"},
       {"columns-12 columns-auto", "columns-auto"},
       {"columns-auto columns-2xl", "columns-2xl"},
       {"gap-2 gap-px basis-px basis-3", "gap-px basis-3"},
       {"max-w-lg max-w-none", "max-w-none"},
       {"max-w-none max-w-lg", "max-w-lg"},
       {"max-h-96 max-h-none", "max-h-none"},
       {"max-h-none max-h-96", "max-h-96"},
       {"max-h-[300px] max-h-none", "max-h-none"},
       {"max-h-none max-h-screen", "max-h-screen"},
       {"lining-nums tabular-nums diagonal-fractions", "lining-nums tabular-nums diagonal-fractions"},
       {"normal-nums tabular-nums diagonal-fractions", "tabular-nums diagonal-fractions"},
       {"tabular-nums diagonal-fractions normal-nums", "normal-nums"},
       {"tabular-nums proportional-nums", "proportional-nums"}
     ]},
    {"colors.test.ts",
     [
       {"bg-grey-5 bg-hotpink", "bg-hotpink"},
       {"hover:bg-grey-5 hover:bg-hotpink", "hover:bg-hotpink"},
       {"stroke-[hsl(350_80%_0%)] stroke-[10px]", "stroke-[hsl(350_80%_0%)] stroke-[10px]"},
       {"text-sm text-[color(display-p3_1_0_0/50%)]", "text-sm text-[color(display-p3_1_0_0/50%)]"},
       {"text-[color(display-p3_1_0_0/50%)] text-sm", "text-[color(display-p3_1_0_0/50%)] text-sm"},
       {"text-red-500 text-[color(display-p3_1_0_0/50%)]", "text-[color(display-p3_1_0_0/50%)]"},
       {"text-[color(display-p3_1_0_0/50%)] text-red-500", "text-red-500"},
       {"border-2 border-[color(display-p3_1_0_0/50%)]", "border-2 border-[color(display-p3_1_0_0/50%)]"},
       {"border-[color(display-p3_1_0_0/50%)] border-2", "border-[color(display-p3_1_0_0/50%)] border-2"},
       {"stroke-2 stroke-[color(display-p3_1_0_0/50%)]", "stroke-2 stroke-[color(display-p3_1_0_0/50%)]"},
       {"stroke-[color(display-p3_1_0_0/50%)] stroke-2", "stroke-[color(display-p3_1_0_0/50%)] stroke-2"},
       {"text-sm text-[light-dark(white,rgb(0_0_0/50%))]", "text-sm text-[light-dark(white,rgb(0_0_0/50%))]"},
       {"text-[light-dark(white,rgb(0_0_0/50%))] text-sm", "text-[light-dark(white,rgb(0_0_0/50%))] text-sm"},
       {"text-red-500 text-[light-dark(white,rgb(0_0_0/50%))]", "text-[light-dark(white,rgb(0_0_0/50%))]"},
       {"text-[light-dark(white,rgb(0_0_0/50%))] text-red-500", "text-red-500"},
       {"border-2 border-[light-dark(white,rgb(0_0_0/50%))]", "border-2 border-[light-dark(white,rgb(0_0_0/50%))]"},
       {"border-[light-dark(white,rgb(0_0_0/50%))] border-2", "border-[light-dark(white,rgb(0_0_0/50%))] border-2"},
       {"stroke-2 stroke-[light-dark(white,rgb(0_0_0/50%))]", "stroke-2 stroke-[light-dark(white,rgb(0_0_0/50%))]"},
       {"stroke-[light-dark(white,rgb(0_0_0/50%))] stroke-2", "stroke-[light-dark(white,rgb(0_0_0/50%))] stroke-2"}
     ]},
    {"conflicts-across-class-groups.test.ts",
     [
       {"inset-1 inset-x-1", "inset-1 inset-x-1"},
       {"inset-x-1 inset-1", "inset-1"},
       {"inset-x-1 left-1 inset-1", "inset-1"},
       {"inset-x-1 inset-1 left-1", "inset-1 left-1"},
       {"inset-x-1 right-1 inset-1", "inset-1"},
       {"inset-x-1 right-1 inset-x-1", "inset-x-1"},
       {"inset-x-1 right-1 inset-y-1", "inset-x-1 right-1 inset-y-1"},
       {"right-1 inset-x-1 inset-y-1", "inset-x-1 inset-y-1"},
       {"inset-x-1 hover:left-1 inset-1", "hover:left-1 inset-1"},
       {"ps-2 px-4", "px-4"},
       {"pe-2 px-4", "px-4"},
       {"px-4 ps-2", "px-4 ps-2"},
       {"pbs-2 py-4", "py-4"},
       {"ms-2 mx-4", "mx-4"},
       {"mbe-2 my-4", "my-4"},
       {"start-2 inset-x-4", "inset-x-4"},
       {"end-2 inset-x-4", "inset-x-4"},
       {"inset-bs-2 inset-y-4", "inset-y-4"},
       {"border-s-2 border-x-4", "border-x-4"},
       {"border-be-2 border-y-4", "border-y-4"},
       {"border-s-red-500 border-x-blue-500", "border-x-blue-500"},
       {"border-bs-red-500 border-y-blue-500", "border-y-blue-500"},
       {"scroll-ms-2 scroll-mx-4", "scroll-mx-4"},
       {"scroll-mbs-2 scroll-my-4", "scroll-my-4"},
       {"scroll-ps-2 scroll-px-4", "scroll-px-4"},
       {"scroll-pbe-2 scroll-py-4", "scroll-py-4"},
       {"ring shadow", "ring shadow"},
       {"ring-2 shadow-md", "ring-2 shadow-md"},
       {"shadow ring", "shadow ring"},
       {"shadow-md ring-2", "shadow-md ring-2"},
       {"touch-pan-x touch-pan-right", "touch-pan-right"},
       {"touch-none touch-pan-x", "touch-pan-x"},
       {"touch-pan-x touch-none", "touch-none"},
       {"touch-pan-x touch-pan-y touch-pinch-zoom", "touch-pan-x touch-pan-y touch-pinch-zoom"},
       {"touch-manipulation touch-pan-x touch-pan-y touch-pinch-zoom", "touch-pan-x touch-pan-y touch-pinch-zoom"},
       {"touch-pan-x touch-pan-y touch-pinch-zoom touch-auto", "touch-auto"},
       {"overflow-auto inline line-clamp-1", "line-clamp-1"},
       {"line-clamp-1 overflow-auto inline", "line-clamp-1 overflow-auto inline"}
     ]},
    {"content-utilities.test.ts",
     [
       {"content-['hello'] content-[attr(data-content)]", "content-[attr(data-content)]"}
     ]},
    {"important-modifier.test.ts",
     [
       {"font-medium! font-bold!", "font-bold!"},
       {"font-medium! font-bold! font-thin", "font-bold! font-thin"},
       {"right-2! -inset-x-px!", "-inset-x-px!"},
       {"focus:inline! focus:block!", "focus:block!"},
       {"[--my-var:20px]! [--my-var:30px]!", "[--my-var:30px]!"},
       {"font-medium! !font-bold", "!font-bold"},
       {"!font-medium !font-bold", "!font-bold"},
       {"!font-medium !font-bold font-thin", "!font-bold font-thin"},
       {"!right-2 !-inset-x-px", "!-inset-x-px"},
       {"focus:!inline focus:!block", "focus:!block"},
       {"![--my-var:20px] ![--my-var:30px]", "![--my-var:30px]"},
       {"!text-lg/7 !text-sm", "!text-sm"},
       {"!text-lg/7 !text-lg/9", "!text-lg/9"},
       {"!text-lg/7 !text-sm/6", "!text-sm/6"},
       {"!p-4/7 !p-2/9", "!p-2/9"},
       {"!text-lg/[0/1] !text-sm", "!text-sm"},
       {"!text-lg/7 font-medium!", "!text-lg/7 font-medium!"}
     ]},
    {"negative-values.test.ts",
     [
       {"-m-2 -m-5", "-m-5"},
       {"-top-12 -top-2000", "-top-2000"},
       {"-m-2 m-auto", "m-auto"},
       {"top-12 -top-69", "-top-69"},
       {"-right-1 inset-x-1", "inset-x-1"},
       {"hover:focus:-right-1 focus:hover:inset-x-1", "focus:hover:inset-x-1"}
     ]},
    {"non-conflicting-classes.test.ts",
     [
       {"border-t border-white/10", "border-t border-white/10"},
       {"border-t border-white", "border-t border-white"},
       {"text-3.5xl text-black", "text-3.5xl text-black"}
     ]},
    {"non-tailwind-classes.test.ts",
     [
       {"non-tailwind-class inline block", "non-tailwind-class block"},
       {"inline block inline-1", "block inline-1"},
       {"inline block i-inline", "block i-inline"},
       {"focus:inline focus:block focus:inline-1", "focus:block focus:inline-1"}
     ]},
    {"per-side-border-colors.test.ts",
     [
       {"border-t-some-blue border-t-other-blue", "border-t-other-blue"},
       {"border-t-some-blue border-some-blue", "border-some-blue"},
       {"border-some-blue border-s-some-blue", "border-some-blue border-s-some-blue"},
       {"border-e-some-blue border-some-blue", "border-some-blue"}
     ]},
    {"pseudo-variants.test.ts",
     [
       {"empty:p-2 empty:p-3", "empty:p-3"},
       {"hover:empty:p-2 hover:empty:p-3", "hover:empty:p-3"},
       {"read-only:p-2 read-only:p-3", "read-only:p-3"},
       {"group-empty:p-2 group-empty:p-3", "group-empty:p-3"},
       {"peer-empty:p-2 peer-empty:p-3", "peer-empty:p-3"},
       {"group-empty:p-2 peer-empty:p-3", "group-empty:p-2 peer-empty:p-3"},
       {"hover:group-empty:p-2 hover:group-empty:p-3", "hover:group-empty:p-3"},
       {"group-read-only:p-2 group-read-only:p-3", "group-read-only:p-3"}
     ]},
    {"standalone-classes.test.ts",
     [
       {"inline block", "block"},
       {"hover:block hover:inline", "hover:inline"},
       {"hover:block hover:block", "hover:block"},
       {"inline hover:inline focus:inline hover:block hover:focus:block",
        "inline focus:inline hover:block hover:focus:block"},
       {"underline line-through", "line-through"},
       {"line-through no-underline", "no-underline"}
     ]},
    {"tailwind-css-versions.test.ts",
     [
       {"text-red text-lg/7 text-lg/8", "text-red text-lg/8"},
       {"start-0 start-1 end-0 end-1 ps-0 ps-1 pe-0 pe-1 ms-0 ms-1 me-0 me-1 rounded-s-sm rounded-s-md rounded-e-sm rounded-e-md rounded-ss-sm rounded-ss-md rounded-ee-sm rounded-ee-md",
        "start-1 end-1 ps-1 pe-1 ms-1 me-1 rounded-s-md rounded-e-md rounded-ss-md rounded-ee-md"},
       {"start-0 end-0 inset-0 ps-0 pe-0 p-0 ms-0 me-0 m-0 rounded-ss rounded-es rounded-s", "inset-0 p-0 m-0 rounded-s"},
       {"hyphens-auto hyphens-manual", "hyphens-manual"},
       {"from-0% from-10% from-[12.5%] via-0% via-10% via-[12.5%] to-0% to-10% to-[12.5%]",
        "from-[12.5%] via-[12.5%] to-[12.5%]"},
       {"from-0% from-red", "from-0% from-red"},
       {"list-image-none list-image-[url(./my-image.png)] list-image-[var(--value)]", "list-image-[var(--value)]"},
       {"caption-top caption-bottom", "caption-bottom"},
       {"line-clamp-2 line-clamp-none line-clamp-[10]", "line-clamp-[10]"},
       {"delay-150 delay-0 duration-150 duration-0", "delay-0 duration-0"},
       {"justify-normal justify-center justify-stretch", "justify-stretch"},
       {"content-normal content-center content-stretch", "content-stretch"},
       {"whitespace-nowrap whitespace-break-spaces", "whitespace-break-spaces"},
       {"h-svh h-dvh w-svw w-dvw", "h-dvh w-dvw"},
       {"has-[[data-potato]]:p-1 has-[[data-potato]]:p-2 group-has-[:checked]:grid group-has-[:checked]:flex",
        "has-[[data-potato]]:p-2 group-has-[:checked]:flex"},
       {"text-wrap text-pretty", "text-pretty"},
       {"w-5 h-3 size-10 w-12", "size-10 w-12"},
       {"grid-cols-2 grid-cols-subgrid grid-rows-5 grid-rows-subgrid", "grid-cols-subgrid grid-rows-subgrid"},
       {"min-w-0 min-w-50 min-w-px max-w-0 max-w-50 max-w-px", "min-w-px max-w-px"},
       {"forced-color-adjust-none forced-color-adjust-auto", "forced-color-adjust-auto"},
       {"appearance-none appearance-auto", "appearance-auto"},
       {"float-start float-end clear-start clear-end", "float-end clear-end"},
       {"*:p-10 *:p-20 hover:*:p-10 hover:*:p-20", "*:p-20 hover:*:p-20"},
       {"transform-3d transform-flat", "transform-flat"},
       {"rotate-12 rotate-x-2 rotate-none rotate-y-3", "rotate-x-2 rotate-none rotate-y-3"},
       {"perspective-dramatic perspective-none perspective-midrange", "perspective-midrange"},
       {"perspective-origin-center perspective-origin-top-left", "perspective-origin-top-left"},
       {"bg-linear-to-r bg-linear-45", "bg-linear-45"},
       {"bg-linear-to-r bg-radial-[something] bg-conic-10", "bg-conic-10"},
       {"bg-conic bg-conic-10", "bg-conic-10"},
       {"bg-conic-10 bg-conic", "bg-conic"},
       {"bg-radial bg-conic/decreasing", "bg-conic/decreasing"},
       {"bg-red-500 bg-conic", "bg-red-500 bg-conic"},
       {"ring-4 ring-orange inset-ring inset-ring-3 inset-ring-blue", "ring-4 ring-orange inset-ring-3 inset-ring-blue"},
       {"field-sizing-content field-sizing-fixed", "field-sizing-fixed"},
       {"scheme-normal scheme-dark", "scheme-dark"},
       {"font-stretch-expanded font-stretch-[66.66%] font-stretch-50%", "font-stretch-50%"},
       {"col-span-full col-2 row-span-3 row-4", "col-2 row-4"},
       {"via-red-500 via-(--mobile-header-gradient)", "via-(--mobile-header-gradient)"},
       {"via-red-500 via-(length:--mobile-header-gradient)", "via-red-500 via-(length:--mobile-header-gradient)"},
       {"shadow-inner shadow-lg", "shadow-lg"},
       {"shadow-lg shadow-inner", "shadow-inner"},
       {"shadow-initial shadow-inner", "shadow-initial shadow-inner"},
       {"items-baseline items-baseline-last", "items-baseline-last"},
       {"self-baseline self-baseline-last", "self-baseline-last"},
       {"place-content-center place-content-end-safe place-content-center-safe", "place-content-center-safe"},
       {"items-center-safe items-baseline items-end-safe", "items-end-safe"},
       {"wrap-break-word wrap-normal wrap-anywhere", "wrap-anywhere"},
       {"text-shadow-none text-shadow-2xl", "text-shadow-2xl"},
       {"text-shadow-none text-shadow-md text-shadow-red text-shadow-red-500 shadow-red shadow-3xs",
        "text-shadow-md text-shadow-red-500 shadow-red shadow-3xs"},
       {"mask-add mask-subtract", "mask-subtract"},
       {"mask-(--foo) mask-[foo] mask-none mask-linear-1 mask-linear-2 mask-linear-from-[position:test] mask-linear-from-3 mask-linear-to-[position:test] mask-linear-to-3 mask-linear-from-color-red mask-linear-from-color-3 mask-linear-to-color-red mask-linear-to-color-3 mask-t-from-[position:test] mask-t-from-3 mask-t-to-[position:test] mask-t-to-3 mask-t-from-color-red mask-t-from-color-3 mask-radial-(--test) mask-radial-[test] mask-radial-from-[position:test] mask-radial-from-3 mask-radial-to-[position:test] mask-radial-to-3 mask-radial-from-color-red mask-radial-from-color-3",
        "mask-none mask-linear-2 mask-linear-from-3 mask-linear-to-3 mask-linear-from-color-3 mask-linear-to-color-3 mask-t-from-3 mask-t-to-3 mask-t-from-color-3 mask-radial-[test] mask-radial-from-3 mask-radial-to-3 mask-radial-from-color-3"},
       {"mask-(--something) mask-[something] mask-top-left mask-center mask-(position:--var) mask-[position:1px_1px] mask-position-(--var) mask-position-[1px_1px]",
        "mask-[something] mask-position-[1px_1px]"},
       {"mask-(--something) mask-[something] mask-auto mask-[size:foo] mask-(size:--foo) mask-size-[foo] mask-size-(--foo) mask-cover mask-contain",
        "mask-[something] mask-contain"},
       {"mask-type-luminance mask-type-alpha", "mask-type-alpha"},
       {"shadow-md shadow-lg/25 text-shadow-md text-shadow-lg/25", "shadow-lg/25 text-shadow-lg/25"},
       {"drop-shadow-some-color drop-shadow-[#123456] drop-shadow-lg drop-shadow-[10px_0]",
        "drop-shadow-[#123456] drop-shadow-[10px_0]"},
       {"drop-shadow-[#123456] drop-shadow-some-color", "drop-shadow-some-color"},
       {"drop-shadow-2xl drop-shadow-[shadow:foo]", "drop-shadow-[shadow:foo]"},
       {"h-12 h-lh", "h-lh"},
       {"min-h-12 min-h-lh", "min-h-lh"},
       {"max-h-12 max-h-lh", "max-h-lh"},
       {"inset-s-1 inset-s-2", "inset-s-2"},
       {"inset-e-1 inset-e-2", "inset-e-2"},
       {"inset-bs-1 inset-bs-2", "inset-bs-2"},
       {"inset-be-1 inset-be-2", "inset-be-2"},
       {"start-1 inset-s-2", "inset-s-2"},
       {"inset-s-1 start-2", "start-2"},
       {"end-1 inset-e-2", "inset-e-2"},
       {"inset-e-1 end-2", "end-2"},
       {"inset-s-1 inset-e-2 inset-bs-3 inset-be-4 inset-0", "inset-0"},
       {"inset-0 inset-s-1 inset-bs-1", "inset-0 inset-s-1 inset-bs-1"},
       {"inset-y-1 inset-bs-2 inset-be-3", "inset-y-1 inset-bs-2 inset-be-3"},
       {"top-1 inset-bs-2 bottom-3 inset-be-4", "top-1 inset-bs-2 bottom-3 inset-be-4"},
       {"pbs-1 pbs-2", "pbs-2"},
       {"pbe-1 pbe-2", "pbe-2"},
       {"mbs-1 mbs-2", "mbs-2"},
       {"mbe-1 mbe-2", "mbe-2"},
       {"pt-1 pbs-2", "pt-1 pbs-2"},
       {"pb-1 pbe-2", "pb-1 pbe-2"},
       {"mt-1 mbs-2", "mt-1 mbs-2"},
       {"mb-1 mbe-2", "mb-1 mbe-2"},
       {"p-0 pbs-1 pbe-1", "p-0 pbs-1 pbe-1"},
       {"pbs-1 pbe-1 p-0", "p-0"},
       {"m-0 mbs-1 mbe-1", "m-0 mbs-1 mbe-1"},
       {"mbs-1 mbe-1 m-0", "m-0"},
       {"py-1 pbs-2 pbe-3", "py-1 pbs-2 pbe-3"},
       {"my-1 mbs-2 mbe-3", "my-1 mbs-2 mbe-3"},
       {"scroll-pbs-1 scroll-pbs-2", "scroll-pbs-2"},
       {"scroll-pbe-1 scroll-pbe-2", "scroll-pbe-2"},
       {"scroll-mbs-1 scroll-mbs-2", "scroll-mbs-2"},
       {"scroll-mbe-1 scroll-mbe-2", "scroll-mbe-2"},
       {"scroll-pt-1 scroll-pbs-2", "scroll-pt-1 scroll-pbs-2"},
       {"scroll-pb-1 scroll-pbe-2", "scroll-pb-1 scroll-pbe-2"},
       {"scroll-mt-1 scroll-mbs-2", "scroll-mt-1 scroll-mbs-2"},
       {"scroll-mb-1 scroll-mbe-2", "scroll-mb-1 scroll-mbe-2"},
       {"scroll-p-0 scroll-pbs-1 scroll-pbe-1", "scroll-p-0 scroll-pbs-1 scroll-pbe-1"},
       {"scroll-pbs-1 scroll-pbe-1 scroll-p-0", "scroll-p-0"},
       {"scroll-m-0 scroll-mbs-1 scroll-mbe-1", "scroll-m-0 scroll-mbs-1 scroll-mbe-1"},
       {"scroll-mbs-1 scroll-mbe-1 scroll-m-0", "scroll-m-0"},
       {"scroll-py-1 scroll-pbs-2 scroll-pbe-3", "scroll-py-1 scroll-pbs-2 scroll-pbe-3"},
       {"scroll-my-1 scroll-mbs-2 scroll-mbe-3", "scroll-my-1 scroll-mbs-2 scroll-mbe-3"},
       {"border-bs-1 border-bs-2", "border-bs-2"},
       {"border-be-1 border-be-2", "border-be-2"},
       {"border-bs-red border-bs-blue", "border-bs-blue"},
       {"border-be-red border-be-blue", "border-be-blue"},
       {"border-2 border-bs-4 border-be-6", "border-2 border-bs-4 border-be-6"},
       {"border-bs-4 border-be-6 border-2", "border-2"},
       {"border-red border-bs-blue border-be-green", "border-red border-bs-blue border-be-green"},
       {"border-bs-blue border-be-green border-red", "border-red"},
       {"border-y-2 border-bs-4 border-be-6", "border-y-2 border-bs-4 border-be-6"},
       {"border-t-2 border-bs-4 border-b-6 border-be-8", "border-t-2 border-bs-4 border-b-6 border-be-8"},
       {"border-y-red border-bs-blue border-be-green", "border-y-red border-bs-blue border-be-green"},
       {"inline-1/2 inline-3/4", "inline-3/4"},
       {"block-1/2 block-3/4", "block-3/4"},
       {"min-inline-auto min-inline-full", "min-inline-full"},
       {"max-inline-none max-inline-10", "max-inline-10"},
       {"min-block-auto min-block-lh min-block-10", "min-block-10"},
       {"max-block-none max-block-lh max-block-10", "max-block-10"},
       {"inline-2xl inline-3xl", "inline-3xl"},
       {"min-inline-xs min-inline-1/2", "min-inline-1/2"},
       {"max-inline-svw max-inline-xl", "max-inline-xl"},
       {"w-10 inline-20", "w-10 inline-20"},
       {"h-10 block-20", "h-10 block-20"},
       {"size-10 inline-20 block-30", "size-10 inline-20 block-30"},
       {"min-w-10 min-inline-20", "min-w-10 min-inline-20"},
       {"max-h-10 max-block-20", "max-h-10 max-block-20"},
       {~s(font-features-["smcp"] font-features-["onum"]), "font-features-[\"onum\"]"},
       {~s{font-features-[var(--font-features)] font-features-["liga","dlig"]}, ~s(font-features-["liga","dlig"])},
       {"tabular-nums font-features-[\"smcp\"]", "tabular-nums font-features-[\"smcp\"]"},
       {"font-features-[\"smcp\"] normal-nums", "font-features-[\"smcp\"] normal-nums"},
       {"font-sans font-features-[\"smcp\"]", "font-sans font-features-[\"smcp\"]"},
       {"aspect-8/11 aspect-8.5/11", "aspect-8.5/11"},
       {"w-8/11 w-8.5/11", "w-8.5/11"},
       {"inset-1/2 inset-1.25/2.5", "inset-1.25/2.5"},
       {"scrollbar-auto scrollbar-thin scrollbar-none", "scrollbar-none"},
       {"scrollbar-gutter-auto scrollbar-gutter-stable scrollbar-gutter-both", "scrollbar-gutter-both"},
       {"scrollbar-thumb-red-500 scrollbar-thumb-blue-500", "scrollbar-thumb-blue-500"},
       {"scrollbar-thumb-red-500 scrollbar-thumb-red-500/50", "scrollbar-thumb-red-500/50"},
       {"scrollbar-thumb-[#0088cc] scrollbar-thumb-(--thumb-color)", "scrollbar-thumb-(--thumb-color)"},
       {"scrollbar-track-red-500 scrollbar-track-blue-500", "scrollbar-track-blue-500"},
       {"scrollbar-track-red-500 scrollbar-track-[color:var(--track-color)]",
        "scrollbar-track-[color:var(--track-color)]"},
       {"scrollbar-thin scrollbar-thumb-red-500 scrollbar-track-blue-500",
        "scrollbar-thin scrollbar-thumb-red-500 scrollbar-track-blue-500"},
       {"@container @container-normal @container-size", "@container-size"},
       {"@container-[inline-size] @container-(--container-type)", "@container-(--container-type)"},
       {"@container @container-size/sidebar", "@container-size/sidebar"},
       {"@container-normal @container-size/sidebar", "@container-size/sidebar"},
       {"@container-size/sidebar @container", "@container-size/sidebar @container"},
       {"@container/sidebar @container-normal", "@container/sidebar @container-normal"},
       {"@container/sidebar @container-normal/sidebar @container-size/content", "@container-size/content"},
       {"@container/sidebar @container-normal/content @container-size", "@container-normal/content @container-size"},
       {"@container-size @container/sidebar", "@container/sidebar"},
       {"@container-size/[sidebar] @container-normal/(--container-name)", "@container-normal/(--container-name)"},
       {"hover:@container hover:@container-size/sidebar", "hover:@container-size/sidebar"},
       {"hover:@container-size/sidebar hover:@container", "hover:@container-size/sidebar hover:@container"},
       {"@container! @container-size/sidebar!", "@container-size/sidebar!"},
       {"@container-size/sidebar! @container!", "@container-size/sidebar! @container!"},
       {"@container-foo/sidebar @container-size/sidebar", "@container-foo/sidebar @container-size/sidebar"},
       {"zoom-50 zoom-100", "zoom-100"},
       {"zoom-100 zoom-[var(--zoom)]", "zoom-[var(--zoom)]"},
       {"zoom-[1.5] zoom-(--zoom)", "zoom-(--zoom)"},
       {"zoom-50 scale-125", "zoom-50 scale-125"},
       {"tab-2 tab-8", "tab-8"},
       {"tab-8 tab-[12px]", "tab-[12px]"},
       {"tab-[3] tab-(--tab-size)", "tab-(--tab-size)"},
       {"tab-4 tabular-nums", "tab-4 tabular-nums"}
     ]},
    {"tw-merge.test.ts",
     [
       {"mix-blend-normal mix-blend-multiply", "mix-blend-multiply"},
       {"h-10 h-min", "h-min"},
       {"stroke-black stroke-1", "stroke-black stroke-1"},
       {"stroke-2 stroke-[3]", "stroke-[3]"},
       {"outline-black outline-1", "outline-black outline-1"},
       {"grayscale-0 grayscale-[50%]", "grayscale-[50%]"},
       {"grow grow-[2]", "grow-[2]"},
       {"grow grow-[2]", "grow-[2]"}
     ]},
    {"wonky-inputs.test.ts",
     [
       {" block", "block"},
       {"block ", "block"},
       {" block ", "block"},
       {"  block  px-2     py-4  ", "block px-2 py-4"},
       {"  block  px-2        py-4  ", "block px-2 py-4"},
       {"block\npx-2", "block px-2"},
       {"\nblock\npx-2\n", "block px-2"},
       {"  block\n        \n        px-2   \n          py-4  ", "block px-2 py-4"},
       {"\r  block\n\r        \n        px-2   \n          py-4  ", "block px-2 py-4"}
     ]}
  ]

  describe "tailwind-merge test suite" do
    for {file, cases} <- @tailwind_merge_cases do
      test file do
        for {input, expected} <- unquote(Macro.escape(cases)) do
          assert merge(input) == expected, "merge(#{inspect(input)})"
        end
      end
    end
  end
end
