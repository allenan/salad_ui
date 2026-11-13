defmodule SaladUI.AttachmentTest do
  use ComponentCase

  import SaladUI.Attachment

  alias Phoenix.LiveView.UploadEntry

  test "attachment renders every part with defaults" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.attachment_group>
        <.attachment>
          <.attachment_media><svg></svg></.attachment_media>
          <.attachment_content>
            <.attachment_title>report.pdf</.attachment_title>
            <.attachment_description>PDF · 2.4 MB</.attachment_description>
          </.attachment_content>
          <.attachment_actions>
            <.attachment_action aria-label="Remove report.pdf">x</.attachment_action>
          </.attachment_actions>
          <.attachment_trigger aria-label="Open report.pdf" />
        </.attachment>
      </.attachment_group>
      """)

    assert html =~ ~s(data-slot="attachment-group")
    assert html =~ "scroll-fade-x"
    assert html =~ "scrollbar-none"

    assert html =~
             ~s(data-slot="attachment" data-state="done" data-size="default" data-orientation="horizontal")

    assert html =~ "group/attachment"
    assert html =~ "min-w-40 items-center"
    assert html =~ ~s(data-slot="attachment-media" data-variant="icon")
    assert html =~ ~s(data-slot="attachment-content")
    assert html =~ ~s(data-slot="attachment-title")
    assert html =~ "group-data-[state=uploading]/attachment:shimmer"
    assert html =~ ~s(data-slot="attachment-description")
    assert html =~ ~s(data-slot="attachment-actions")
    assert html =~ ~r/<button type="button" data-slot="attachment-action" data-variant="ghost" data-size="icon-xs"/
    assert html =~ "size-6 rounded-md"

    assert html =~
             ~r/<button[^>]*data-slot="attachment-trigger"[^>]*type="button"|<button[^>]*type="button"[^>]*data-slot="attachment-trigger"/

    assert html =~ "absolute inset-0 z-10 outline-none"
  end

  test "the card shows shadcn's focus ring when its trigger has keyboard focus" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.attachment>
        <.attachment_trigger aria-label="Open report.pdf" />
      </.attachment>
      """)

    for class <- ~w(has-focus-visible:border-ring has-focus-visible:ring-[3px] has-focus-visible:ring-ring/50) do
      assert html =~ class
    end

    refute html =~ "focus-within:ring-1"
  end

  test "attachment state, size, orientation and image media" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.attachment state="error" size="xs" orientation="vertical">
        <.attachment_media variant="image"><img src="/a.png" alt="a" /></.attachment_media>
      </.attachment>
      """)

    assert html =~ ~s(data-state="error" data-size="xs" data-orientation="vertical")
    assert html =~ "data-[state=error]:border-destructive/30"
    assert html =~ "w-24 flex-col"
    assert html =~ "gap-1.5 rounded-lg text-xs"
    assert html =~ ~s(data-variant="image")
    assert html =~ "group-data-[state=done]/attachment:opacity-100"
  end

  test "attachment_trigger renders a link" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.attachment_trigger as="a" href="/a.png" target="_blank" aria-label="Open" />
      """)

    assert html =~ ~r/^<a[^>]*href="\/a.png"/
    refute html =~ "type="
  end

  describe "attachment_upload_entry" do
    defp entry(attrs) do
      struct(
        %UploadEntry{
          ref: "0",
          upload_ref: "phx-ref",
          client_name: "report.pdf",
          client_size: 2_400_000,
          client_type: "application/pdf"
        },
        attrs
      )
    end

    test "idle before the upload starts" do
      assigns = %{entry: entry(%{})}

      html =
        rendered_to_string(~H"""
        <.attachment_upload_entry entry={@entry} />
        """)

      assert html =~ ~s(data-state="idle")
      assert html =~ "report.pdf"
      assert html =~ "Ready to upload"
      assert html =~ ~s(phx-click="cancel-upload")
      assert html =~ ~s(phx-value-ref="0")
      assert html =~ ~s(aria-label="Remove report.pdf")
      refute html =~ "progressbar"
    end

    test "uploading shows progress and a cancel button" do
      assigns = %{entry: entry(%{progress: 64, preflighted?: true, valid?: true})}

      html =
        rendered_to_string(~H"""
        <.attachment_upload_entry entry={@entry} on_cancel="cancel" target="#uploader" />
        """)

      assert html =~ ~s(data-state="uploading")
      assert html =~ "Uploading · 64%"
      assert html =~ ~s(role="progressbar")
      assert html =~ ~s(aria-valuenow="64")
      assert html =~ "width: 64%"
      assert html =~ ~s(data-slot="spinner")
      assert html =~ ~s(phx-click="cancel")
      assert html =~ ~s(phx-target="#uploader")
      assert html =~ ~s(aria-label="Cancel upload of report.pdf")
    end

    test "done shows the file type and size" do
      assigns = %{entry: entry(%{progress: 100, done?: true, preflighted?: true, valid?: true})}

      html =
        rendered_to_string(~H"""
        <.attachment_upload_entry entry={@entry} on_cancel={nil} />
        """)

      assert html =~ ~s(data-state="done")
      assert html =~ "PDF · 2.4 MB"
      refute html =~ "phx-click"
      refute html =~ "attachment-actions"
    end

    test "errors come from the upload config or the errors attr" do
      entry = entry(%{preflighted?: true, valid?: false})
      upload = %Phoenix.LiveView.UploadConfig{errors: [{"0", :too_large}], entries: [entry]}
      assigns = %{entry: entry, upload: upload}

      html =
        rendered_to_string(~H"""
        <.attachment_upload_entry entry={@entry} upload={@upload} />
        """)

      assert html =~ ~s(data-state="error")
      assert html =~ "File is too large"

      html =
        rendered_to_string(~H"""
        <.attachment_upload_entry
          entry={@entry}
          errors={[:not_accepted]}
          error_to_string={fn :not_accepted -> "Only images" end}
        />
        """)

      assert html =~ "Only images"
    end

    test "image entries render a live preview" do
      assigns = %{entry: entry(%{client_name: "cat.png", client_type: "image/png"})}

      html =
        rendered_to_string(~H"""
        <.attachment_upload_entry entry={@entry} orientation="vertical" />
        """)

      assert html =~ ~s(data-variant="image")
      assert html =~ ~s(data-phx-hook="Phoenix.LiveImgPreview")
      assert html =~ ~s(alt="cat.png")
    end

    test "state override and custom slots" do
      assigns = %{entry: entry(%{progress: 100, done?: true})}

      html =
        rendered_to_string(~H"""
        <.attachment_upload_entry entry={@entry} state="processing">
          <:media><span id="custom-media"></span></:media>
          <:actions>
            <.attachment_action aria-label="Retry">r</.attachment_action>
          </:actions>
        </.attachment_upload_entry>
        """)

      assert html =~ ~s(data-state="processing")
      assert html =~ "Processing"
      assert html =~ ~s(id="custom-media")
      assert html =~ ~s(aria-label="Retry")
    end
  end

  test "format_bytes" do
    assert format_bytes(512) == "512 B"
    assert format_bytes(820_000) == "820 KB"
    assert format_bytes(2_400_000) == "2.4 MB"
    assert format_bytes(3_100_000_000) == "3.1 GB"
  end
end
