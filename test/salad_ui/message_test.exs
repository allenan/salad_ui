defmodule SaladUI.MessageTest do
  use ComponentCase

  import SaladUI.Message

  test "message renders the shadcn slots and alignment" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.message_group>
        <.message align="end" class="custom">
          <.message_avatar>ME</.message_avatar>
          <.message_content>
            <.message_header>Olivia</.message_header>
            <p>Hi</p>
            <.message_footer>Delivered</.message_footer>
          </.message_content>
        </.message>
      </.message_group>
      """)

    assert html =~ ~s(data-slot="message-group")
    assert html =~ ~s(data-slot="message" data-align="end")
    assert html =~ "group/message"
    assert html =~ "data-[align=end]:flex-row-reverse"
    assert html =~ "custom"
    assert html =~ ~s(data-slot="message-avatar")
    assert html =~ "group-has-data-[slot=message-footer]/message:-translate-y-8"
    assert html =~ ~s(data-slot="message-content")
    assert html =~ "group-data-[align=end]/message:*:data-slot:self-end"
    assert html =~ ~s(data-slot="message-header")
    assert html =~ ~s(data-slot="message-footer")
    assert html =~ "group-data-[align=end]/message:justify-end"
  end

  test "message defaults to start alignment and allows an empty avatar" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.message>
        <.message_avatar />
        <.message_content>Hi</.message_content>
      </.message>
      """)

    assert html =~ ~s(data-align="start")
    assert html =~ ~s(data-slot="message-avatar")
  end
end
