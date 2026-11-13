defmodule SaladUI.ClassMerge do
  @moduledoc """
  Tailwind v4 class merging, used by `classes/1` in every component.

  It works like shadcn's `cn()`: when two classes set the same thing, the later
  one wins, so a caller's `class` overrides a component's default:

      iex> SaladUI.ClassMerge.merge(["px-2 py-1 bg-primary", "p-3 bg-red-500"])
      "p-3 bg-red-500"

      iex> SaladUI.ClassMerge.merge("data-[orientation=vertical]:h-full data-[orientation=vertical]:h-auto")
      "data-[orientation=vertical]:h-auto"

      iex> SaladUI.ClassMerge.merge("text-sm/6 leading-tight mask-linear-from-10% mask-linear-from-50%")
      "text-sm/6 leading-tight mask-linear-from-50%"

  This is a port of [tailwind-merge](https://github.com/dcastil/tailwind-merge)
  3.7.0, the library shadcn/ui's `cn()` uses: the same class groups, conflicts,
  validators and parsing rules, so a class list merges here as it does in
  shadcn. That includes Tailwind v4 syntax such as the `(--var)` shorthand
  (`w-(--x) w-full` gives `w-full`), the trailing important (`p-0!`), the
  `text-sm/6` line-height postfix, logical properties (`ps-*`, `ms-*`,
  `rounded-s-*`, ...), `mask-*`, `bg-size-*`/`bg-position-*`, `inset-shadow-*`,
  `text-shadow-*`, `wrap-*`, `field-sizing-*` and `scheme-*`.

  One difference: the Tailwind v3 name `bg-gradient-to-*` is a background
  image here, so it doesn't remove a `bg-<color>` (tailwind-merge reads it as a
  color).

  Classes it doesn't recognise are kept as they are, in place. Results are
  cached in the `TwMerge.Cache` table, so `TwMerge.Cache` must be in your
  supervision tree, as before.
  """

  defmodule Config do
    @moduledoc false
    # tailwind-merge 3.7.0's default config (src/lib/default-config.ts), with
    # the theme scales inlined. A class definition is one of:
    #
    #   "part-part"              - a class (or "" for the current part)
    #   :validator               - a validator for the rest of the class
    #   {"part-part", [defs]}    - a nested object: defs below that path
    #
    # The order of groups and definitions matters, as in tailwind-merge:
    # validators on the same path are tried in the order they were added.

    @vv [:arbitrary_variable, :arbitrary_value]

    @theme_color [:any]
    @theme_font [:any_non_arbitrary]
    @theme_text [:tshirt_size]
    @theme_font_weight ~w(thin extralight light normal medium semibold bold extrabold black)
    @theme_tracking ~w(tighter tight normal wide wider widest)
    @theme_leading ~w(none tight snug normal relaxed loose)
    @theme_breakpoint [:tshirt_size]
    @theme_container [:tshirt_size]
    @theme_spacing ["px", :number]
    @theme_radius [:tshirt_size]
    @theme_shadow [:tshirt_size]
    @theme_inset_shadow [:tshirt_size]
    @theme_text_shadow [:tshirt_size]
    @theme_drop_shadow [:tshirt_size]
    @theme_blur [:tshirt_size]
    @theme_perspective ~w(dramatic near normal midrange distant none)
    @theme_aspect ["video"]
    @theme_ease ~w(in out in-out)
    @theme_animate ~w(spin ping pulse bounce)

    @scale_break ~w(auto avoid all avoid-page page left right column)
    @scale_position ~w(center top bottom left right top-left left-top top-right right-top bottom-right right-bottom bottom-left left-bottom)
    @scale_position_with_arbitrary @scale_position ++ @vv
    @scale_overflow ~w(auto hidden clip visible scroll)
    @scale_overscroll ~w(auto contain none)
    @scale_spacing @vv ++ @theme_spacing
    @scale_inset [:fraction, "full", "auto"] ++ @scale_spacing
    @scale_grid_template [:integer, "none", "subgrid"] ++ @vv
    @scale_grid_start_and_end ["auto", {"span", ["full", :integer] ++ @vv}, :integer] ++ @vv
    @scale_grid_start_or_end [:integer, "auto"] ++ @vv
    @scale_grid_auto ~w(auto min max fr) ++ @vv
    @scale_align_primary ~w(start end center between around evenly stretch baseline center-safe end-safe)
    @scale_align_secondary ~w(start end center stretch center-safe end-safe)
    @scale_margin ["auto"] ++ @scale_spacing
    @scale_sizing [:fraction | ~w(auto full dvw dvh lvw lvh svw svh min max fit)] ++ @scale_spacing
    @scale_sizing_inline @theme_container ++ [:fraction | ~w(screen full dvw lvw svw min max fit)] ++ @scale_spacing
    @scale_sizing_block [:fraction | ~w(screen full lh dvh lvh svh min max fit)] ++ @scale_spacing
    @scale_color @theme_color ++ @vv
    @scale_bg_position @scale_position ++ [:arbitrary_variable_position, :arbitrary_position, {"position", @vv}]
    @scale_bg_repeat ["no-repeat", {"repeat", ["", "x", "y", "space", "round"]}]
    @scale_bg_size ["auto", "cover", "contain", :arbitrary_variable_size, :arbitrary_size, {"size", @vv}]
    @scale_gradient_stop [:percent, :arbitrary_variable_length, :arbitrary_length]
    @scale_radius ["", "none", "full"] ++ @theme_radius ++ @vv
    @scale_border_width ["", :number, :arbitrary_variable_length, :arbitrary_length]
    @scale_line_style ~w(solid dashed dotted double)
    @scale_blend_mode ~w(normal multiply screen overlay darken lighten color-dodge color-burn hard-light soft-light difference exclusion hue saturation color luminosity)
    @scale_mask_position [:number, :percent, :arbitrary_variable_position, :arbitrary_position]
    @scale_blur ["", "none"] ++ @theme_blur ++ @vv
    @scale_rotate ["none", :number] ++ @vv
    @scale_skew [:number] ++ @vv
    @scale_translate [:fraction, "full"] ++ @scale_spacing
    @shadow_values [:arbitrary_variable_shadow, :arbitrary_shadow]

    @cursors ~w(auto default pointer wait text move help not-allowed none context-menu progress cell crosshair vertical-text alias copy no-drop grab grabbing all-scroll col-resize row-resize n-resize e-resize s-resize w-resize ne-resize nw-resize se-resize sw-resize ew-resize ns-resize nesw-resize nwse-resize zoom-in zoom-out)

    @display ~w(block inline-block inline flex inline-flex table inline-table table-caption table-cell table-column table-column-group table-footer-group table-header-group table-row-group table-row flow-root grid inline-grid contents list-item hidden)

    @font_stretch ~w(ultra-condensed extra-condensed condensed semi-condensed normal semi-expanded expanded extra-expanded ultra-expanded)

    # Groups named after their class prefix: {"p", [{"p", scale}]}.
    defp simple(ids, scale), do: for(id <- ids, do: {id, [{id, scale}]})

    # mask-image-<side>-from-pos, -to-pos, -from-color, -to-color
    defp mask_gradient(side) do
      [
        {"mask-image-#{side}-from-pos", [{"mask-#{side}-from", @scale_mask_position}]},
        {"mask-image-#{side}-to-pos", [{"mask-#{side}-to", @scale_mask_position}]},
        {"mask-image-#{side}-from-color", [{"mask-#{side}-from", @scale_color}]},
        {"mask-image-#{side}-to-color", [{"mask-#{side}-to", @scale_color}]}
      ]
    end

    # border-w, border-w-x, ... -> border, border-x, ...
    defp border_sides(group, scale) do
      for side <- ["" | ~w(x y s e bs be t r b l)] do
        suffix = if side == "", do: "", else: "-" <> side
        {group <> suffix, [{"border" <> suffix, scale}]}
      end
    end

    def class_groups do
      Enum.concat([
        [
          {"aspect", [{"aspect", ["auto", "square", :fraction, :arbitrary_value, :arbitrary_variable] ++ @theme_aspect}]},
          {"container", ["container"]},
          {"container-type", [{"@container", ["", "normal", "size"] ++ @vv}]},
          {"container-named", [:named_container_query]},
          {"columns", [{"columns", [:number, "auto", :arbitrary_value, :arbitrary_variable] ++ @theme_container}]},
          {"break-after", [{"break-after", @scale_break}]},
          {"break-before", [{"break-before", @scale_break}]},
          {"break-inside", [{"break-inside", ~w(auto avoid avoid-page avoid-column)}]},
          {"box-decoration", [{"box-decoration", ~w(slice clone)}]},
          {"box", [{"box", ~w(border content)}]},
          {"display", @display},
          {"sr", ~w(sr-only not-sr-only)},
          {"float", [{"float", ~w(right left none start end)}]},
          {"clear", [{"clear", ~w(left right both none start end)}]},
          {"isolation", ~w(isolate isolation-auto)},
          {"object-fit", [{"object", ~w(contain cover fill none scale-down)}]},
          {"object-position", [{"object", @scale_position_with_arbitrary}]}
        ],
        simple(~w(overflow overflow-x overflow-y), @scale_overflow),
        simple(~w(overscroll overscroll-x overscroll-y), @scale_overscroll),
        [{"position", ~w(static fixed absolute relative sticky)}],
        simple(~w(inset inset-x inset-y), @scale_inset),
        [
          {"start", [{"inset-s", @scale_inset}, {"start", @scale_inset}]},
          {"end", [{"inset-e", @scale_inset}, {"end", @scale_inset}]}
        ],
        simple(~w(inset-bs inset-be top right bottom left), @scale_inset),
        [
          {"visibility", ~w(visible invisible collapse)},
          {"z", [{"z", [:integer, "auto"] ++ @vv}]},
          {"basis", [{"basis", [:fraction, "full", "auto"] ++ @theme_container ++ @scale_spacing}]},
          {"flex-direction", [{"flex", ~w(row row-reverse col col-reverse)}]},
          {"flex-wrap", [{"flex", ~w(nowrap wrap wrap-reverse)}]},
          {"flex", [{"flex", [:number, :fraction, "auto", "initial", "none", :arbitrary_value]}]},
          {"grow", [{"grow", ["", :number] ++ @vv}]},
          {"shrink", [{"shrink", ["", :number] ++ @vv}]},
          {"order", [{"order", [:integer, "first", "last", "none"] ++ @vv}]},
          {"grid-cols", [{"grid-cols", @scale_grid_template}]},
          {"col-start-end", [{"col", @scale_grid_start_and_end}]},
          {"col-start", [{"col-start", @scale_grid_start_or_end}]},
          {"col-end", [{"col-end", @scale_grid_start_or_end}]},
          {"grid-rows", [{"grid-rows", @scale_grid_template}]},
          {"row-start-end", [{"row", @scale_grid_start_and_end}]},
          {"row-start", [{"row-start", @scale_grid_start_or_end}]},
          {"row-end", [{"row-end", @scale_grid_start_or_end}]},
          {"grid-flow", [{"grid-flow", ~w(row col dense row-dense col-dense)}]},
          {"auto-cols", [{"auto-cols", @scale_grid_auto}]},
          {"auto-rows", [{"auto-rows", @scale_grid_auto}]}
        ],
        simple(~w(gap gap-x gap-y), @scale_spacing),
        [
          {"justify-content", [{"justify", @scale_align_primary ++ ["normal"]}]},
          {"justify-items", [{"justify-items", @scale_align_secondary ++ ["normal"]}]},
          {"justify-self", [{"justify-self", ["auto" | @scale_align_secondary]}]},
          {"align-content", [{"content", ["normal" | @scale_align_primary]}]},
          {"align-items", [{"items", @scale_align_secondary ++ [{"baseline", ["", "last"]}]}]},
          {"align-self", [{"self", ["auto" | @scale_align_secondary] ++ [{"baseline", ["", "last"]}]}]},
          {"place-content", [{"place-content", @scale_align_primary}]},
          {"place-items", [{"place-items", @scale_align_secondary ++ ["baseline"]}]},
          {"place-self", [{"place-self", ["auto" | @scale_align_secondary]}]}
        ],
        simple(~w(p px py ps pe pbs pbe pt pr pb pl), @scale_spacing),
        simple(~w(m mx my ms me mbs mbe mt mr mb ml), @scale_margin),
        [
          {"space-x", [{"space-x", @scale_spacing}]},
          {"space-x-reverse", ["space-x-reverse"]},
          {"space-y", [{"space-y", @scale_spacing}]},
          {"space-y-reverse", ["space-y-reverse"]},
          {"size", [{"size", @scale_sizing}]},
          {"inline-size", [{"inline", ["auto" | @scale_sizing_inline]}]},
          {"min-inline-size", [{"min-inline", ["auto" | @scale_sizing_inline]}]},
          {"max-inline-size", [{"max-inline", ["none" | @scale_sizing_inline]}]},
          {"block-size", [{"block", ["auto" | @scale_sizing_block]}]},
          {"min-block-size", [{"min-block", ["auto" | @scale_sizing_block]}]},
          {"max-block-size", [{"max-block", ["none" | @scale_sizing_block]}]},
          {"w", [{"w", @theme_container ++ ["screen"] ++ @scale_sizing}]},
          {"min-w", [{"min-w", @theme_container ++ ["screen", "none"] ++ @scale_sizing}]},
          {"max-w",
           [
             {"max-w", @theme_container ++ ["screen", "none", "prose", {"screen", @theme_breakpoint}] ++ @scale_sizing}
           ]},
          {"h", [{"h", ["screen", "lh"] ++ @scale_sizing}]},
          {"min-h", [{"min-h", ["screen", "lh", "none"] ++ @scale_sizing}]},
          {"max-h", [{"max-h", ["screen", "lh", "none"] ++ @scale_sizing}]},
          {"font-size", [{"text", ["base"] ++ @theme_text ++ [:arbitrary_variable_length, :arbitrary_length]}]},
          {"font-smoothing", ~w(antialiased subpixel-antialiased)},
          {"font-style", ~w(italic not-italic)},
          {"font-weight", [{"font", @theme_font_weight ++ [:arbitrary_variable_weight, :arbitrary_weight]}]},
          {"font-stretch", [{"font-stretch", @font_stretch ++ [:percent, :arbitrary_value]}]},
          {"font-family", [{"font", [:arbitrary_variable_family_name, :arbitrary_family_name] ++ @theme_font}]},
          {"font-features", [{"font-features", [:arbitrary_value]}]},
          {"fvn-normal", ["normal-nums"]},
          {"fvn-ordinal", ["ordinal"]},
          {"fvn-slashed-zero", ["slashed-zero"]},
          {"fvn-figure", ~w(lining-nums oldstyle-nums)},
          {"fvn-spacing", ~w(proportional-nums tabular-nums)},
          {"fvn-fraction", ~w(diagonal-fractions stacked-fractions)},
          {"tracking", [{"tracking", @theme_tracking ++ @vv}]},
          {"line-clamp", [{"line-clamp", [:number, "none", :arbitrary_variable, :arbitrary_number]}]},
          {"leading", [{"leading", ["none"] ++ @theme_leading ++ @scale_spacing}]},
          {"list-image", [{"list-image", ["none" | @vv]}]},
          {"list-style-position", [{"list", ~w(inside outside)}]},
          {"list-style-type", [{"list", ["disc", "decimal", "none" | @vv]}]},
          {"text-alignment", [{"text", ~w(left center right justify start end)}]},
          {"placeholder-color", [{"placeholder", @scale_color}]},
          {"text-color", [{"text", @scale_color}]},
          {"text-decoration", ~w(underline overline line-through no-underline)},
          {"text-decoration-style", [{"decoration", @scale_line_style ++ ["wavy"]}]},
          {"text-decoration-thickness",
           [{"decoration", [:number, "from-font", "auto", :arbitrary_variable, :arbitrary_length]}]},
          {"text-decoration-color", [{"decoration", @scale_color}]},
          {"underline-offset", [{"underline-offset", [:number, "auto" | @vv]}]},
          {"text-transform", ~w(uppercase lowercase capitalize normal-case)},
          {"text-overflow", ~w(truncate text-ellipsis text-clip)},
          {"text-wrap", [{"text", ~w(wrap nowrap balance pretty)}]},
          {"indent", [{"indent", @scale_spacing}]},
          {"tab-size", [{"tab", [:integer | @vv]}]},
          {"vertical-align", [{"align", ~w(baseline top middle bottom text-top text-bottom sub super) ++ @vv}]},
          {"whitespace", [{"whitespace", ~w(normal nowrap pre pre-line pre-wrap break-spaces)}]},
          {"break", [{"break", ~w(normal words all keep)}]},
          {"wrap", [{"wrap", ~w(break-word anywhere normal)}]},
          {"hyphens", [{"hyphens", ~w(none manual auto)}]},
          {"content", [{"content", ["none" | @vv]}]},
          {"bg-attachment", [{"bg", ~w(fixed local scroll)}]},
          {"bg-clip", [{"bg-clip", ~w(border padding content text)}]},
          {"bg-origin", [{"bg-origin", ~w(border padding content)}]},
          {"bg-position", [{"bg", @scale_bg_position}]},
          {"bg-repeat", [{"bg", @scale_bg_repeat}]},
          {"bg-size", [{"bg", @scale_bg_size}]},
          {"bg-image",
           [
             {"bg",
              [
                "none",
                {"linear", [{"to", ~w(t tr r br b bl l tl)}, :integer | @vv]},
                {"radial", ["" | @vv]},
                {"conic", ["", :integer | @vv]},
                # Not in tailwind-merge, which reads the Tailwind v3 name
                # `bg-gradient-to-r` as a color and drops `bg-<color>` for it.
                {"gradient-to", ~w(t tr r br b bl l tl)},
                :arbitrary_variable_image,
                :arbitrary_image
              ]}
           ]},
          {"bg-color", [{"bg", @scale_color}]}
        ],
        [
          {"gradient-from-pos", [{"from", @scale_gradient_stop}]},
          {"gradient-via-pos", [{"via", @scale_gradient_stop}]},
          {"gradient-to-pos", [{"to", @scale_gradient_stop}]},
          {"gradient-from", [{"from", @scale_color}]},
          {"gradient-via", [{"via", @scale_color}]},
          {"gradient-to", [{"to", @scale_color}]}
        ],
        simple(
          ~w(rounded rounded-s rounded-e rounded-t rounded-r rounded-b rounded-l rounded-ss rounded-se rounded-ee rounded-es rounded-tl rounded-tr rounded-br rounded-bl),
          @scale_radius
        ),
        border_sides("border-w", @scale_border_width),
        [
          {"divide-x", [{"divide-x", @scale_border_width}]},
          {"divide-x-reverse", ["divide-x-reverse"]},
          {"divide-y", [{"divide-y", @scale_border_width}]},
          {"divide-y-reverse", ["divide-y-reverse"]},
          {"border-style", [{"border", @scale_line_style ++ ["hidden", "none"]}]},
          {"divide-style", [{"divide", @scale_line_style ++ ["hidden", "none"]}]}
        ],
        border_sides("border-color", @scale_color),
        [
          {"divide-color", [{"divide", @scale_color}]},
          {"outline-style", [{"outline", @scale_line_style ++ ["none", "hidden"]}]},
          {"outline-offset", [{"outline-offset", [:number | @vv]}]},
          {"outline-w", [{"outline", ["", :number, :arbitrary_variable_length, :arbitrary_length]}]},
          {"outline-color", [{"outline", @scale_color}]},
          {"shadow", [{"shadow", ["", "inner", "none"] ++ @theme_shadow ++ @shadow_values}]},
          {"shadow-color", [{"shadow", @scale_color}]},
          {"inset-shadow", [{"inset-shadow", ["none"] ++ @theme_inset_shadow ++ @shadow_values}]},
          {"inset-shadow-color", [{"inset-shadow", @scale_color}]},
          {"ring-w", [{"ring", @scale_border_width}]},
          {"ring-w-inset", ["ring-inset"]},
          {"ring-color", [{"ring", @scale_color}]},
          {"ring-offset-w", [{"ring-offset", [:number, :arbitrary_length]}]},
          {"ring-offset-color", [{"ring-offset", @scale_color}]},
          {"inset-ring-w", [{"inset-ring", @scale_border_width}]},
          {"inset-ring-color", [{"inset-ring", @scale_color}]},
          {"text-shadow", [{"text-shadow", ["none"] ++ @theme_text_shadow ++ @shadow_values}]},
          {"text-shadow-color", [{"text-shadow", @scale_color}]},
          {"opacity", [{"opacity", [:number | @vv]}]},
          {"mix-blend", [{"mix-blend", @scale_blend_mode ++ ["plus-darker", "plus-lighter"]}]},
          {"bg-blend", [{"bg-blend", @scale_blend_mode}]},
          {"mask-clip", [{"mask-clip", ~w(border padding content fill stroke view)}, "mask-no-clip"]},
          {"mask-composite", [{"mask", ~w(add subtract intersect exclude)}]},
          {"mask-image-linear-pos", [{"mask-linear", [:number]}]}
        ],
        Enum.flat_map(~w(linear t r b l x y), &mask_gradient/1),
        [{"mask-image-radial", [{"mask-radial", @vv}]}],
        mask_gradient("radial"),
        [
          {"mask-image-radial-shape", [{"mask-radial", ~w(circle ellipse)}]},
          {"mask-image-radial-size", [{"mask-radial", [{"closest", ~w(side corner)}, {"farthest", ~w(side corner)}]}]},
          {"mask-image-radial-pos", [{"mask-radial-at", @scale_position}]},
          {"mask-image-conic-pos", [{"mask-conic", [:number]}]}
        ],
        mask_gradient("conic"),
        [
          {"mask-mode", [{"mask", ~w(alpha luminance match)}]},
          {"mask-origin", [{"mask-origin", ~w(border padding content fill stroke view)}]},
          {"mask-position", [{"mask", @scale_bg_position}]},
          {"mask-repeat", [{"mask", @scale_bg_repeat}]},
          {"mask-size", [{"mask", @scale_bg_size}]},
          {"mask-type", [{"mask-type", ~w(alpha luminance)}]},
          {"mask-image", [{"mask", ["none" | @vv]}]},
          {"filter", [{"filter", ["", "none" | @vv]}]},
          {"blur", [{"blur", @scale_blur}]},
          {"brightness", [{"brightness", [:number | @vv]}]},
          {"contrast", [{"contrast", [:number | @vv]}]},
          {"drop-shadow", [{"drop-shadow", ["", "none"] ++ @theme_drop_shadow ++ @shadow_values}]},
          {"drop-shadow-color", [{"drop-shadow", @scale_color}]},
          {"grayscale", [{"grayscale", ["", :number | @vv]}]},
          {"hue-rotate", [{"hue-rotate", [:number | @vv]}]},
          {"invert", [{"invert", ["", :number | @vv]}]},
          {"saturate", [{"saturate", [:number | @vv]}]},
          {"sepia", [{"sepia", ["", :number | @vv]}]},
          {"backdrop-filter", [{"backdrop-filter", ["", "none" | @vv]}]},
          {"backdrop-blur", [{"backdrop-blur", @scale_blur}]},
          {"backdrop-brightness", [{"backdrop-brightness", [:number | @vv]}]},
          {"backdrop-contrast", [{"backdrop-contrast", [:number | @vv]}]},
          {"backdrop-grayscale", [{"backdrop-grayscale", ["", :number | @vv]}]},
          {"backdrop-hue-rotate", [{"backdrop-hue-rotate", [:number | @vv]}]},
          {"backdrop-invert", [{"backdrop-invert", ["", :number | @vv]}]},
          {"backdrop-opacity", [{"backdrop-opacity", [:number | @vv]}]},
          {"backdrop-saturate", [{"backdrop-saturate", [:number | @vv]}]},
          {"backdrop-sepia", [{"backdrop-sepia", ["", :number | @vv]}]},
          {"border-collapse", [{"border", ~w(collapse separate)}]}
        ],
        simple(~w(border-spacing border-spacing-x border-spacing-y), @scale_spacing),
        [
          {"table-layout", [{"table", ~w(auto fixed)}]},
          {"caption", [{"caption", ~w(top bottom)}]},
          {"transition", [{"transition", ["", "all", "colors", "opacity", "shadow", "transform", "none" | @vv]}]},
          {"transition-behavior", [{"transition", ~w(normal discrete)}]},
          {"duration", [{"duration", [:number, "initial" | @vv]}]},
          {"ease", [{"ease", ["linear", "initial"] ++ @theme_ease ++ @vv}]},
          {"delay", [{"delay", [:number | @vv]}]},
          {"animate", [{"animate", ["none"] ++ @theme_animate ++ @vv}]},
          {"backface", [{"backface", ~w(hidden visible)}]},
          {"perspective", [{"perspective", @theme_perspective ++ @vv}]},
          {"perspective-origin", [{"perspective-origin", @scale_position_with_arbitrary}]}
        ],
        simple(~w(rotate rotate-x rotate-y rotate-z), @scale_rotate),
        simple(~w(scale scale-x scale-y scale-z), @scale_rotate),
        [{"scale-3d", ["scale-3d"]}],
        simple(~w(skew skew-x skew-y), @scale_skew),
        [
          {"transform", [{"transform", @vv ++ ["", "none", "gpu", "cpu"]}]},
          {"transform-origin", [{"origin", @scale_position_with_arbitrary}]},
          {"transform-style", [{"transform", ~w(3d flat)}]}
        ],
        simple(~w(translate translate-x translate-y translate-z), @scale_translate),
        [
          {"translate-none", ["translate-none"]},
          {"zoom", [{"zoom", [:integer | @vv]}]},
          {"accent", [{"accent", @scale_color}]},
          {"appearance", [{"appearance", ~w(none auto)}]},
          {"caret-color", [{"caret", @scale_color}]},
          {"color-scheme", [{"scheme", ~w(normal dark light light-dark only-dark only-light)}]},
          {"cursor", [{"cursor", @cursors ++ @vv}]},
          {"field-sizing", [{"field-sizing", ~w(fixed content)}]},
          {"pointer-events", [{"pointer-events", ~w(auto none)}]},
          {"resize", [{"resize", ["none", "", "y", "x"]}]},
          {"scroll-behavior", [{"scroll", ~w(auto smooth)}]},
          {"scrollbar-thumb-color", [{"scrollbar-thumb", @scale_color}]},
          {"scrollbar-track-color", [{"scrollbar-track", @scale_color}]},
          {"scrollbar-gutter", [{"scrollbar-gutter", ~w(auto stable both)}]},
          {"scrollbar-w", [{"scrollbar", ~w(auto thin none)}]}
        ],
        simple(
          ~w(scroll-m scroll-mx scroll-my scroll-ms scroll-me scroll-mbs scroll-mbe scroll-mt scroll-mr scroll-mb scroll-ml scroll-p scroll-px scroll-py scroll-ps scroll-pe scroll-pbs scroll-pbe scroll-pt scroll-pr scroll-pb scroll-pl),
          @scale_spacing
        ),
        [
          {"snap-align", [{"snap", ~w(start end center align-none)}]},
          {"snap-stop", [{"snap", ~w(normal always)}]},
          {"snap-type", [{"snap", ~w(none x y both)}]},
          {"snap-strictness", [{"snap", ~w(mandatory proximity)}]},
          {"touch", [{"touch", ~w(auto none manipulation)}]},
          {"touch-x", [{"touch-pan", ~w(x left right)}]},
          {"touch-y", [{"touch-pan", ~w(y up down)}]},
          {"touch-pz", ["touch-pinch-zoom"]},
          {"select", [{"select", ~w(none text all auto)}]},
          {"will-change", [{"will-change", ~w(auto scroll contents transform) ++ @vv}]},
          {"fill", [{"fill", ["none" | @scale_color]}]},
          {"stroke-w", [{"stroke", [:number, :arbitrary_variable_length, :arbitrary_length, :arbitrary_number]}]},
          {"stroke", [{"stroke", ["none" | @scale_color]}]},
          {"forced-color-adjust", [{"forced-color-adjust", ~w(auto none)}]}
        ]
      ])
    end

    def conflicting_groups do
      %{
        "container-named" => ["container-type"],
        "overflow" => ["overflow-x", "overflow-y"],
        "overscroll" => ["overscroll-x", "overscroll-y"],
        "inset" => ~w(inset-x inset-y inset-bs inset-be start end top right bottom left),
        "inset-x" => ~w(start end right left),
        "inset-y" => ~w(inset-bs inset-be top bottom),
        "flex" => ~w(basis grow shrink),
        "gap" => ~w(gap-x gap-y),
        "p" => ~w(px py ps pe pbs pbe pt pr pb pl),
        "px" => ~w(ps pe pr pl),
        "py" => ~w(pbs pbe pt pb),
        "m" => ~w(mx my ms me mbs mbe mt mr mb ml),
        "mx" => ~w(ms me mr ml),
        "my" => ~w(mbs mbe mt mb),
        "size" => ~w(w h),
        "font-size" => ["leading"],
        "fvn-normal" => ~w(fvn-ordinal fvn-slashed-zero fvn-figure fvn-spacing fvn-fraction),
        "fvn-ordinal" => ["fvn-normal"],
        "fvn-slashed-zero" => ["fvn-normal"],
        "fvn-figure" => ["fvn-normal"],
        "fvn-spacing" => ["fvn-normal"],
        "fvn-fraction" => ["fvn-normal"],
        "line-clamp" => ~w(display overflow),
        "rounded" =>
          ~w(rounded-s rounded-e rounded-t rounded-r rounded-b rounded-l rounded-ss rounded-se rounded-ee rounded-es rounded-tl rounded-tr rounded-br rounded-bl),
        "rounded-s" => ~w(rounded-ss rounded-es),
        "rounded-e" => ~w(rounded-se rounded-ee),
        "rounded-t" => ~w(rounded-tl rounded-tr),
        "rounded-r" => ~w(rounded-tr rounded-br),
        "rounded-b" => ~w(rounded-br rounded-bl),
        "rounded-l" => ~w(rounded-tl rounded-bl),
        "border-spacing" => ~w(border-spacing-x border-spacing-y),
        "border-w" =>
          ~w(border-w-x border-w-y border-w-s border-w-e border-w-bs border-w-be border-w-t border-w-r border-w-b border-w-l),
        "border-w-x" => ~w(border-w-s border-w-e border-w-r border-w-l),
        "border-w-y" => ~w(border-w-bs border-w-be border-w-t border-w-b),
        "border-color" =>
          ~w(border-color-x border-color-y border-color-s border-color-e border-color-bs border-color-be border-color-t border-color-r border-color-b border-color-l),
        "border-color-x" => ~w(border-color-s border-color-e border-color-r border-color-l),
        "border-color-y" => ~w(border-color-bs border-color-be border-color-t border-color-b),
        "translate" => ~w(translate-x translate-y translate-none),
        "translate-none" => ~w(translate translate-x translate-y translate-z),
        "scroll-m" =>
          ~w(scroll-mx scroll-my scroll-ms scroll-me scroll-mbs scroll-mbe scroll-mt scroll-mr scroll-mb scroll-ml),
        "scroll-mx" => ~w(scroll-ms scroll-me scroll-mr scroll-ml),
        "scroll-my" => ~w(scroll-mbs scroll-mbe scroll-mt scroll-mb),
        "scroll-p" =>
          ~w(scroll-px scroll-py scroll-ps scroll-pe scroll-pbs scroll-pbe scroll-pt scroll-pr scroll-pb scroll-pl),
        "scroll-px" => ~w(scroll-ps scroll-pe scroll-pr scroll-pl),
        "scroll-py" => ~w(scroll-pbs scroll-pbe scroll-pt scroll-pb),
        "touch" => ~w(touch-x touch-y touch-pz),
        "touch-x" => ["touch"],
        "touch-y" => ["touch"],
        "touch-pz" => ["touch"]
      }
    end

    # Extra conflicts when the class has a postfix: `text-sm/6` also sets the
    # line height.
    def conflicting_group_modifiers, do: %{"font-size" => ["leading"]}

    # Groups whose class may itself contain a `/` (`@container/name`).
    def postfix_lookup_groups, do: ["container-type"]

    # Variants whose position changes what they select, so they aren't sorted.
    def order_sensitive_modifiers,
      do: ~w(* ** after backdrop before details-content file first-letter first-line marker placeholder selection)

    # Builds the lookup tree tailwind-merge calls the class map: each node is
    # `{group, %{part => node}, [{validator, group}]}`, keyed by the classes'
    # `-`-separated parts.
    def class_map do
      Enum.reduce(class_groups(), new_node(), fn {group, defs}, root -> add_defs(root, defs, group) end)
    end

    defp new_node, do: {nil, %{}, []}

    defp add_defs(node, defs, group), do: Enum.reduce(defs, node, &add_def(&2, &1, group))

    defp add_def({_group, next, validators}, "", group), do: {group, next, validators}

    defp add_def(node, class, group) when is_binary(class),
      do: update_path(node, String.split(class, "-"), &add_def(&1, "", group))

    defp add_def(node, {path, defs}, group), do: update_path(node, String.split(path, "-"), &add_defs(&1, defs, group))

    defp add_def({own, next, validators}, validator, group) when is_atom(validator),
      do: {own, next, validators ++ [{validator, group}]}

    defp update_path(node, [], fun), do: fun.(node)

    defp update_path({own, next, validators}, [part | rest], fun) do
      child = Map.get(next, part, new_node())
      {own, Map.put(next, part, update_path(child, rest, fun)), validators}
    end
  end

  @class_map Config.class_map()
  @conflicting_groups Config.conflicting_groups()
  @conflicting_group_modifiers Config.conflicting_group_modifiers()
  @postfix_lookup_groups Config.postfix_lookup_groups()
  @order_sensitive_modifiers Config.order_sensitive_modifiers()

  @doc """
  Joins `input` (a string, or a nested list of strings and `nil`s) and merges
  conflicting Tailwind classes, the later class winning.
  """
  @spec merge(term()) :: String.t()
  def merge(input) do
    classes = TwMerge.join(input)
    key = {__MODULE__, classes}

    case TwMerge.Cache.retrieve(key) do
      nil ->
        merged = do_merge(classes)
        TwMerge.Cache.insert(key, merged)
        merged

      merged ->
        merged
    end
  end

  # tailwind-merge's mergeClassList: walk from the end, keeping a class unless
  # a later class already claimed its group (for the same variants).
  defp do_merge(classes) do
    classes
    |> String.split()
    |> Enum.reverse()
    |> Enum.reduce({[], MapSet.new()}, fn class, acc -> keep_unless_taken(class, conflict_ids(class), acc) end)
    |> elem(0)
    |> Enum.join(" ")
  end

  defp keep_unless_taken(class, nil, {kept, taken}), do: {[class | kept], taken}

  defp keep_unless_taken(class, {id, conflicts}, {kept, taken}) do
    if MapSet.member?(taken, id),
      do: {kept, taken},
      else: {[class | kept], Enum.reduce(conflicts, MapSet.put(taken, id), &MapSet.put(&2, &1))}
  end

  # nil for a class that isn't Tailwind's; otherwise the class's own id and
  # the ids of the groups it overrides.
  defp conflict_ids(class) do
    {modifiers, important?, base, postfix_at} = parse(class)

    with {group, postfix?} <- class_group(base, postfix_at) do
      modifier_id = Enum.join(sort_modifiers(modifiers), ":") <> if(important?, do: "!", else: "")
      conflicts = Enum.map(conflicting_groups(group, postfix?), &{modifier_id, &1})
      {{modifier_id, group}, conflicts}
    end
  end

  defp class_group(base, nil) do
    if group = group_id(base), do: {group, false}
  end

  defp class_group(base, postfix_at) do
    group = group_id(binary_part(base, 0, postfix_at))

    with_postfix =
      if group in @postfix_lookup_groups, do: group_id(base)

    cond do
      with_postfix && with_postfix != group -> {with_postfix, false}
      group -> {group, true}
      full = group_id(base) -> {full, false}
      true -> nil
    end
  end

  defp conflicting_groups(group, true) do
    case Map.fetch(@conflicting_group_modifiers, group) do
      {:ok, modifier_conflicts} -> Map.get(@conflicting_groups, group, []) ++ modifier_conflicts
      :error -> conflicting_groups(group, false)
    end
  end

  defp conflicting_groups(group, false), do: Map.get(@conflicting_groups, group, [])

  # -- parsing -----------------------------------------------------------------

  # Splits `hover:md:bg-red-500/50!` into its variants, the important flag, the
  # base class and the position of a top-level `/` postfix within the base.
  defp parse(class) do
    {modifiers, base_start, slash_at} = scan(class, class, 0, {0, 0}, 0, [], nil)
    with_important = binary_part(class, base_start, byte_size(class) - base_start)
    size = byte_size(with_important)

    {base, important?, offset} =
      cond do
        String.ends_with?(with_important, "!") -> {binary_part(with_important, 0, size - 1), true, 0}
        String.starts_with?(with_important, "!") -> {binary_part(with_important, 1, size - 1), true, 1}
        true -> {with_important, false, 0}
      end

    # A leading `!` shifts the postfix position (tailwind-merge 3.7.0 misses
    # this, so `!text-lg/7 !text-sm` keeps both there; fixed on its main branch).
    postfix_at =
      if slash_at && slash_at > base_start do
        position = slash_at - base_start - offset
        if position <= byte_size(base), do: position
      end

    {modifiers, important?, base, postfix_at}
  end

  # `:` and `/` count only outside `[]` and `()`.
  defp scan(<<":", rest::binary>>, class, i, {0, 0} = depth, start, modifiers, slash_at),
    do: scan(rest, class, i + 1, depth, i + 1, [binary_part(class, start, i - start) | modifiers], slash_at)

  defp scan(<<"/", rest::binary>>, class, i, {0, 0} = depth, start, modifiers, _slash_at),
    do: scan(rest, class, i + 1, depth, start, modifiers, i)

  defp scan(<<c, rest::binary>>, class, i, {brackets, parens}, start, modifiers, slash_at) do
    depth =
      case c do
        ?[ -> {brackets + 1, parens}
        ?] -> {brackets - 1, parens}
        ?( -> {brackets, parens + 1}
        ?) -> {brackets, parens - 1}
        _ -> {brackets, parens}
      end

    scan(rest, class, i + 1, depth, start, modifiers, slash_at)
  end

  defp scan(<<>>, _class, _i, _depth, start, modifiers, slash_at), do: {Enum.reverse(modifiers), start, slash_at}

  # Variants are sorted so their order doesn't matter, except arbitrary ones
  # and order-sensitive ones (`*`, `before`, ...), which stay in place.
  defp sort_modifiers(modifiers) when length(modifiers) < 2, do: modifiers

  defp sort_modifiers(modifiers) do
    {sorted, segment} =
      Enum.reduce(modifiers, {[], []}, fn modifier, {sorted, segment} ->
        if String.starts_with?(modifier, "[") or modifier in @order_sensitive_modifiers,
          do: {sorted ++ Enum.sort(segment) ++ [modifier], []},
          else: {sorted, [modifier | segment]}
      end)

    sorted ++ Enum.sort(segment)
  end

  # -- class groups --------------------------------------------------------------

  defp group_id("[" <> rest = class) do
    if String.ends_with?(rest, "]"), do: arbitrary_property_group(rest), else: lookup(class)
  end

  defp group_id(class), do: lookup(class)

  # `[mask-type:luminance]` -> "arbitrary..mask-type"
  defp arbitrary_property_group(rest) do
    case :binary.split(binary_part(rest, 0, byte_size(rest) - 1), ":") do
      [property, _value] when property != "" -> "arbitrary.." <> property
      _ -> nil
    end
  end

  defp lookup(class) do
    parts =
      case String.split(class, "-") do
        # `-inset-1`: negative values use the same group
        ["" | rest] when rest != [] -> rest
        parts -> parts
      end

    find_group(parts, @class_map)
  end

  defp find_group([], {group, _next, _validators}), do: group

  defp find_group([part | rest] = parts, {_group, next, validators}) do
    found =
      case next do
        %{^part => child} -> find_group(rest, child)
        _ -> nil
      end

    found || validate(validators, parts)
  end

  defp validate([], _parts), do: nil

  defp validate(validators, parts) do
    value = Enum.join(parts, "-")
    Enum.find_value(validators, fn {validator, group} -> if valid?(validator, value), do: group end)
  end

  # -- validators (tailwind-merge's src/lib/validators.ts) -------------------------

  defp valid?(:any, _value), do: true
  defp valid?(:any_non_arbitrary, value), do: !arbitrary_value?(value) and !arbitrary_variable?(value)
  defp valid?(:fraction, value), do: Regex.match?(~r/^\d+(?:\.\d+)?\/\d+(?:\.\d+)?$/, value)
  defp valid?(:number, value), do: number?(value)
  defp valid?(:integer, value), do: integer?(value)
  defp valid?(:percent, value), do: percent?(value)
  defp valid?(:tshirt_size, value), do: Regex.match?(~r/^(\d+(\.\d+)?)?(xs|sm|md|lg|xl)$/, value)
  defp valid?(:named_container_query, value), do: named_container_query?(value)
  defp valid?(:arbitrary_value, value), do: arbitrary_value?(value)
  defp valid?(:arbitrary_variable, value), do: arbitrary_variable?(value)
  defp valid?(:arbitrary_size, value), do: arbitrary_value?(value, &(&1 in ~w(length size bg-size)), &never/1)
  defp valid?(:arbitrary_length, value), do: arbitrary_value?(value, &(&1 == "length"), &length_only?/1)
  defp valid?(:arbitrary_number, value), do: arbitrary_value?(value, &(&1 == "number"), &number?/1)
  defp valid?(:arbitrary_weight, value), do: arbitrary_value?(value, &(&1 in ~w(number weight)), &always/1)
  defp valid?(:arbitrary_family_name, value), do: arbitrary_value?(value, &(&1 == "family-name"), &never/1)
  defp valid?(:arbitrary_position, value), do: arbitrary_value?(value, &(&1 in ~w(position percentage)), &never/1)
  defp valid?(:arbitrary_image, value), do: arbitrary_value?(value, &(&1 in ~w(image url)), &image?/1)
  defp valid?(:arbitrary_shadow, value), do: arbitrary_value?(value, &(&1 == "shadow"), &shadow?/1)
  defp valid?(:arbitrary_variable_length, value), do: arbitrary_variable?(value, &(&1 == "length"), false)
  defp valid?(:arbitrary_variable_family_name, value), do: arbitrary_variable?(value, &(&1 == "family-name"), false)

  defp valid?(:arbitrary_variable_position, value),
    do: arbitrary_variable?(value, &(&1 in ~w(position percentage)), false)

  defp valid?(:arbitrary_variable_size, value), do: arbitrary_variable?(value, &(&1 in ~w(length size bg-size)), false)
  defp valid?(:arbitrary_variable_image, value), do: arbitrary_variable?(value, &(&1 in ~w(image url)), false)
  defp valid?(:arbitrary_variable_shadow, value), do: arbitrary_variable?(value, &(&1 == "shadow"), true)
  defp valid?(:arbitrary_variable_weight, value), do: arbitrary_variable?(value, &(&1 in ~w(number weight)), true)

  defp always(_value), do: true
  defp never(_value), do: false

  # `[label:value]`
  defp arbitrary_value?(value), do: Regex.match?(~r/^\[(?:(\w[\w-]*):)?(.+)\]$/, value)

  defp arbitrary_value?(value, label?, value?) do
    case Regex.run(~r/^\[(?:(\w[\w-]*):)?(.+)\]$/, value) do
      [_, "", inner] -> value?.(inner)
      [_, label, _inner] -> label?.(label)
      nil -> false
    end
  end

  # `(label:--var)`
  defp arbitrary_variable?(value), do: Regex.match?(~r/^\((?:(\w[\w-]*):)?(.+)\)$/, value)

  defp arbitrary_variable?(value, label?, match_no_label?) do
    case Regex.run(~r/^\((?:(\w[\w-]*):)?(.+)\)$/, value) do
      [_, "", _inner] -> match_no_label?
      [_, label, _inner] -> label?.(label)
      nil -> false
    end
  end

  defp named_container_query?("@container/" <> name), do: name != ""
  defp named_container_query?("@container-size/" <> name), do: name != ""
  defp named_container_query?("@container-normal/" <> name), do: name != ""
  defp named_container_query?(_value), do: false

  # Color functions can contain percentages, which aren't lengths.
  defp length_only?(value) do
    Regex.match?(
      ~r/\d+(%|px|r?em|[sdl]?v([hwib]|min|max)|pt|pc|in|cm|mm|cap|ch|ex|r?lh|cq(w|h|i|b|min|max))|\b(calc|min|max|clamp)\(.+\)|^0$/,
      value
    ) and
      not Regex.match?(~r/^(rgba?|hsla?|hwb|(ok)?(lab|lch)|color-mix|color|light-dark)\(.+\)$/, value)
  end

  defp shadow?(value), do: Regex.match?(~r/^(inset_)?-?((\d+)?\.?(\d+)[a-z]+|0)_-?((\d+)?\.?(\d+)[a-z]+|0)/, value)

  defp image?(value),
    do:
      Regex.match?(
        ~r/^(url|image|image-set|cross-fade|element|(repeating-)?(linear|radial|conic)-gradient)\(.+\)$/,
        value
      )

  defp percent?(value) do
    size = byte_size(value)
    size > 1 and String.ends_with?(value, "%") and number?(binary_part(value, 0, size - 1))
  end

  # JavaScript's `Number(value)`: decimals with an optional exponent, hex,
  # octal and binary literals, and Infinity.
  defp number?(value), do: js_number(value) != :nan

  defp integer?(value) do
    case js_number(value) do
      number when is_integer(number) -> true
      number when is_float(number) -> number == Float.round(number)
      _ -> false
    end
  end

  defp js_number(value) do
    cond do
      value in ["Infinity", "+Infinity", "-Infinity"] ->
        :infinity

      Regex.match?(~r/^[+-]?(\d+\.?\d*|\.\d+)(e[+-]?\d+)?$/i, value) ->
        parse_decimal(value)

      match = Regex.run(~r/^0([xob])([0-9a-f]+)$/i, value, capture: :all_but_first) ->
        [base, digits] = match
        base = %{"x" => 16, "o" => 8, "b" => 2}[String.downcase(base)]

        case Integer.parse(digits, base) do
          {number, ""} -> number
          _ -> :nan
        end

      true ->
        :nan
    end
  end

  defp parse_decimal(value) do
    normalised =
      value
      |> String.trim_leading("+")
      |> String.replace(~r/^(-?)\./, "\\g{1}0.")
      |> String.replace(~r/\.(?=e|E|$)/, ".0")

    case Float.parse(normalised) do
      {number, ""} -> number
      _ -> :infinity
    end
  rescue
    ArgumentError -> :infinity
  end
end
