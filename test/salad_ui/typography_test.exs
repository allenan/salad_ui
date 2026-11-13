defmodule SaladUI.TypographyTest do
  use ComponentCase

  import SaladUI.Typography

  test "headings" do
    assigns = %{}

    assert rendered_to_string(~H|<.typography_h1>T</.typography_h1>|) =~
             ~s(<h1 class="scroll-m-20 text-4xl font-extrabold tracking-tight text-balance")

    h2 = rendered_to_string(~H|<.typography_h2>T</.typography_h2>|)
    assert h2 =~ "<h2"
    assert h2 =~ "border-b pb-2 text-3xl font-semibold tracking-tight"
    assert h2 =~ "first:mt-0"

    assert rendered_to_string(~H|<.typography_h3>T</.typography_h3>|) =~
             ~s(<h3 class="scroll-m-20 text-2xl font-semibold tracking-tight")

    assert rendered_to_string(~H|<.typography_h4>T</.typography_h4>|) =~
             ~s(<h4 class="scroll-m-20 text-xl font-semibold tracking-tight")
  end

  test "text styles" do
    assigns = %{}

    assert rendered_to_string(~H|<.typography_p>T</.typography_p>|) =~
             ~s{<p class="leading-7 [&amp;:not(:first-child)]:mt-6"}

    assert rendered_to_string(~H|<.typography_blockquote>T</.typography_blockquote>|) =~
             ~s(<blockquote class="mt-6 border-s-2 ps-6 italic")

    assert rendered_to_string(~H|<.typography_inline_code>x</.typography_inline_code>|) =~
             ~s(<code class="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold">x</code>)

    assert rendered_to_string(~H|<.typography_lead>T</.typography_lead>|) =~
             ~s(<p class="text-xl text-muted-foreground")

    assert rendered_to_string(~H|<.typography_large>T</.typography_large>|) =~
             ~s(<div class="text-lg font-semibold")

    assert rendered_to_string(~H|<.typography_small>T</.typography_small>|) =~
             ~s(<small class="text-sm leading-none font-medium")

    assert rendered_to_string(~H|<.typography_muted>T</.typography_muted>|) =~
             ~s(<p class="text-sm text-muted-foreground")
  end

  test "lists" do
    assigns = %{}

    ul =
      rendered_to_string(~H"""
      <.typography_list>
        <li>a</li>
      </.typography_list>
      """)

    assert ul =~ ~s(<ul class="my-6 ms-6 list-disc [&amp;&gt;li]:mt-2")

    ol =
      rendered_to_string(~H"""
      <.typography_list ordered>
        <li>a</li>
      </.typography_list>
      """)

    assert ol =~ ~s(<ol class="my-6 ms-6 list-decimal)
  end

  test "table styles descendant cells" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.typography_table>
        <tbody>
          <tr>
            <td align="right">1</td>
          </tr>
        </tbody>
      </.typography_table>
      """)

    assert html =~ ~s(<div class="my-6 w-full overflow-y-auto">)
    assert html =~ "[&amp;_tr:nth-child(even)]:bg-muted"
    assert html =~ "[&amp;_td]:border"
    assert html =~ "[&amp;_td[align=right]]:text-right"
    assert html =~ "[&amp;_th]:font-bold"
  end

  test "custom classes merge" do
    assigns = %{}
    html = rendered_to_string(~H|<.typography_h1 class="text-center text-5xl">T</.typography_h1>|)
    assert html =~ "text-center"
    assert html =~ "text-5xl"
    refute html =~ "text-4xl"
  end
end
