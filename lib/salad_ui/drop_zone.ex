defmodule SaladUI.DropZone do
  @moduledoc """
  A drop target for files: while files are dragged over a region, an overlay
  covers it; dropping hands the files to a LiveView upload.

      <.drop_zone
        id="chat-drop"
        for="#chat"
        input="#attach-form input[type=file]"
        label="Drop files to attach"
      />

  `for` is the region (a selector; the overlay's parent by default) and
  `input` the `live_file_input` the files go to. Both are looked up when they
  are needed, so a re-rendered region, or an upload whose ref changed on
  connect, still works. The upload's own `accept`, size and entry limits and
  errors apply, as for its "Choose file" button. The overlay also dispatches a
  bubbling `drop-zone:files` DOM event (`detail.files`) for other uses.

  The overlay is fixed over the region (no positioned parent needed) and
  hidden from screen readers: dragging is a pointer shortcut for the upload's
  own button, which stays the accessible way in. It has `data-state="idle"`
  or `"active"`.

  For pasted files, `attachFiles(input, files)` from
  `salad_ui/components/drop_zone.js` hands files to an upload the same way:

      import { attachFiles } from "salad_ui/components/drop_zone";

  shadcn/ui has no drop zone; this one uses its tokens. The behaviour is the
  `drop-zone` component in `salad_ui/components/drop_zone.js`.
  """
  use SaladUI, :component

  attr :id, :string, required: true
  attr :for, :string, default: nil, doc: "selector of the region files are dragged over (default: the parent)"
  attr :input, :string, default: nil, doc: "selector of the live_file_input that receives the files"
  attr :label, :string, default: "Drop files to upload"
  attr :description, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  slot :icon, doc: "replaces the upload icon"

  def drop_zone(assigns) do
    assigns = assign(assigns, :options, json(%{for: assigns.for, input: assigns.input}))

    ~H"""
    <div
      id={@id}
      data-slot="drop-zone"
      data-component="drop-zone"
      data-part="root"
      data-state="idle"
      data-options={@options}
      phx-hook="SaladUI"
      aria-hidden="true"
      hidden
      class={
        classes([
          "pointer-events-none fixed z-40 box-border flex items-center justify-center p-3 data-[state=active]:animate-in data-[state=active]:fade-in-0",
          @class
        ])
      }
      {@rest}
    >
      <div class="flex size-full flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed border-primary bg-background/90 p-6 text-center shadow-lg backdrop-blur-sm">
        <span class="flex size-10 items-center justify-center rounded-full bg-primary/15 text-primary [&_svg]:size-5">
          {render_slot(@icon)}
          <svg
            :if={@icon == []}
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <path d="M12 3v12" /><path d="m17 8-5-5-5 5" /><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
          </svg>
        </span>
        <p class="m-0 text-sm font-semibold text-foreground">{@label}</p>
        <p :if={@description} class="m-0 max-w-xs text-xs text-muted-foreground">
          {@description}
        </p>
      </div>
    </div>
    """
  end
end
