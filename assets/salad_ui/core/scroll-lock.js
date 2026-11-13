// saladui/core/scroll-lock.js
/**
 * Body scroll lock shared by every modal surface (dialog, sheet, alert
 * dialog, drawer, the sidebar's mobile sheet), like Radix's RemoveScroll
 * and vaul.
 *
 * Locks are reference-counted: the first lockScroll() hides the page's
 * overflow on <html> and <body> and pads <body> by the scrollbar's width so
 * the layout does not jump; the styles come back only when the last lock is
 * released. Nested modals therefore stack: closing the inner one leaves the
 * page locked until the outer one closes too.
 *
 *   const release = lockScroll();
 *   ...
 *   release(); // idempotent
 *
 * Inline styles the page already had on <html>/<body> (including
 * `!important` ones) are saved and put back exactly. While locked, <body>
 * carries `data-scroll-locked` (the lock count), as react-remove-scroll
 * does, for CSS that needs to compensate fixed elements.
 */

let count = 0;
let saved = null;
// Bumped by resetScrollLock() so releases of locks it dropped do nothing.
let generation = 0;

const LOCK_ATTRIBUTE = "data-scroll-locked";

function readInline(el, property) {
  return {
    value: el.style.getPropertyValue(property),
    priority: el.style.getPropertyPriority(property),
  };
}

function writeInline(el, property, { value, priority }) {
  if (value) {
    el.style.setProperty(property, value, priority);
  } else {
    el.style.removeProperty(property);
  }
}

/**
 * Width (px) of the page's vertical scrollbar, or 0 when there is none or
 * the page already reserves its space with `scrollbar-gutter: stable`.
 */
export function scrollbarWidth() {
  const html = document.documentElement;
  const view = document.defaultView || window;
  // An unlaid-out document (no clientWidth) has no scrollbar to measure.
  if (!html.clientWidth || !view?.innerWidth) return 0;

  const gutter = view.getComputedStyle?.(html)?.scrollbarGutter || "";
  if (gutter.includes("stable")) return 0;

  return Math.max(0, view.innerWidth - html.clientWidth);
}

function apply() {
  const html = document.documentElement;
  const body = document.body;
  if (!html || !body) return;

  const gap = scrollbarWidth();
  const view = document.defaultView || window;
  const basePadding =
    parseFloat(view.getComputedStyle?.(body)?.paddingRight) || 0;

  saved = {
    html,
    body,
    htmlOverflow: readInline(html, "overflow"),
    bodyOverflow: readInline(body, "overflow"),
    bodyPaddingRight: readInline(body, "padding-right"),
  };

  html.style.setProperty("overflow", "hidden", "important");
  body.style.setProperty("overflow", "hidden", "important");
  if (gap > 0) {
    body.style.setProperty(
      "padding-right",
      `${basePadding + gap}px`,
      "important",
    );
  }
}

function restore() {
  if (!saved) return;
  const { html, body } = saved;

  writeInline(html, "overflow", saved.htmlOverflow);
  writeInline(body, "overflow", saved.bodyOverflow);
  writeInline(body, "padding-right", saved.bodyPaddingRight);
  if (html.getAttribute("style") === "") html.removeAttribute("style");
  if (body.getAttribute("style") === "") body.removeAttribute("style");
  body.removeAttribute(LOCK_ATTRIBUTE);

  saved = null;
}

/**
 * Lock page scrolling. Returns a function that releases this lock; calling
 * it more than once is a no-op.
 */
export function lockScroll() {
  if (typeof document === "undefined") return () => {};

  if (count === 0) apply();
  count += 1;
  saved?.body.setAttribute(LOCK_ATTRIBUTE, String(count));

  const lockGeneration = generation;
  let released = false;
  return () => {
    if (released || lockGeneration !== generation) return;
    released = true;

    count = Math.max(0, count - 1);
    if (count === 0) {
      restore();
    } else {
      saved?.body.setAttribute(LOCK_ATTRIBUTE, String(count));
    }
  };
}

/** Whether any lock is held. */
export function isScrollLocked() {
  return count > 0;
}

/** Number of locks currently held. */
export function scrollLockCount() {
  return count;
}

/**
 * Drop every lock and restore the page's styles. For test teardown and for
 * apps that swap the whole document; components release their own locks.
 */
export function resetScrollLock() {
  generation += 1;
  count = 0;
  restore();
}
