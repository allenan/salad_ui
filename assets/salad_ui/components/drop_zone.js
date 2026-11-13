// saladui/components/drop_zone.js
//
// A drop target for files, for Phoenix LiveView uploads. The markup comes from
// `SaladUI.DropZone.drop_zone/1`.
//
// While files are dragged over the element the `for` option names (a
// selector; the overlay's parent by default), the overlay covers it
// (data-state="active"). Dropping sends the files to the live_file_input the
// `input` option names (read at drop time, so an input re-rendered with a new
// upload ref still works) and dispatches a bubbling `drop-zone:files` event
// with `{files}` on the overlay. The upload's own limits and errors apply, as
// for its "Choose file" button.
//
// `attachFiles(input, files)` does the same for pasted files.
import Component from "../core/component.js";
import SaladUI from "../index.js";

/**
 * Hands `files` to a LiveView `live_file_input`, the way a JS hook's
 * `this.upload/2` does (LiveView's "track-uploads" event). Returns whether
 * anything was handed over.
 */
export function attachFiles(input, files) {
  // Files and Blobs (duck-typed: a File from another realm, e.g. an iframe,
  // is not an instance of this window's Blob).
  const list = Array.from(files || []).filter(
    (file) =>
      typeof file?.size === "number" && typeof file.slice === "function",
  );
  if (!input || list.length === 0) return false;
  input.dispatchEvent(
    new CustomEvent("track-uploads", {
      bubbles: true,
      detail: { files: list },
    }),
  );
  return true;
}

const hasFiles = (event) =>
  Array.from(event.dataTransfer?.types || []).includes("Files");

class DropZoneComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext, initialState: "idle" });
    this.depth = 0;

    this.onEnter = this.onEnter.bind(this);
    this.onOver = this.onOver.bind(this);
    this.onLeave = this.onLeave.bind(this);
    this.onDrop = this.onDrop.bind(this);
    this.onEnd = this.onEnd.bind(this);

    this.keepStateAcrossPatches();
  }

  // The overlay's visibility, position and state live on the client.
  keepStateAcrossPatches() {
    const js = this.hook?.js?.();
    if (typeof js?.ignoreAttributes !== "function") return;
    js.ignoreAttributes(this.el, ["hidden", "style", "data-state"]);
  }

  getComponentConfig() {
    return {
      stateMachine: {
        idle: { transitions: { activate: "active" } },
        active: { transitions: { deactivate: "idle" } },
      },
      hiddenConfig: {
        idle: { root: true },
        active: { root: false },
      },
    };
  }

  skipReinitialize(el) {
    if (!this.sameConfig(el)) return false;
    this.reapplyState();
    return true;
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    document.addEventListener("dragenter", this.onEnter);
    document.addEventListener("dragover", this.onOver);
    document.addEventListener("dragleave", this.onLeave);
    document.addEventListener("drop", this.onDrop);
    window.addEventListener("dragend", this.onEnd);
    window.addEventListener("blur", this.onEnd);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    document.removeEventListener("dragenter", this.onEnter);
    document.removeEventListener("dragover", this.onOver);
    document.removeEventListener("dragleave", this.onLeave);
    document.removeEventListener("drop", this.onDrop);
    window.removeEventListener("dragend", this.onEnd);
    window.removeEventListener("blur", this.onEnd);
  }

  // The region the event is in, or null.
  regionFor(event) {
    const selector = this.options.for;
    const region = selector
      ? document.querySelector(selector)
      : this.el.parentElement;
    return region &&
      event.target instanceof Node &&
      region.contains(event.target)
      ? region
      : null;
  }

  onEnter(event) {
    if (!hasFiles(event)) return;
    const region = this.regionFor(event);
    if (!region) return;
    this.depth += 1;
    this.show(region);
  }

  onOver(event) {
    if (!hasFiles(event) || !this.regionFor(event)) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = "copy";
  }

  onLeave(event) {
    if (!hasFiles(event) || !this.regionFor(event)) return;
    this.depth = Math.max(0, this.depth - 1);
    if (this.depth === 0) this.hide();
  }

  onDrop(event) {
    const region = this.regionFor(event);
    this.depth = 0;
    this.hide();
    if (!region || !hasFiles(event)) return;
    event.preventDefault();
    const files = Array.from(event.dataTransfer.files || []);
    if (files.length === 0) return;
    const input =
      this.options.input && document.querySelector(this.options.input);
    attachFiles(input, files);
    this.el.dispatchEvent(
      new CustomEvent("drop-zone:files", { bubbles: true, detail: { files } }),
    );
  }

  // A drag that ends anywhere else (Escape, or dropped outside the window).
  onEnd() {
    this.depth = 0;
    this.hide();
  }

  // Fixed over the region, so the overlay needs no positioned parent.
  show(region) {
    const rect = region.getBoundingClientRect();
    Object.assign(this.el.style, {
      left: `${rect.left}px`,
      top: `${rect.top}px`,
      width: `${rect.width}px`,
      height: `${rect.height}px`,
    });
    if (this.state !== "active") this.transition("activate");
  }

  hide() {
    if (this.state === "active") this.transition("deactivate");
  }
}

SaladUI.register("drop-zone", DropZoneComponent);

export default DropZoneComponent;
