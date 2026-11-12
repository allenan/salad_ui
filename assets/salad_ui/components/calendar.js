// saladui/components/calendar.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

// The month grid is rendered by the server (SaladUI.Calendar.LiveComponent).
// This component only adds what needs the client: roving focus and keyboard
// navigation over the day buttons, the caption dropdowns, and telling the form
// / LiveView when the user changed the selection.

const DAY_MS = 24 * 60 * 60 * 1000;

const KEY_MOVES = {
  ArrowLeft: ["day", -1],
  ArrowRight: ["day", 1],
  ArrowUp: ["week", -1],
  ArrowDown: ["week", 1],
  PageUp: ["month", -1],
  PageDown: ["month", 1],
  Home: ["startOfWeek", -1],
  End: ["endOfWeek", 1],
};

// Dates are handled as UTC midnights so DST never shifts a day.
export function parseISODate(iso) {
  if (!iso) return null;
  const [y, m, d] = iso.split("-").map(Number);
  if (!y || !m || !d) return null;
  return new Date(Date.UTC(y, m - 1, d));
}

export function toISODate(date) {
  return date.toISOString().slice(0, 10);
}

function addDays(date, days) {
  return new Date(date.getTime() + days * DAY_MS);
}

function addMonths(date, months) {
  const y = date.getUTCFullYear();
  const m = date.getUTCMonth() + months;
  const lastDay = new Date(Date.UTC(y, m + 1, 0)).getUTCDate();
  return new Date(Date.UTC(y, m, Math.min(date.getUTCDate(), lastDay)));
}

/**
 * The date a key press moves focus to, following react-day-picker.
 */
export function moveDate(date, move, dir, weekStartsOn = 0) {
  switch (move) {
    case "day":
      return addDays(date, dir);
    case "week":
      return addDays(date, 7 * dir);
    case "month":
      return addMonths(date, dir);
    case "year":
      return addMonths(date, 12 * dir);
    case "startOfWeek":
      return addDays(date, -((date.getUTCDay() - weekStartsOn + 7) % 7));
    case "endOfWeek":
      return addDays(date, 6 - ((date.getUTCDay() - weekStartsOn + 7) % 7));
    default:
      return date;
  }
}

class CalendarComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    this.weekStartsOn = Number(this.options.weekStartsOn) || 0;
    this.min = parseISODate(this.options.min);
    this.max = parseISODate(this.options.max);

    this.onKeyDown = this.onKeyDown.bind(this);
    this.onSelectChange = this.onSelectChange.bind(this);
    this.onSelectInput = this.onSelectInput.bind(this);
    this.onFocusIn = this.onFocusIn.bind(this);
    this.onFocusOut = this.onFocusOut.bind(this);
  }

  getComponentConfig() {
    return {
      stateMachine: {
        idle: {
          transitions: {},
        },
      },
      events: {},
      // The grid semantics (role="grid", aria-selected, aria-label on each
      // day) are rendered by the server so they survive LiveView patches.
      ariaConfig: {
        grid: {
          all: {
            role: "grid",
          },
        },
      },
    };
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    this.el.addEventListener("keydown", this.onKeyDown);
    this.el.addEventListener("change", this.onSelectChange);
    this.el.addEventListener("input", this.onSelectInput);
    this.el.addEventListener("focusin", this.onFocusIn);
    this.el.addEventListener("focusout", this.onFocusOut);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.el.removeEventListener("keydown", this.onKeyDown);
    this.el.removeEventListener("change", this.onSelectChange);
    this.el.removeEventListener("input", this.onSelectInput);
    this.el.removeEventListener("focusin", this.onFocusIn);
    this.el.removeEventListener("focusout", this.onFocusOut);
  }

  /**
   * State that has to outlive this instance: the hook rebuilds the component
   * after every LiveView patch, and the server's answer to a pick arrives as
   * such a patch.
   */
  get shared() {
    if (!this.hook) return (this._shared ||= {});
    return (this.hook.__saladCalendar ||= {});
  }

  afterMount() {
    const shared = this.shared;
    const value = this.el.getAttribute("data-value") || "";
    // The server bumps data-selection-seq for every pick by the user (a day
    // click, Enter/Space on a day, a preset), never for a `value` the parent
    // passes in. So only the user's own changes reach the form and on-select.
    const seq = this.el.getAttribute("data-selection-seq") || "";

    if (
      shared.lastSeq !== undefined &&
      seq !== shared.lastSeq &&
      value !== shared.lastValue
    ) {
      this.selectionChanged(value);
    }
    shared.lastSeq = seq;
    shared.lastValue = value;

    this.restoreFocusedDay();
  }

  /**
   * A patch resets the server-rendered tabindex and drops data-focused; keep
   * both on the day that still has focus.
   */
  restoreFocusedDay() {
    const active = document.activeElement;
    if (!active?.matches?.("button[data-day]") || !this.el.contains(active)) {
      return;
    }
    this.dayButtons().forEach((b) =>
      b.setAttribute("tabindex", b === active ? "0" : "-1"),
    );
    active.parentElement?.setAttribute("data-focused", "true");
  }

  // -- day buttons -----------------------------------------------------------

  dayButtons() {
    return Array.from(this.el.querySelectorAll("button[data-day]"));
  }

  /** The button for `date` in one of the visible months (not an outside day). */
  dayButton(date) {
    const iso = toISODate(date);
    return this.dayButtons().find(
      (button) =>
        button.dataset.day === iso &&
        !button.parentElement?.hasAttribute("data-outside"),
    );
  }

  tabbableDay() {
    return (
      this.dayButtons().find((b) => b.getAttribute("tabindex") === "0") || null
    );
  }

  focusDay(button) {
    if (!button) return;
    this.dayButtons().forEach((b) => b.setAttribute("tabindex", "-1"));
    button.setAttribute("tabindex", "0");
    button.focus();
  }

  isRtl() {
    const dir = this.el.closest("[dir]")?.getAttribute("dir");
    return dir === "rtl";
  }

  outOfBounds(date, dir) {
    if (dir < 0 && this.min && date < this.min) return true;
    if (dir > 0 && this.max && date > this.max) return true;
    return false;
  }

  onKeyDown(event) {
    const button = event.target.closest?.("button[data-day]");
    if (!button || !this.el.contains(button)) return;

    let [move, dir] = KEY_MOVES[event.key] || [];
    if (!move) return;
    event.preventDefault();

    if (event.shiftKey && move === "month") move = "year";
    if (move === "day" && this.isRtl()) dir = -dir;

    this.moveFocus(parseISODate(button.dataset.day), move, dir);
  }

  moveFocus(from, move, dir) {
    let target = moveDate(from, move, dir, this.weekStartsOn);

    // Skip disabled days, like react-day-picker: keep moving the same way
    // (by day for Home/End, which would otherwise stay put).
    for (let i = 0; i < 366; i++) {
      if (this.outOfBounds(target, dir)) return;

      const button = this.dayButton(target);
      if (!button) {
        this.requestFocus(target, dir);
        return;
      }
      if (!button.disabled) {
        this.focusDay(button);
        return;
      }

      target =
        move === "startOfWeek" || move === "endOfWeek"
          ? addDays(target, dir)
          : moveDate(target, move, dir, this.weekStartsOn);
    }
  }

  /**
   * Ask the server to show the month holding `date`, then focus its answer.
   * The reply arrives after the server's patch has been applied, by which
   * time the hook has rebuilt the component, so go through the hook.
   */
  requestFocus(date, dir) {
    const hook = this.hook;
    this.pushToComponent("focus", { date: toISODate(date), dir }, () => {
      const component = hook.component;
      if (!component || component.destroyed) return;

      // Leave focus alone if the user has moved on in the meantime.
      const active = document.activeElement;
      if (active && active !== document.body && !component.el.contains(active))
        return;
      component.focusDay(component.tabbableDay());
    });
  }

  pushToComponent(event, payload, onReply) {
    if (!this.hook?.pushEventTo) return;
    if (onReply) this.hook.pushEventTo(this.el, event, payload, onReply);
    else this.hook.pushEventTo(this.el, event, payload);
  }

  onFocusIn(event) {
    const button = event.target.closest?.("button[data-day]");
    if (!button) return;
    button.parentElement?.setAttribute("data-focused", "true");
    // Keep the roving tabindex on the day the user last focused.
    this.dayButtons().forEach((b) =>
      b.setAttribute("tabindex", b === button ? "0" : "-1"),
    );
  }

  onFocusOut(event) {
    const button = event.target.closest?.("button[data-day]");
    button?.parentElement?.removeAttribute("data-focused");
  }

  // -- caption dropdowns -----------------------------------------------------

  isCaptionSelect(target) {
    const part = target?.getAttribute?.("data-part");
    return part === "month-select" || part === "year-select";
  }

  // The dropdowns are not form fields: keep their events away from a
  // surrounding form's phx-change.
  onSelectInput(event) {
    if (this.isCaptionSelect(event.target)) event.stopPropagation();
  }

  onSelectChange(event) {
    const select = event.target;
    if (!this.isCaptionSelect(select)) return;
    event.stopPropagation();

    const isMonth = select.getAttribute("data-part") === "month-select";
    const year = isMonth ? select.dataset.year : select.value;
    const month = isMonth ? select.value : select.dataset.month;
    const iso = `${year}-${String(month).padStart(2, "0")}-01`;

    this.pushToComponent("goto", {
      month: iso,
      index: Number(select.dataset.index) || 0,
    });
  }

  // -- selection -------------------------------------------------------------

  parseValue(raw) {
    try {
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }

  selectionChanged(raw) {
    const value = this.parseValue(raw);

    // Let a surrounding form's phx-change see the new hidden input values.
    const inputs = this.options.inputs
      ? document.getElementById(this.options.inputs)
      : null;
    const input = inputs?.querySelector("input");
    input?.dispatchEvent(new Event("input", { bubbles: true }));

    this.notify("select", { id: this.el.id, value });

    if (this.options.closeOnSelect && this.isComplete(value)) {
      this.closePopover();
    }
  }

  isComplete(value) {
    if (!value) return false;
    if (this.options.mode === "range") {
      return !!(value.from && value.to && value.from !== value.to);
    }
    return this.options.mode === "single";
  }

  closePopover() {
    const popover = this.el.closest('[data-component="popover"]');
    if (!popover) return;
    popover.dispatchEvent(
      new CustomEvent("salad_ui:command", {
        detail: { command: "close", target: popover.id },
      }),
    );
  }

  /**
   * Pushes a mapped event to the calendar's *parent*. A plain pushEvent from
   * this element would go to the calendar's own LiveComponent, so target the
   * element that contains the component root instead.
   */
  notify(clientEvent, payload) {
    const handler = this.eventMappings[clientEvent];
    if (!handler || !this.hook) return;

    const componentRoot = this.el.closest("[data-phx-component]");
    const owner = componentRoot?.parentElement || this.el;

    if (typeof handler === "string") {
      this.hook.pushEventTo?.(owner, handler, payload);
    } else {
      this.hook.liveSocket?.execJS(owner, JSON.stringify(handler));
    }
  }
}

SaladUI.register("calendar", CalendarComponent);

export default CalendarComponent;
