// saladui/core/direction.js
/**
 * Reading direction helpers (the counterpart of Radix's DirectionProvider /
 * useDirection). A component's direction comes from the nearest ancestor
 * with a `dir` attribute (`<html dir="rtl">`, `direction_provider/1`, or a
 * `dir` set on the component itself), falling back to the computed CSS
 * `direction` and then to `"ltr"`.
 */

/**
 * @param {Element|null|undefined} el
 * @returns {"ltr"|"rtl"}
 */
export function getDirection(el) {
  if (!el || typeof el.closest !== "function") return "ltr";

  const attr = el.closest("[dir]")?.getAttribute("dir")?.trim().toLowerCase();
  if (attr === "rtl" || attr === "ltr") return attr;

  // `dir="auto"` (or no attribute at all): ask the browser.
  try {
    const view = el.ownerDocument?.defaultView;
    if (view?.getComputedStyle?.(el)?.direction === "rtl") return "rtl";
  } catch {
    // Detached nodes / non-browser environments: assume LTR.
  }
  return "ltr";
}

/**
 * @param {Element|null|undefined} el
 * @returns {boolean}
 */
export function isRtl(el) {
  return getDirection(el) === "rtl";
}

/**
 * The logical `"start"`/`"end"` alignment of a top/bottom placed element,
 * resolved to the physical edge it lines up with.
 *
 * @param {"start"|"center"|"end"} alignment
 * @param {"ltr"|"rtl"} dir
 */
export function mirrorAlignment(alignment, dir) {
  if (dir !== "rtl") return alignment;
  if (alignment === "start") return "end";
  if (alignment === "end") return "start";
  return alignment;
}
