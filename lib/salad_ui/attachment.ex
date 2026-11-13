defmodule SaladUI.Attachment do
  @moduledoc """
  An attachment is a file card for chat composers and messages: a thumbnail or
  icon, a name and a meta line, with optional actions (remove, retry,
  download) and an optional full-card trigger.

  Parts: `attachment_group/1`, `attachment/1`, `attachment_media/1`,
  `attachment_content/1`, `attachment_title/1`, `attachment_description/1`,
  `attachment_actions/1`, `attachment_action/1`, `attachment_trigger/1`.

  `attachment_upload_entry/1` renders a whole attachment from a
  `Phoenix.LiveView.UploadEntry`, with progress, errors and a cancel button.

  ## States

  `state` is one of `"idle"` (selected, not uploaded yet; dashed border),
  `"uploading"` and `"processing"` (the title shimmers, image media is dimmed),
  `"error"` (destructive border, media and description) and `"done"`.

  ## Opening an attachment

  To make the whole card one link, give `attachment/1` an `href`, `navigate`
  or `patch` (or render it `as` another tag or function component); the card
  is then the link, so it holds no actions or trigger:

      <.attachment navigate={~p"/files/\#{@file.id}"}>
        <.attachment_media><.icon name="hero-document-text" /></.attachment_media>
        <.attachment_content>
          <.attachment_title>{@file.name}</.attachment_title>
        </.attachment_content>
      </.attachment>

  With actions, use `attachment_trigger/1` instead: a transparent button (or
  link) stretched over the card, so the whole card opens a preview while
  `attachment_actions/1` stay clickable above it. To open a `SaladUI.Dialog`, wrap the attachment in the
  dialog and use the dialog trigger with the same classes:

      <.dialog id="preview">
        <.attachment class="w-full">
          ...
          <.dialog_trigger as="button" class="absolute inset-0 z-10 outline-none" aria-label="Preview report.pdf">
            <span class="sr-only">Preview report.pdf</span>
          </.dialog_trigger>
        </.attachment>
        <.dialog_content>...</.dialog_content>
      </.dialog>

  ## Uploads

      <.attachment_group>
        <.attachment_upload_entry
          :for={entry <- @uploads.avatar.entries}
          entry={entry}
          upload={@uploads.avatar}
          on_cancel="cancel-upload"
        />
      </.attachment_group>

      def handle_event("cancel-upload", %{"ref" => ref}, socket) do
        {:noreply, cancel_upload(socket, :avatar, ref)}
      end

  ## Examples:

      <.attachment>
        <.attachment_media><.icon name="hero-document-text" /></.attachment_media>
        <.attachment_content>
          <.attachment_title>sales-dashboard.pdf</.attachment_title>
          <.attachment_description>PDF · 2.4 MB</.attachment_description>
        </.attachment_content>
        <.attachment_actions>
          <.attachment_action aria-label="Remove sales-dashboard.pdf">
            <.icon name="hero-x-mark" />
          </.attachment_action>
        </.attachment_actions>
      </.attachment>

      <.attachment orientation="vertical">
        <.attachment_media variant="image">
          <img src="/uploads/workspace.png" alt="Workspace" />
        </.attachment_media>
        <.attachment_content>
          <.attachment_title>workspace.png</.attachment_title>
          <.attachment_description>PNG · 820 KB</.attachment_description>
        </.attachment_content>
      </.attachment>
  """
  use SaladUI, :component

  alias Phoenix.LiveView.UploadConfig
  alias Phoenix.LiveView.UploadEntry

  @doc """
  A horizontally scrolling, snapping row of attachments.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def attachment_group(assigns) do
    ~H"""
    <div
      data-slot="attachment-group"
      class={
        classes([
          "flex min-w-0 scroll-fade-x snap-x snap-mandatory scroll-px-1 scrollbar-none gap-3 overflow-x-auto overscroll-x-contain py-1 *:data-[slot=attachment]:flex-none *:data-[slot=attachment]:snap-start",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @sizes %{
    "default" =>
      "gap-2 text-sm has-data-[slot=attachment-content]:px-2.5 has-data-[slot=attachment-content]:py-2 has-data-[slot=attachment-media]:p-2",
    "sm" =>
      "gap-2.5 text-xs has-data-[slot=attachment-content]:px-2 has-data-[slot=attachment-content]:py-1.5 has-data-[slot=attachment-media]:p-1.5",
    "xs" =>
      "gap-1.5 rounded-lg text-xs has-data-[slot=attachment-content]:px-1.5 has-data-[slot=attachment-content]:py-1 has-data-[slot=attachment-media]:p-1"
  }

  @orientations %{
    "horizontal" => "min-w-40 items-center",
    "vertical" => "w-24 flex-col has-data-[slot=attachment-content]:w-30"
  }

  @doc """
  Renders an attachment card.

  ## Options

  * `:state` - `"idle"`, `"uploading"`, `"processing"`, `"error"` or
    `"done"` (default).
  * `:size` - `"default"`, `"sm"` or `"xs"`.
  * `:orientation` - `"horizontal"` (default; media beside the text) or
    `"vertical"` (a square tile with the text below).
  * `:href`, `:navigate`, `:patch` - Render the card as a link
    (`Phoenix.Component.link/1`), so the whole card is one link.
  * `:as` - The tag or function component to render instead of the `div`
    (shadcn's `asChild`).
  * `:class` - Additional CSS classes.
  """
  attr :state, :string,
    values: ~w(idle uploading processing error done),
    default: "done",
    doc: "the upload state"

  attr :size, :string, values: ~w(default sm xs), default: "default", doc: "the attachment size"

  attr :orientation, :string,
    values: ~w(horizontal vertical),
    default: "horizontal",
    doc: "the layout direction"

  attr :as, :any, default: "div", doc: "the tag or function component to render"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch replace method download target rel)
  slot :inner_block, required: true

  def attachment(assigns) do
    link? = Enum.any?([:href, :navigate, :patch], &assigns.rest[&1])

    assigns =
      assign(assigns,
        as: if(link? and assigns.as == "div", do: &Phoenix.Component.link/1, else: assigns.as),
        root_class:
          classes([
            "group/attachment relative flex w-fit max-w-full min-w-0 shrink-0 flex-wrap rounded-xl border bg-card text-card-foreground transition-colors focus-within:ring-1 focus-within:ring-ring/50 has-[>a,>button]:hover:bg-muted/50 data-[state=error]:border-destructive/30 data-[state=idle]:border-dashed",
            # the card itself is the link (`href`/`navigate`/`patch`)
            link? && "outline-none hover:bg-muted/50",
            @sizes[assigns.size],
            @orientations[assigns.orientation],
            assigns.class
          ])
      )

    ~H"""
    <div
      :if={@as == "div"}
      data-slot="attachment"
      data-state={@state}
      data-size={@size}
      data-orientation={@orientation}
      class={@root_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    <.dynamic
      :if={@as != "div"}
      tag={@as}
      data-slot="attachment"
      data-state={@state}
      data-size={@size}
      data-orientation={@orientation}
      class={@root_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  The square thumbnail: an icon (default) or an `<img>` (`variant="image"`).

  ## Options

  * `:variant` - `"icon"` (default) or `"image"`. Image media is dimmed while
    the attachment is uploading or processing.
  * `:class` - Additional CSS classes.
  """
  attr :variant, :string, values: ~w(icon image), default: "icon", doc: "what the media holds"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def attachment_media(assigns) do
    assigns =
      assign(
        assigns,
        :variant_class,
        if(assigns.variant == "image",
          do:
            "opacity-60 group-data-[state=done]/attachment:opacity-100 group-data-[state=idle]/attachment:opacity-100 *:[img]:aspect-square *:[img]:w-full *:[img]:object-cover",
          else: ""
        )
      )

    ~H"""
    <div
      data-slot="attachment-media"
      data-variant={@variant}
      class={
        classes([
          "relative flex aspect-square w-10 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-muted text-foreground group-data-[orientation=vertical]/attachment:w-full group-data-[size=sm]/attachment:w-8 group-data-[size=xs]/attachment:w-7 group-data-[size=xs]/attachment:rounded-md group-data-[state=error]/attachment:bg-destructive/10 group-data-[state=error]/attachment:text-destructive group-data-[orientation=vertical]/attachment:*:data-[slot=spinner]:size-6! [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 group-data-[orientation=vertical]/attachment:[&_svg:not([class*='size-'])]:size-6 group-data-[size=xs]/attachment:[&_svg:not([class*='size-'])]:size-3.5",
          @variant_class,
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Holds the title and description.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def attachment_content(assigns) do
    ~H"""
    <div
      data-slot="attachment-content"
      class={
        classes([
          "max-w-full min-w-0 flex-1 leading-tight group-data-[orientation=vertical]/attachment:px-1",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The file name. Truncates, and shimmers while uploading or processing.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def attachment_title(assigns) do
    ~H"""
    <span
      data-slot="attachment-title"
      class={
        classes([
          "block max-w-full min-w-0 truncate font-medium group-data-[state=processing]/attachment:shimmer group-data-[state=uploading]/attachment:shimmer",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  The meta line: type and size, upload progress, or an error.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def attachment_description(assigns) do
    ~H"""
    <span
      data-slot="attachment-description"
      class={
        classes([
          "mt-0.5 block min-w-0 truncate text-xs text-muted-foreground group-data-[state=error]/attachment:text-destructive/80",
          "max-w-full",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Holds `attachment_action/1` buttons. Sits above `attachment_trigger/1`, and
  in the top-right corner of a vertical attachment.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def attachment_actions(assigns) do
    ~H"""
    <div
      data-slot="attachment-actions"
      class={
        classes([
          "relative z-20 flex shrink-0 items-center group-data-[orientation=vertical]/attachment:absolute group-data-[orientation=vertical]/attachment:top-3 group-data-[orientation=vertical]/attachment:end-3 group-data-[orientation=vertical]/attachment:gap-1",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A small icon button (remove, retry, download). Styled as a `SaladUI.Button`;
  give it an `aria-label`.

  ## Options

  * `:variant` - Any button variant. Defaults to `"ghost"`.
  * `:size` - Any button size. Defaults to `"icon-xs"`.
  * `:type` - Defaults to `"button"`.
  * `:class` - Additional CSS classes.
  """
  attr :variant, :string,
    values: ~w(default secondary destructive outline ghost link),
    default: "ghost",
    doc: "the button variant"

  attr :size, :string,
    values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg),
    default: "icon-xs",
    doc: "the button size"

  attr :type, :string, default: "button"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def attachment_action(assigns) do
    ~H"""
    <button
      type={@type}
      data-slot="attachment-action"
      data-variant={@variant}
      data-size={@size}
      class={classes([button_variant(%{variant: @variant, size: @size}), @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  A transparent button (or link) stretched over the whole card, so clicking
  anywhere opens the attachment. Give it an `aria-label`.

  ## Options

  * `:as` - `"button"` (default, `type="button"`) or `"a"` (pass `href`).
  * `:class` - Additional CSS classes.
  """
  attr :as, :string, values: ~w(button a), default: "button", doc: "the element to render"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href target rel type disabled download)
  slot :inner_block

  def attachment_trigger(assigns) do
    assigns =
      if assigns.as == "button" and is_nil(assigns.rest[:type]),
        do: assign(assigns, :rest, Map.put(assigns.rest, :type, "button")),
        else: assigns

    ~H"""
    <.dynamic_tag
      tag_name={@as}
      data-slot="attachment-trigger"
      class={classes(["absolute inset-0 z-10 outline-none", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  @doc """
  Renders an attachment for a `Phoenix.LiveView.UploadEntry`.

  The state follows the entry: `"error"` when the entry has upload errors or
  is invalid, `"done"` once uploaded, `"uploading"` while progress is between
  0 and 100, and `"idle"` before the upload starts (e.g. with
  `auto_upload: false`). Pass `state` to override it, for example
  `"processing"` while you consume the file.

  Image entries show a `live_img_preview/1` thumbnail. While uploading, the
  description reads `"Uploading · 64%"` and a thin progress bar
  (`role="progressbar"`) runs along the bottom edge. Errors show the first
  message from `upload_errors/2`.

  ## Options

  * `:entry` - Required. The `Phoenix.LiveView.UploadEntry`.
  * `:upload` - The `Phoenix.LiveView.UploadConfig` (`@uploads.name`), used to
    look up the entry's errors.
  * `:errors` - Errors to show instead of the ones on `:upload` (atoms or
    strings).
  * `:error_to_string` - A 1-arity function turning an error atom into a
    message. Defaults to English messages for LiveView's built-in errors.
  * `:on_cancel` - The event pushed with `phx-value-ref={entry.ref}` when the
    cancel/remove button is clicked. Defaults to `"cancel-upload"`; `nil`
    hides the button.
  * `:target` - `phx-target` for the cancel event (for LiveComponents).
  * `:state` - Overrides the derived state.
  * `:preview` - Show an image preview for image entries. Defaults to `true`.
  * `:size`, `:orientation`, `:class` - As on `attachment/1`.

  ## Slots

  * `:media` - Replaces the default media (preview, spinner or file icon).
  * `:actions` - Extra `attachment_action/1` buttons, rendered before cancel.

  ## Examples:

      <.attachment_upload_entry
        :for={entry <- @uploads.documents.entries}
        entry={entry}
        upload={@uploads.documents}
      />
  """
  attr :entry, UploadEntry, required: true, doc: "the upload entry to render"
  attr :upload, UploadConfig, default: nil, doc: "the upload config, for errors"
  attr :errors, :list, default: nil, doc: "errors to show instead of the upload's"
  attr :error_to_string, :any, default: nil, doc: "1-arity function formatting an error"
  attr :on_cancel, :string, default: "cancel-upload", doc: "event pushed to cancel or remove the entry"
  attr :target, :any, default: nil, doc: "phx-target for the cancel event"

  attr :state, :string,
    values: [nil | ~w(idle uploading processing error done)],
    default: nil,
    doc: "overrides the derived state"

  attr :preview, :boolean, default: true, doc: "show an image preview for image entries"
  attr :size, :string, values: ~w(default sm xs), default: "default"
  attr :orientation, :string, values: ~w(horizontal vertical), default: "horizontal"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :media
  slot :actions

  def attachment_upload_entry(assigns) do
    %UploadEntry{} = entry = assigns.entry
    errors = upload_entry_errors(assigns)
    state = assigns.state || upload_entry_state(entry, errors)
    format = assigns.error_to_string || (&upload_error_to_string/1)

    assigns =
      assign(assigns,
        state: state,
        error_message: errors |> List.first() |> format_error(format),
        image?: assigns.preview and image_entry?(entry),
        meta: entry_meta(entry),
        cancel_label:
          if(state in ~w(uploading processing),
            do: "Cancel upload of #{entry.client_name}",
            else: "Remove #{entry.client_name}"
          )
      )

    ~H"""
    <.attachment
      state={@state}
      size={@size}
      orientation={@orientation}
      class={@class}
      {@rest}
    >
      <%= if @media != [] do %>
        {render_slot(@media)}
      <% else %>
        <.attachment_media :if={@image? and @state != "error"} variant="image">
          <.live_img_preview entry={@entry} alt={@entry.client_name} />
        </.attachment_media>
        <.attachment_media :if={not @image? or @state == "error"}>
          <.upload_icon state={@state} />
        </.attachment_media>
      <% end %>
      <.attachment_content>
        <.attachment_title>{@entry.client_name}</.attachment_title>
        <.attachment_description>
          <%= cond do %>
            <% @state == "error" -> %>
              {@error_message}
            <% @state == "uploading" -> %>
              Uploading · {@entry.progress}%
            <% @state == "processing" -> %>
              Processing
            <% @state == "idle" -> %>
              Ready to upload
            <% true -> %>
              {@meta}
          <% end %>
        </.attachment_description>
      </.attachment_content>
      <.attachment_actions :if={@actions != [] or @on_cancel}>
        {render_slot(@actions)}
        <.attachment_action
          :if={@on_cancel}
          phx-click={@on_cancel}
          phx-value-ref={@entry.ref}
          phx-target={@target}
          aria-label={@cancel_label}
          title={@cancel_label}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <path d="M18 6 6 18" /><path d="m6 6 12 12" />
          </svg>
        </.attachment_action>
      </.attachment_actions>
      <div
        :if={@state == "uploading"}
        data-slot="attachment-progress"
        role="progressbar"
        aria-label={"Uploading #{@entry.client_name}"}
        aria-valuemin="0"
        aria-valuemax="100"
        aria-valuenow={@entry.progress}
        class="pointer-events-none absolute inset-x-3 bottom-0 h-0.5 overflow-hidden rounded-full bg-muted"
      >
        <div class="h-full bg-primary transition-[width]" style={"width: #{@entry.progress}%"}></div>
      </div>
    </.attachment>
    """
  end

  attr :state, :string, required: true

  defp upload_icon(%{state: "uploading"} = assigns) do
    ~H"""
    <svg
      data-slot="spinner"
      role="status"
      aria-label="Loading"
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-4 animate-spin"
    >
      <path d="M21 12a9 9 0 1 1-6.219-8.56" />
    </svg>
    """
  end

  defp upload_icon(%{state: "error"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <circle cx="12" cy="12" r="10" /><line x1="12" x2="12" y1="8" y2="12" /><line
        x1="12"
        x2="12.01"
        y1="16"
        y2="16"
      />
    </svg>
    """
  end

  defp upload_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" /><path d="M14 2v4a2 2 0 0 0 2 2h4" />
    </svg>
    """
  end

  defp upload_entry_errors(%{errors: errors}) when is_list(errors), do: errors
  defp upload_entry_errors(%{upload: %UploadConfig{} = upload, entry: entry}), do: upload_errors(upload, entry)
  defp upload_entry_errors(_), do: []

  defp upload_entry_state(%UploadEntry{} = entry, errors) do
    cond do
      errors != [] or (entry.preflighted? and not entry.valid?) -> "error"
      entry.done? -> "done"
      entry.progress > 0 -> "uploading"
      true -> "idle"
    end
  end

  defp format_error(nil, _format), do: "Upload failed"
  defp format_error(error, _format) when is_binary(error), do: error
  defp format_error(error, format), do: format.(error)

  @doc false
  def upload_error_to_string(:too_large), do: "File is too large"
  def upload_error_to_string(:not_accepted), do: "File type not accepted"
  def upload_error_to_string(:too_many_files), do: "Too many files"
  def upload_error_to_string(:external_client_failure), do: "Upload failed. Try again."

  def upload_error_to_string(error) when is_atom(error),
    do: error |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  def upload_error_to_string(error), do: to_string(error)

  defp image_entry?(%UploadEntry{client_type: "image/" <> _}), do: true
  defp image_entry?(_), do: false

  defp entry_meta(%UploadEntry{client_name: name, client_size: size, client_type: type}) do
    kind =
      case name && Path.extname(name) do
        "." <> ext when ext != "" -> String.upcase(ext)
        _ -> type
      end

    [kind, size && format_bytes(size)]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" · ")
  end

  @doc false
  def format_bytes(bytes) when bytes < 1000, do: "#{bytes} B"
  def format_bytes(bytes) when bytes < 1_000_000, do: "#{round(bytes / 1000)} KB"
  def format_bytes(bytes) when bytes < 1_000_000_000, do: "#{Float.round(bytes / 1_000_000, 1)} MB"
  def format_bytes(bytes), do: "#{Float.round(bytes / 1_000_000_000, 1)} GB"
end
