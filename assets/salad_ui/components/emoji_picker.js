// saladui/components/emoji_picker.js
//
// An emoji picker on SaladUI's popover. One picker per page serves any number
// of openers; the markup comes from `SaladUI.EmojiPicker.emoji_picker/1`.
//
// A plain button opens it:
//
//     <button type="button" data-emoji-picker="PICKER_ID" ...>
//
// optionally with `data-emoji-event="react"` and `data-emoji-value-*`: picking
// then pushes that event with the values and `emoji` (like phx-value-*). The
// picker's `on-select` mapping runs too, and the opener receives a bubbling
// `emoji-picker:select` event with `{emoji, name}` once the picker has closed.
//
// Commands (`SaladUI.JS.dispatch_command/3`, `SaladUI.LiveView.send_command/4`):
// `open` with `{anchor, event, values, return_focus}` (selectors for anchor
// and return_focus), `close` and `toggle`.
//
// The dataset (`emoji_picker/data.json`, from Unicode's emoji-test.txt; see
// generate_data.exs and DATA_LICENSE.txt there) is loaded with a dynamic
// import() the first time a picker opens: with code splitting (esbuild
// `--splitting --format=esm`) it is its own chunk. Recently used emoji and the
// skin tone are kept in localStorage.
import Component from "../core/component.js";
import SaladUI from "../index.js";

const TONES = [
  "",
  "\u{1F3FB}",
  "\u{1F3FC}",
  "\u{1F3FD}",
  "\u{1F3FE}",
  "\u{1F3FF}",
];
const RECENT_MAX = 24;
const MODIFIERS = /[\u{1F3FB}-\u{1F3FF}]/gu;
const VS16 = "\u{FE0F}";
const HAND = "\u{270B}";
const CLOCK = "\u{1F552}";
// A click on the opener that just closed the picker (a touch closes it on
// touchend, before the click) toggles it shut instead of reopening it.
const REOPEN_GUARD_MS = 400;

const DEFAULT_LABELS = {
  emoji: "Emoji",
  search: "Search emoji",
  categories: "Emoji categories",
  recent: "Recently used",
  results: "Search results",
  empty: "No emoji found.",
  tone: "Skin tone",
  tones: [
    "No skin tone",
    "Light",
    "Medium-light",
    "Medium",
    "Medium-dark",
    "Dark",
  ],
  groups: {},
};

/**
 * The emoji with skin tone `tone` (0 none, 1-5 light to dark): the modifier
 * goes after the first code point, in place of a U+FE0F there. The dataset
 * marks only emoji for which this gives Unicode's sequence.
 */
export function withTone(emoji, tone) {
  if (!tone || !TONES[tone]) return emoji;
  const [first, ...rest] = [...emoji];
  const tail = rest[0] === VS16 ? rest.slice(1) : rest;
  return first + TONES[tone] + tail.join("");
}

function read(key, fallback) {
  try {
    const value = window.localStorage.getItem(key);
    return value === null ? fallback : JSON.parse(value);
  } catch {
    return fallback;
  }
}

function write(key, value) {
  try {
    window.localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // Storage blocked or full: recents are a convenience.
  }
}

// data-emoji-value-message-id="1" -> {message_id: "1"}
export function valuesFrom(dataset) {
  const values = {};
  for (const [key, value] of Object.entries(dataset)) {
    if (!key.startsWith("emojiValue") || key === "emojiValue") continue;
    const name = key
      .slice("emojiValue".length)
      .replace(/^./, (c) => c.toLowerCase())
      .replace(/[A-Z]/g, (c) => "_" + c.toLowerCase());
    values[name] = value;
  }
  return values;
}

function command(el, name) {
  el?.dispatchEvent(
    new CustomEvent("salad_ui:command", {
      detail: { command: name, params: {} },
      bubbles: false,
    }),
  );
}

let dataPromise = null;

class EmojiPickerComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    const labels = this.options.labels || {};
    this.labels = { ...DEFAULT_LABELS, ...labels };
    const key = this.options.storageKey || "salad-ui:emoji-picker";
    this.recentKey = `${key}:recent`;
    this.toneKey = `${key}:tone`;
    const tone = Number(read(this.toneKey, 0));
    this.tone = tone >= 0 && tone < TONES.length ? tone : 0;
    this.query = "";
    this.items = [];
    this.active = -1;
    this.lastClose = null;

    this.resolveParts();

    this.onDocumentClick = this.onDocumentClick.bind(this);
    this.onClosed = this.onClosed.bind(this);
  }

  /**
   * The picker's own elements are inside the popover's content, which moves
   * to the portal while open, so they are found by their server-rendered ids
   * and data-slot names rather than as parts of this component.
   */
  resolveParts() {
    const id = this.el.id;
    const find = (suffix) =>
      document.getElementById(`${id}-${suffix}`) ||
      this.el.querySelector(`[id="${id}-${suffix}"]`);
    this.popover = find("popover");
    this.anchor = find("anchor");
    this.panel = find("panel");
    this.search = find("search");
    this.grid = find("grid");
    const slot = (name) =>
      this.panel?.querySelector(`[data-slot="emoji-picker-${name}"]`) || null;
    this.nav = slot("nav");
    this.preview = slot("preview");
    this.toneRow = slot("tones");
    this.toneButton = slot("tone-button");
  }

  getComponentConfig() {
    return {
      stateMachine: {
        idle: { transitions: {} },
      },
    };
  }

  /** Nothing the picker reads changed: keep its state (recents, tone, data). */
  skipReinitialize(el) {
    return this.sameConfig(el) && !!this.panel?.isConnected;
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    document.addEventListener("click", this.onDocumentClick);
    this.el.addEventListener("emoji-picker:closed", this.onClosed);

    this.onSearchInput = () => {
      this.query = this.search.value;
      this.render();
    };
    this.onSearchKeyDown = (event) => this.onKeyDown(event);
    this.onGridClick = (event) => {
      const option = event.target.closest?.("[data-index]");
      if (option) this.choose(Number(option.dataset.index));
    };
    this.onGridPointerMove = (event) => {
      const option = event.target.closest?.("[data-index]");
      if (option && Number(option.dataset.index) !== this.active) {
        this.setActive(Number(option.dataset.index), { scroll: false });
      }
    };
    this.onGridScroll = () => this.syncNav();
    this.onNavClick = (event) => {
      const button = event.target.closest?.("[data-section-key]");
      if (button) this.jumpTo(button.dataset.sectionKey);
    };
    this.onToneButtonClick = () => this.showTones(this.toneRow.hidden);
    this.onToneRowClick = (event) => {
      const button = event.target.closest?.("[data-tone]");
      if (!button) return;
      this.tone = Number(button.dataset.tone);
      write(this.toneKey, this.tone);
      this.showTones(false);
      this.drawToneButton();
      this.render();
      this.search?.focus();
    };

    this.search?.addEventListener("input", this.onSearchInput);
    this.search?.addEventListener("keydown", this.onSearchKeyDown);
    this.grid?.addEventListener("click", this.onGridClick);
    this.grid?.addEventListener("pointermove", this.onGridPointerMove);
    this.grid?.addEventListener("scroll", this.onGridScroll, { passive: true });
    this.nav?.addEventListener("click", this.onNavClick);
    this.toneButton?.addEventListener("click", this.onToneButtonClick);
    this.toneRow?.addEventListener("click", this.onToneRowClick);
    this.drawToneButton();
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    document.removeEventListener("click", this.onDocumentClick);
    this.el?.removeEventListener("emoji-picker:closed", this.onClosed);
    this.search?.removeEventListener("input", this.onSearchInput);
    this.search?.removeEventListener("keydown", this.onSearchKeyDown);
    this.grid?.removeEventListener("click", this.onGridClick);
    this.grid?.removeEventListener("pointermove", this.onGridPointerMove);
    this.grid?.removeEventListener("scroll", this.onGridScroll);
    this.nav?.removeEventListener("click", this.onNavClick);
    this.toneButton?.removeEventListener("click", this.onToneButtonClick);
    this.toneRow?.removeEventListener("click", this.onToneRowClick);
  }

  handleCommand(name, params = {}) {
    if (name === "open") return this.request(() => this.open(params || {}));
    if (name === "close") return this.close();
    if (name === "toggle") {
      return this.isOpen()
        ? this.close()
        : this.request(() => this.open(params || {}));
    }
    return undefined;
  }

  // Loads the dataset, then runs `fn` a tick later: after the click that
  // asked for it has been handled by the popover's outside-click monitor.
  request(fn) {
    return this.loadData().then(
      () => new Promise((resolve) => setTimeout(() => resolve(fn()), 0)),
      () => {},
    );
  }

  loadData() {
    if (this.data) return Promise.resolve(this.data);
    dataPromise ||= Promise.resolve()
      .then(() => EmojiPickerComponent.loadData())
      .then((module) => module?.default || module)
      .catch((error) => {
        dataPromise = null;
        console.warn("SaladUI emoji picker: the dataset did not load", error);
        throw error;
      });
    return dataPromise.then((data) => {
      if (!this.destroyed) this.setData(data);
      return data;
    });
  }

  setData(data) {
    if (this.data === data) return;
    this.data = data;
    this.names = new Map();
    for (const group of data.groups) {
      for (const [emoji, name] of group.emoji) this.names.set(emoji, name);
    }
    this.drawNav();
  }

  onDocumentClick(event) {
    const opener = event.target?.closest?.("[data-emoji-picker]");
    if (!opener || opener.dataset.emojiPicker !== this.el.id) return;
    const justClosed =
      this.lastClose &&
      this.lastClose.opener === opener &&
      Date.now() - this.lastClose.at < REOPEN_GUARD_MS;
    const wasOpenHere = (this.isOpen() && this.opener === opener) || justClosed;
    this.request(() => (wasOpenHere ? this.close() : this.open({ opener })));
  }

  isOpen() {
    return this.popover?.dataset.state === "open";
  }

  groupName(group) {
    return this.labels.groups?.[group.key] || group.name;
  }

  /**
   * Opens at `anchor` (an element or selector; the opener by default).
   */
  open({
    opener = null,
    anchor = null,
    event = null,
    values = null,
    return_focus = null,
  } = {}) {
    if (this.destroyed || !this.anchor) return;
    const anchorEl =
      typeof anchor === "string"
        ? document.querySelector(anchor)
        : anchor || opener;
    if (!anchorEl) return;

    this.opener = opener;
    this.returnFocus = return_focus;
    this.target = {
      event: opener?.dataset.emojiEvent || event,
      values: opener ? valuesFrom(opener.dataset) : values || {},
    };

    // On a narrow screen the picker spans the width, 8px in from each side.
    const rect = anchorEl.getBoundingClientRect();
    const vw = document.documentElement.clientWidth;
    const narrow = vw > 0 && vw < 480;
    Object.assign(this.anchor.style, {
      left: `${narrow ? 8 : rect.left}px`,
      top: `${rect.top}px`,
      width: `${narrow ? vw - 16 : rect.width}px`,
      height: `${rect.height}px`,
    });

    this.pending = null;
    this.query = "";
    if (this.search) this.search.value = "";
    this.showTones(false);

    // The popover's focus trap returns focus to what had it when it opened:
    // make that the opener (or, from a menu, `return_focus`).
    const back =
      opener || (return_focus && document.querySelector(return_focus));
    if (back && document.activeElement !== back) {
      back.focus({ preventScroll: true });
    }

    this.wasOpen = true;
    command(this.popover, "open");
    requestAnimationFrame(() => {
      if (this.destroyed) return;
      this.fitColumns();
      this.render();
    });
  }

  close() {
    command(this.popover, "close");
  }

  // The popover's on-close; runs a tick later, after its focus trap has
  // returned focus.
  onClosed() {
    this.lastClose = { opener: this.opener, at: Date.now() };
    setTimeout(() => this.afterClose(), 0);
  }

  afterClose() {
    if (this.destroyed || !this.wasOpen) return;
    this.wasOpen = false;
    const opener = this.opener?.isConnected ? this.opener : null;
    const back =
      opener || (this.returnFocus && document.querySelector(this.returnFocus));
    const pick = this.pending;
    this.pending = null;

    // Escape or a pick: focus goes back where the picker was opened from,
    // unless the person has moved it (or a listener below takes it).
    const active = document.activeElement;
    if (!active || active === document.body || this.panel?.contains(active)) {
      back?.focus({ preventScroll: true });
    }
    if (pick) {
      (opener || this.el).dispatchEvent(
        new CustomEvent("emoji-picker:select", { bubbles: true, detail: pick }),
      );
    }
  }

  // Columns that fit: 36px cells, 44px under a finger.
  fitColumns() {
    if (!this.grid) return;
    const coarse = window.matchMedia?.("(pointer: coarse)").matches;
    const cell = coarse ? 44 : 36;
    const width = this.grid.clientWidth - 8;
    this.cols = width > 0 ? Math.max(6, Math.floor(width / cell)) : 8;
    this.grid.style.setProperty("--emoji-cols", this.cols);
  }

  nameOf(emoji) {
    const bare = emoji.replace(MODIFIERS, "");
    return (
      this.names.get(emoji) ||
      this.names.get(bare) ||
      this.names.get(bare + VS16) ||
      emoji
    );
  }

  sections() {
    const shown = ([emoji, name, toned]) => ({
      emoji: toned ? withTone(emoji, this.tone) : emoji,
      name,
    });
    const q = this.query.trim().toLowerCase();
    if (q) {
      return [
        {
          key: "results",
          name: this.labels.results,
          items: this.searchFor(q).map(shown),
        },
      ];
    }
    const sections = this.data.groups.map((group) => ({
      key: group.key,
      name: this.groupName(group),
      items: group.emoji.map(shown),
    }));
    const recent = read(this.recentKey, []);
    if (Array.isArray(recent) && recent.length > 0) {
      sections.unshift({
        key: "recent",
        name: this.labels.recent,
        items: recent
          .filter((e) => typeof e === "string")
          .map((emoji) => ({ emoji, name: this.nameOf(emoji) })),
      });
    }
    return sections;
  }

  // Every word must be in the name. An exact emoji comes first, then names
  // that start with the query, then those with a word that does.
  searchFor(q) {
    const words = q.split(/\s+/).filter(Boolean);
    const scored = [];
    for (const group of this.data.groups) {
      for (const entry of group.emoji) {
        const name = entry[1].toLowerCase();
        if (entry[0] !== q && !words.every((w) => name.includes(w))) continue;
        const score =
          entry[0] === q
            ? 0
            : name.startsWith(q)
              ? 1
              : name.split(/[\s:,-]+/).some((w) => w.startsWith(words[0]))
                ? 2
                : 3;
        scored.push([score, scored.length, entry]);
      }
    }
    return scored
      .sort((a, b) => a[0] - b[0] || a[1] - b[1])
      .map((item) => item[2]);
  }

  render() {
    if (!this.data || !this.grid) return;
    const sections = this.sections();
    const gridId = this.grid.id;
    this.items = [];
    this.sectionEls = [];
    const fragment = document.createDocumentFragment();

    sections.forEach((section) => {
      if (section.items.length === 0) return;
      const group = document.createElement("div");
      group.setAttribute("role", "group");
      group.dataset.section = section.key;
      const heading = document.createElement("div");
      heading.id = `${gridId}-h-${section.key}`;
      heading.className =
        "sticky top-0 z-10 bg-popover px-1.5 pt-2 pb-1 text-xs font-medium text-muted-foreground";
      heading.textContent = section.name;
      group.setAttribute("aria-labelledby", heading.id);
      const cells = document.createElement("div");
      cells.className =
        "grid grid-cols-[repeat(var(--emoji-cols,8),minmax(0,1fr))]";
      const start = this.items.length;
      section.items.forEach((item, i) => {
        const index = this.items.length;
        const option = document.createElement("div");
        option.id = `${gridId}-o-${index}`;
        option.setAttribute("role", "option");
        option.setAttribute("aria-selected", "false");
        option.setAttribute("aria-label", item.name);
        option.dataset.index = index;
        option.className =
          "flex aspect-square cursor-default items-center justify-center rounded-md text-[22px] leading-none select-none aria-selected:bg-accent";
        option.textContent = item.emoji;
        cells.appendChild(option);
        this.items.push({
          el: option,
          section: this.sectionEls.length,
          i,
          emoji: item.emoji,
          name: item.name,
        });
      });
      group.append(heading, cells);
      fragment.appendChild(group);
      this.sectionEls.push({
        key: section.key,
        el: group,
        start,
        length: section.items.length,
      });
    });

    if (this.items.length === 0) {
      const empty = document.createElement("p");
      empty.className = "px-2 py-6 text-center text-sm text-muted-foreground";
      empty.textContent = this.labels.empty;
      fragment.appendChild(empty);
    }

    this.grid.replaceChildren(fragment);
    this.grid.scrollTop = 0;
    if (this.nav) this.nav.hidden = !!this.query.trim();
    this.drawNavRecent(sections.some((s) => s.key === "recent"));
    this.setActive(this.items.length > 0 ? 0 : -1);
    this.syncNav();
  }

  drawNav() {
    if (!this.nav) return;
    const items = [
      { key: "recent", name: this.labels.recent, icon: CLOCK },
    ].concat(
      this.data.groups.map((group) => ({
        key: group.key,
        name: this.groupName(group),
        icon: group.icon || group.emoji[0][0],
      })),
    );
    this.nav.replaceChildren(
      ...items.map((item) => {
        const button = document.createElement("button");
        button.type = "button";
        button.dataset.sectionKey = item.key;
        button.setAttribute("aria-label", item.name);
        button.title = item.name;
        button.className =
          "flex size-8 flex-none items-center justify-center rounded-md text-base leading-none text-muted-foreground opacity-70 outline-none hover:bg-accent hover:opacity-100 focus-visible:ring-[3px] focus-visible:ring-ring/50 aria-[current=true]:bg-accent aria-[current=true]:opacity-100 pointer-coarse:size-11";
        button.textContent = item.icon;
        return button;
      }),
    );
  }

  drawNavRecent(shown) {
    const button = this.nav?.querySelector('[data-section-key="recent"]');
    if (button) button.hidden = !shown;
  }

  jumpTo(key) {
    const section = this.sectionEls?.find((s) => s.key === key);
    if (!section) return;
    this.grid.scrollTop = section.el.offsetTop;
    this.setActive(section.start, { scroll: false });
    this.search?.focus();
  }

  // The category in view is marked in the row of category buttons.
  syncNav() {
    if (!this.sectionEls?.length || !this.nav) return;
    const top = this.grid.scrollTop + 4;
    let current = this.sectionEls[0].key;
    for (const section of this.sectionEls) {
      if (section.el.offsetTop <= top) current = section.key;
    }
    for (const button of this.nav.children) {
      button.setAttribute(
        "aria-current",
        button.dataset.sectionKey === current ? "true" : "false",
      );
    }
  }

  setActive(index, { scroll = true } = {}) {
    const old = this.items[this.active];
    if (old) old.el.setAttribute("aria-selected", "false");
    this.active = index;
    const item = this.items[index];
    if (!item) {
      this.search?.removeAttribute("aria-activedescendant");
      this.drawPreview(null);
      return;
    }
    item.el.setAttribute("aria-selected", "true");
    this.search?.setAttribute("aria-activedescendant", item.el.id);
    if (scroll) item.el.scrollIntoView?.({ block: "nearest" });
    this.drawPreview(item);
  }

  drawPreview(item) {
    if (!this.preview) return;
    const [glyph, name] = this.preview.children;
    if (glyph) glyph.textContent = item ? item.emoji : "";
    if (name) name.textContent = item ? item.name : "";
  }

  // The arrow keys move through the grid from the search box, which keeps
  // focus and points at the highlighted emoji with aria-activedescendant.
  onKeyDown(event) {
    if (event.isComposing) return;
    const move = {
      ArrowRight: () => this.active + 1,
      ArrowLeft: () => this.active - 1,
      ArrowDown: () => this.vertical(1),
      ArrowUp: () => this.vertical(-1),
    }[event.key];
    if (move) {
      event.preventDefault();
      if (this.items.length === 0) return;
      this.setActive(Math.min(Math.max(move(), 0), this.items.length - 1));
    } else if (event.key === "Enter") {
      event.preventDefault();
      if (this.active >= 0) this.choose(this.active);
    }
  }

  // One row down or up, keeping the column, across category boundaries.
  vertical(dir) {
    const current = this.items[this.active];
    if (!current) return 0;
    const cols = this.cols || 8;
    const section = this.sectionEls[current.section];
    const col = current.i % cols;
    const row = Math.floor(current.i / cols);
    const lastRow = Math.floor((section.length - 1) / cols);
    if (dir > 0) {
      if (row < lastRow) {
        return section.start + Math.min(current.i + cols, section.length - 1);
      }
      const next = this.sectionEls[current.section + 1];
      return next ? next.start + Math.min(col, next.length - 1) : this.active;
    }
    if (row > 0) return section.start + current.i - cols;
    const prev = this.sectionEls[current.section - 1];
    if (!prev) return this.active;
    const prevLast = Math.floor((prev.length - 1) / cols);
    return prev.start + Math.min(prevLast * cols + col, prev.length - 1);
  }

  choose(index) {
    const item = this.items[index];
    if (!item) return;
    const recent = read(this.recentKey, []);
    const rest = Array.isArray(recent)
      ? recent.filter((e) => e !== item.emoji)
      : [];
    write(this.recentKey, [item.emoji, ...rest].slice(0, RECENT_MAX));

    const pick = { emoji: item.emoji, name: item.name };
    const values = this.target?.values || {};
    if (this.target?.event && this.hook?.pushEventTo) {
      this.hook.pushEventTo(this.eventSource(), this.target.event, {
        ...values,
        emoji: pick.emoji,
      });
    }
    this.pushEvent("select", { ...values, ...pick });
    this.pending = pick;
    this.close();
  }

  showTones(show) {
    if (!this.toneRow) return;
    this.toneRow.hidden = !show;
    if (this.preview) this.preview.hidden = show;
    this.toneButton?.setAttribute("aria-expanded", show ? "true" : "false");
    if (!show) return;
    const buttons = [...this.toneRow.querySelectorAll("[data-tone]")];
    buttons.forEach((button, i) => {
      button.textContent = withTone(HAND, i);
      button.setAttribute("aria-label", this.labels.tones[i]);
      button.title = this.labels.tones[i];
      button.setAttribute("aria-pressed", i === this.tone ? "true" : "false");
    });
    buttons[this.tone]?.focus();
  }

  drawToneButton() {
    if (!this.toneButton) return;
    this.toneButton.textContent = withTone(HAND, this.tone);
    this.toneButton.setAttribute(
      "aria-label",
      `${this.labels.tone}: ${this.labels.tones[this.tone]}`,
    );
    this.toneButton.title = this.labels.tone;
  }
}

/**
 * Loads the dataset. A function so tests (or an app serving its own data)
 * can replace it; it must resolve to `{groups: [...]}` or a module whose
 * default export is that.
 */
EmojiPickerComponent.loadData = () => import("./emoji_picker/data.json");

/** Forget a loaded dataset (for tests, after replacing loadData). */
EmojiPickerComponent.resetData = () => {
  dataPromise = null;
};

SaladUI.register("emoji-picker", EmojiPickerComponent);

export default EmojiPickerComponent;
