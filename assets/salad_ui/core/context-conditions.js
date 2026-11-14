// saladui/core/context-conditions.js
//
// Items of a shared menu that depend on the row it is open for. A shared
// menu (see detached-triggers.js) is rendered once, so which items it shows
// cannot be decided on the server per row. Instead its parts carry
// conditions on the open menu's context map, as JSON, evaluated in the
// browser each time the menu opens (and when the context changes while open):
//
//     data-show-when='{"own":true}'        shown only when the context matches
//     data-hide-when='{"pinned":true}'     hidden when it matches
//     data-disabled-when='{"locked":true}' disabled when it matches (items)
//
// A condition is a map whose every key must match: the context's value for
// that key equals the condition's value, or one of them when the condition's
// value is a list. A list of maps matches when any of them does. A key the
// context lacks reads as null, so `{"own":null}` matches a context without
// `own`. Values compare as JSON (`true`, `42`, `"pinned"`).
//
// Hidden parts get the `hidden` attribute, so they are not rendered, not
// announced and skipped by keyboard navigation and typeahead (menu.js).
// Afterwards each panel is tidied: a group whose items are all hidden is
// hidden too, then a label that heads no visible item, then separators that
// would lead, trail or double up.
//
// This has no Radix equivalent; it is an additive, opt-in SaladUI extension.

export const SHOW_WHEN = "data-show-when";
export const HIDE_WHEN = "data-hide-when";
export const DISABLED_WHEN = "data-disabled-when";

// What this module changed, so the next pass can undo exactly that:
// `data-salad-hidden` ("when": a condition, "auto": tidying) on parts it hid,
// `data-salad-disabled` on items it disabled.
const HIDDEN_MARK = "data-salad-hidden";
const DISABLED_MARK = "data-salad-disabled";

const ITEM_SELECTOR = [
  "[data-part='item']",
  "[data-part='checkbox-item']",
  "[data-part='radio-item']",
  "[data-part='sub-trigger']",
].join(", ");
const PANEL_SELECTOR = "[data-part='content'], [data-part='sub-content']";
const GROUP_SELECTOR = "[data-part='group'], [data-part='radio-group']";
const FLOW_SELECTOR = `${ITEM_SELECTOR}, [data-part='separator'], [data-part='label']`;
const CONDITION_SELECTOR = `[${SHOW_WHEN}], [${HIDE_WHEN}]`;

function sameValue(a, b) {
  if (a === b) return true;
  if (a && b && typeof a === "object" && typeof b === "object") {
    return JSON.stringify(a) === JSON.stringify(b);
  }
  return false;
}

function matchesMap(condition, context) {
  if (!condition || typeof condition !== "object") return false;

  return Object.entries(condition).every(([key, expected]) => {
    const actual = context[key] ?? null;
    const accepted = Array.isArray(expected) ? expected : [expected];
    return accepted.some((value) => sameValue(value ?? null, actual));
  });
}

/**
 * Whether `context` (a map; null reads as {}) satisfies `condition`: a map
 * whose every key matches, or a list of maps of which any matches.
 */
export function matchesContext(condition, context) {
  const ctx = context && typeof context === "object" ? context : {};
  if (Array.isArray(condition)) {
    return condition.some((map) => matchesMap(map, ctx));
  }
  return matchesMap(condition, ctx);
}

/** A part's condition attribute, parsed; undefined when absent or invalid. */
export function readCondition(el, name) {
  const raw = el.getAttribute(name);
  if (raw === null || raw === "") return undefined;

  try {
    return JSON.parse(raw);
  } catch {
    console.error(`SaladUI: invalid ${name} JSON:`, raw);
    return undefined;
  }
}

/** Whether a part has a condition on the context. */
export function hasConditions(root) {
  return !!root?.querySelector(`${CONDITION_SELECTOR}, [${DISABLED_WHEN}]`);
}

function isDisabledAttr(el) {
  const value = el.getAttribute("data-disabled");
  return (
    el.hasAttribute("disabled") ||
    el.getAttribute("aria-disabled") === "true" ||
    (value !== null && value !== "false")
  );
}

/** Whether `el` or an ancestor below `boundary` is hidden. */
export function hiddenWithin(el, boundary) {
  for (let node = el; node && node !== boundary; node = node.parentElement) {
    if (node.hidden) return true;
  }
  return false;
}

function panelsOf(root) {
  const panels = [...root.querySelectorAll(PANEL_SELECTOR)];
  return root.matches?.(PANEL_SELECTOR) ? [root, ...panels] : panels;
}

/**
 * One evaluation of a menu's conditions. It decides which parts to hide
 * and disable without touching the DOM, then writes only the difference
 * from the previous pass (marked by HIDDEN_MARK / DISABLED_MARK): undoing
 * the previous pass first and hiding again would restyle every conditional
 * part on every open, even when the next row needs the same items.
 */
class Pass {
  constructor(root) {
    this.root = root;
    // What the previous pass hid (el -> reason) and disabled.
    this.hiddenBefore = new Map();
    root.querySelectorAll(`[${HIDDEN_MARK}]`).forEach((el) => {
      this.hiddenBefore.set(el, el.getAttribute(HIDDEN_MARK));
    });
    this.disabledBefore = new Set(root.querySelectorAll(`[${DISABLED_MARK}]`));
    // What this pass hides (el -> reason) and disabled.
    this.hidden = new Map();
    this.disabled = new Set();
  }

  // Hidden by something other than a previous pass (e.g. the server).
  hiddenElsewhere(el) {
    return el.hidden && !this.hiddenBefore.has(el);
  }

  isHidden(el) {
    return this.hidden.has(el) || this.hiddenElsewhere(el);
  }

  hiddenWithin(el, boundary) {
    for (let node = el; node && node !== boundary; node = node.parentElement) {
      if (this.isHidden(node)) return true;
    }
    return false;
  }

  hide(el, reason) {
    if (!this.isHidden(el)) this.hidden.set(el, reason);
  }

  disable(el) {
    const elsewhere = isDisabledAttr(el) && !this.disabledBefore.has(el);
    if (!elsewhere) this.disabled.add(el);
  }

  write() {
    this.hiddenBefore.forEach((_reason, el) => {
      if (this.hidden.has(el)) return;
      el.hidden = false;
      el.removeAttribute(HIDDEN_MARK);
    });
    this.hidden.forEach((reason, el) => {
      if (!el.hidden) el.hidden = true;
      if (el.getAttribute(HIDDEN_MARK) !== reason) {
        el.setAttribute(HIDDEN_MARK, reason);
      }
    });

    this.disabledBefore.forEach((el) => {
      if (this.disabled.has(el)) return;
      el.removeAttribute("data-disabled");
      el.removeAttribute("aria-disabled");
      el.removeAttribute(DISABLED_MARK);
    });
    this.disabled.forEach((el) => {
      if (el.getAttribute("data-disabled") !== "true") {
        el.setAttribute("data-disabled", "true");
      }
      if (el.getAttribute("aria-disabled") !== "true") {
        el.setAttribute("aria-disabled", "true");
      }
      if (!el.hasAttribute(DISABLED_MARK)) el.setAttribute(DISABLED_MARK, "");
    });
  }
}

// Hide what the conditions hid leaves dangling in one panel: groups with no
// visible item, labels heading no visible item, and separators that lead,
// trail or follow another separator.
function tidy(panel, pass) {
  const own = (el) => el.closest(PANEL_SELECTOR) === panel;
  const visible = (el) => !pass.hiddenWithin(el, panel);
  const hide = (el, reason) => pass.hide(el, reason);

  panel.querySelectorAll(GROUP_SELECTOR).forEach((group) => {
    if (!own(group) || !visible(group)) return;
    const items = [...group.querySelectorAll(ITEM_SELECTOR)].filter(own);
    if (items.length > 0 && !items.some(visible)) hide(group, "auto");
  });

  const isPart = (el, part) => el?.getAttribute("data-part") === part;
  let flow = [...panel.querySelectorAll(FLOW_SELECTOR)].filter(
    (el) => own(el) && visible(el),
  );

  flow = flow.filter((el, index) => {
    if (!isPart(el, "label")) return true;
    const next = flow[index + 1];
    if (next && !isPart(next, "separator") && !isPart(next, "label")) {
      return true;
    }
    hide(el, "auto");
    return false;
  });

  let previous = null;
  for (const el of flow) {
    if (
      isPart(el, "separator") &&
      (!previous || isPart(previous, "separator"))
    ) {
      hide(el, "auto");
      continue;
    }
    previous = el;
  }
  if (isPart(previous, "separator")) hide(previous, "auto");
}

/**
 * Evaluates the show/hide/disabled conditions of every part inside `root`
 * (a menu's positioner, sub-menus included) against `context`, then tidies
 * the panels whose parts a condition hid. What a previous pass hid or
 * disabled and this one does not is restored, and only parts whose state
 * changes are written; nothing else is touched, so parts the server rendered
 * hidden or disabled stay so. Returns whether `root` has any condition at
 * all.
 */
export function applyContextConditions(root, context) {
  if (!root?.querySelectorAll) return false;

  const pass = new Pass(root);
  const conditional = hasConditions(root);
  if (conditional) {
    const hidByCondition = [];
    root.querySelectorAll(CONDITION_SELECTOR).forEach((el) => {
      const show = readCondition(el, SHOW_WHEN);
      const hideWhen = readCondition(el, HIDE_WHEN);
      const shown =
        (show === undefined || matchesContext(show, context)) &&
        (hideWhen === undefined || !matchesContext(hideWhen, context));
      if (shown || pass.isHidden(el)) return;
      pass.hide(el, "when");
      hidByCondition.push(el);
    });

    root.querySelectorAll(`[${DISABLED_WHEN}]`).forEach((el) => {
      const condition = readCondition(el, DISABLED_WHEN);
      if (condition === undefined) return;
      if (matchesContext(condition, context)) pass.disable(el);
    });

    const panels = new Set(
      hidByCondition.map((el) => el.closest(PANEL_SELECTOR)),
    );
    for (const panel of panelsOf(root)) {
      if (panels.has(panel)) tidy(panel, pass);
    }
  }

  pass.write();
  return conditional;
}
