defmodule Storybook.SaladUIComponents.Attachment do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Attachment
  alias SaladUI.Dialog

  def function, do: &Attachment.attachment/1
  def layout, do: :one_column

  def imports,
    do: [
      {Attachment,
       [
         attachment_group: 1,
         attachment_media: 1,
         attachment_content: 1,
         attachment_title: 1,
         attachment_description: 1,
         attachment_actions: 1,
         attachment_action: 1,
         attachment_trigger: 1,
         attachment_upload_entry: 1
       ]},
      {Dialog, [dialog: 1, dialog_trigger: 1, dialog_content: 1, dialog_header: 1, dialog_title: 1, dialog_description: 1]},
      {SaladUI.Spinner, [spinner: 1]},
      {SaladStorybookWeb.CoreComponents, [icon: 1]}
    ]

  @workspace "https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=900&auto=format&fit=crop&q=80"
  @desk "https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=900&auto=format&fit=crop&q=80"
  @office "https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=900&auto=format&fit=crop&q=80"

  def variations do
    [
      %Variation{
        id: :demo,
        template: """
        <div class="mx-auto flex w-full max-w-sm flex-col gap-3 py-12">
          <.attachment_group>
            <.attachment orientation="vertical">
              <.attachment_media variant="image"><img src="#{@workspace}" alt="Workspace" /></.attachment_media>
              <.attachment_content>
                <.attachment_title>workspace.png</.attachment_title>
                <.attachment_description>PNG · 820 KB</.attachment_description>
              </.attachment_content>
            </.attachment>
            <.attachment orientation="vertical">
              <.attachment_media variant="image"><img src="#{@desk}" alt="Desk" /></.attachment_media>
              <.attachment_content>
                <.attachment_title>desk-reference.jpg</.attachment_title>
                <.attachment_description>JPG · 1.1 MB</.attachment_description>
              </.attachment_content>
            </.attachment>
            <.attachment orientation="vertical">
              <.attachment_media variant="image"><img src="#{@office}" alt="Office" /></.attachment_media>
              <.attachment_content>
                <.attachment_title>office-reference.jpg</.attachment_title>
                <.attachment_description>JPG · 940 KB</.attachment_description>
              </.attachment_content>
            </.attachment>
          </.attachment_group>
          <.attachment state="uploading" class="w-full">
            <.attachment_media><.spinner /></.attachment_media>
            <.attachment_content>
              <.attachment_title>sales-dashboard.pdf</.attachment_title>
              <.attachment_description>Uploading · 64%</.attachment_description>
            </.attachment_content>
            <.attachment_actions>
              <.attachment_action aria-label="Cancel upload"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
            </.attachment_actions>
          </.attachment>
          <.attachment class="w-full">
            <.attachment_media><.icon name="hero-code-bracket" class="size-4" /></.attachment_media>
            <.attachment_content>
              <.attachment_title>message-renderer.tsx</.attachment_title>
              <.attachment_description>TypeScript · 12 KB</.attachment_description>
            </.attachment_content>
            <.attachment_actions>
              <.attachment_action aria-label="Remove message-renderer.tsx"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
            </.attachment_actions>
          </.attachment>
        </div>
        """
      },
      %Variation{
        id: :image,
        description: "An `attachment_trigger` link stretched over the card opens the image; actions stay clickable above it.",
        template: """
        <div class="mx-auto w-full max-w-sm py-12">
          <.attachment_group class="w-full">
            <.attachment :for={{name, meta, src} <- [{"workspace.png", "PNG · 820 KB", "#{@workspace}"}, {"desk-reference.jpg", "JPG · 1.1 MB", "#{@desk}"}, {"office-reference.jpg", "JPG · 940 KB", "#{@office}"}]} orientation="vertical">
              <.attachment_media variant="image"><img src={src} alt={name} /></.attachment_media>
              <.attachment_content>
                <.attachment_title>{name}</.attachment_title>
                <.attachment_description>{meta}</.attachment_description>
              </.attachment_content>
              <.attachment_actions>
                <.attachment_action aria-label={"Remove " <> name}><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
              </.attachment_actions>
              <.attachment_trigger as="a" href={src} target="_blank" rel="noreferrer" aria-label={"Open " <> name} />
            </.attachment>
          </.attachment_group>
        </div>
        """
      },
      %Variation{
        id: :states,
        template: """
        <div class="mx-auto flex w-full max-w-sm flex-col gap-2 py-12">
          <.attachment state="idle" class="w-full">
            <.attachment_media><.icon name="hero-clock" class="size-4" /></.attachment_media>
            <.attachment_content>
              <.attachment_title>selected-file.pdf</.attachment_title>
              <.attachment_description>Ready to upload</.attachment_description>
            </.attachment_content>
            <.attachment_actions>
              <.attachment_action aria-label="Remove selected-file.pdf"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
            </.attachment_actions>
          </.attachment>
          <.attachment state="uploading" class="w-full">
            <.attachment_media><.spinner /></.attachment_media>
            <.attachment_content>
              <.attachment_title>design-system.zip</.attachment_title>
              <.attachment_description>Uploading · 64%</.attachment_description>
            </.attachment_content>
            <.attachment_actions>
              <.attachment_action aria-label="Cancel upload"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
            </.attachment_actions>
          </.attachment>
          <.attachment state="processing" class="w-full">
            <.attachment_media><.icon name="hero-document-text" class="size-4" /></.attachment_media>
            <.attachment_content>
              <.attachment_title>market-research.pdf</.attachment_title>
              <.attachment_description>Processing document</.attachment_description>
            </.attachment_content>
            <.attachment_actions>
              <.attachment_action aria-label="Remove market-research.pdf"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
            </.attachment_actions>
          </.attachment>
          <.attachment state="error" class="w-full">
            <.attachment_media><.icon name="hero-exclamation-triangle" class="size-4" /></.attachment_media>
            <.attachment_content>
              <.attachment_title>financial-model.xlsx</.attachment_title>
              <.attachment_description>Upload failed. Try again.</.attachment_description>
            </.attachment_content>
            <.attachment_actions>
              <.attachment_action aria-label="Retry upload"><.icon name="hero-arrow-path" class="size-3" /></.attachment_action>
              <.attachment_action aria-label="Remove financial-model.xlsx"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
            </.attachment_actions>
          </.attachment>
          <.attachment state="done" class="w-full">
            <.attachment_media><.icon name="hero-check" class="size-4" /></.attachment_media>
            <.attachment_content>
              <.attachment_title>uploaded-report.pdf</.attachment_title>
              <.attachment_description>Uploaded · 1.8 MB</.attachment_description>
            </.attachment_content>
            <.attachment_actions>
              <.attachment_action aria-label="Remove uploaded-report.pdf"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
            </.attachment_actions>
          </.attachment>
        </div>
        """
      },
      %Variation{
        id: :sizes,
        template: """
        <div class="mx-auto flex w-full max-w-sm flex-col gap-3 py-12">
          <.attachment size="default" class="w-full">
            <.attachment_media><.icon name="hero-document-text" class="size-4" /></.attachment_media>
            <.attachment_content>
              <.attachment_title>Default attachment</.attachment_title>
              <.attachment_description>PDF · 2.4 MB</.attachment_description>
            </.attachment_content>
          </.attachment>
          <.attachment size="sm" class="w-full">
            <.attachment_media><.icon name="hero-document-text" class="size-4" /></.attachment_media>
            <.attachment_content>
              <.attachment_title>Small attachment</.attachment_title>
              <.attachment_description>PDF · 2.4 MB</.attachment_description>
            </.attachment_content>
          </.attachment>
          <.attachment size="xs" class="w-full">
            <.attachment_media><.icon name="hero-document-text" class="size-3.5" /></.attachment_media>
            <.attachment_content>
              <.attachment_title>Extra small attachment</.attachment_title>
            </.attachment_content>
          </.attachment>
        </div>
        """
      },
      %Variation{
        id: :group,
        template: """
        <div class="mx-auto w-full max-w-sm py-12">
          <.attachment_group class="w-full">
            <.attachment class="w-64">
              <.attachment_media><.icon name="hero-document-text" class="size-4" /></.attachment_media>
              <.attachment_content>
                <.attachment_title>briefing-notes.pdf</.attachment_title>
                <.attachment_description>PDF · 1.4 MB</.attachment_description>
              </.attachment_content>
              <.attachment_actions>
                <.attachment_action aria-label="Remove briefing-notes.pdf"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
              </.attachment_actions>
            </.attachment>
            <.attachment class="w-64">
              <.attachment_media variant="image"><img src="#{@workspace}" alt="workspace.png" /></.attachment_media>
              <.attachment_content>
                <.attachment_title>workspace.png</.attachment_title>
                <.attachment_description>PNG · 820 KB</.attachment_description>
              </.attachment_content>
              <.attachment_actions>
                <.attachment_action aria-label="Remove workspace.png"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
              </.attachment_actions>
            </.attachment>
            <.attachment class="w-64">
              <.attachment_media><.icon name="hero-table-cells" class="size-4" /></.attachment_media>
              <.attachment_content>
                <.attachment_title>customers.csv</.attachment_title>
                <.attachment_description>CSV · 18 KB</.attachment_description>
              </.attachment_content>
              <.attachment_actions>
                <.attachment_action aria-label="Remove customers.csv"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
              </.attachment_actions>
            </.attachment>
            <.attachment class="w-64">
              <.attachment_media><.icon name="hero-code-bracket" class="size-4" /></.attachment_media>
              <.attachment_content>
                <.attachment_title>renderer.tsx</.attachment_title>
                <.attachment_description>TSX · 12 KB</.attachment_description>
              </.attachment_content>
              <.attachment_actions>
                <.attachment_action aria-label="Remove renderer.tsx"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
              </.attachment_actions>
            </.attachment>
          </.attachment_group>
        </div>
        """
      },
      %Variation{
        id: :trigger,
        description: "A dialog trigger with the `attachment_trigger` classes fills the card and opens a preview.",
        template: """
        <div class="mx-auto w-full max-w-sm py-12">
          <.dialog id="attachment-dialog">
            <.attachment class="w-full">
              <.attachment_media><.icon name="hero-document-magnifying-glass" class="size-4" /></.attachment_media>
              <.attachment_content>
                <.attachment_title>research-summary.pdf</.attachment_title>
                <.attachment_description>Open preview dialog</.attachment_description>
              </.attachment_content>
              <.attachment_actions>
                <.attachment_action aria-label="Copy link"><.icon name="hero-clipboard-document" class="size-3" /></.attachment_action>
                <.attachment_action aria-label="Remove research-summary.pdf"><.icon name="hero-x-mark" class="size-3" /></.attachment_action>
              </.attachment_actions>
              <.dialog_trigger as="button" class="absolute inset-0 z-10 outline-none" aria-label="Preview research-summary.pdf">
                <span class="sr-only">Preview research-summary.pdf</span>
              </.dialog_trigger>
            </.attachment>
            <.dialog_content class="sm:max-w-md">
              <.dialog_header>
                <.dialog_title>research-summary.pdf</.dialog_title>
                <.dialog_description>
                  The attachment trigger fills the card and opens the dialog, while the actions stay independently clickable above it.
                </.dialog_description>
              </.dialog_header>
            </.dialog_content>
          </.dialog>
        </div>
        """
      },
      %Variation{
        id: :upload_entry,
        description:
          "`attachment_upload_entry` renders a `Phoenix.LiveView.UploadEntry`: idle, uploading (with progress), done and error (from `upload_errors/2`), with a cancel button pushing `cancel-upload`.",
        template: """
        <div class="mx-auto flex w-full max-w-sm flex-col gap-2 py-12">
          <.attachment_upload_entry
            class="w-full"
            entry={%Phoenix.LiveView.UploadEntry{ref: "0", upload_ref: "phx-docs", client_name: "selected-file.pdf", client_size: 1_800_000, client_type: "application/pdf"}}
          />
          <.attachment_upload_entry
            class="w-full"
            entry={%Phoenix.LiveView.UploadEntry{ref: "1", upload_ref: "phx-docs", client_name: "design-system.zip", client_size: 4_200_000, client_type: "application/zip", progress: 64, preflighted?: true, valid?: true}}
          />
          <.attachment_upload_entry
            class="w-full"
            entry={%Phoenix.LiveView.UploadEntry{ref: "2", upload_ref: "phx-docs", client_name: "uploaded-report.pdf", client_size: 1_800_000, client_type: "application/pdf", progress: 100, done?: true, preflighted?: true, valid?: true}}
          />
          <.attachment_upload_entry
            class="w-full"
            entry={%Phoenix.LiveView.UploadEntry{ref: "3", upload_ref: "phx-docs", client_name: "financial-model.xlsx", client_size: 24_000_000, client_type: "application/vnd.ms-excel"}}
            errors={[:too_large]}
          />
        </div>
        """
      }
    ]
  end
end
