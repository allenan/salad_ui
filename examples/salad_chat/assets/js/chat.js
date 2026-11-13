// Client-side glue for Salad Chat: LiveView hooks plus a few global
// listeners (keyboard shortcuts, theme, opening the thread sheet on phones).

import {attachFiles} from "salad_ui/components/drop_zone"

const saladCommand = (selector, command, params = {}) => {
  const el = document.querySelector(selector)
  if (!el) return
  el.dispatchEvent(
    new CustomEvent("salad_ui:command", {detail: {command, params}, bubbles: false}),
  )
}

// SaladUI's emoji picker reports a pick as a bubbling `emoji-picker:select`
// on the button that opened it; the composer's emoji button names its
// textarea in `data-insert-into`.
document.addEventListener("emoji-picker:select", (e) => {
  const target = e.target.closest?.("[data-insert-into]")
  const input = target && document.querySelector(target.dataset.insertInto)
  if (input) input.dispatchEvent(new CustomEvent("salad-chat:insert", {detail: {text: e.detail.emoji}}))
})

const isMobile = () => window.matchMedia("(max-width: 767px)").matches

// ---------------------------------------------------------------------------
// Theme: "light" | "dark" | "system", stored in localStorage. The root layout
// applies it before first paint; this keeps it in sync afterwards.

const systemTheme = () =>
  window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"

export const currentTheme = () => localStorage.getItem("salad-chat:theme") || "system"

export const applyTheme = (theme) => {
  const resolved = theme === "system" ? systemTheme() : theme
  const root = document.documentElement
  root.classList.toggle("dark", resolved === "dark")
  root.setAttribute("data-theme", resolved)
  root.style.colorScheme = resolved
  if (theme === "system") localStorage.removeItem("salad-chat:theme")
  else localStorage.setItem("salad-chat:theme", theme)
}

window.addEventListener("phx:set-theme", (e) => applyTheme(e.detail.theme))
window.addEventListener("salad-chat:toggle-theme", () =>
  applyTheme(document.documentElement.classList.contains("dark") ? "light" : "dark"),
)
window
  .matchMedia("(prefers-color-scheme: dark)")
  .addEventListener("change", () => currentTheme() === "system" && applyTheme("system"))

// ---------------------------------------------------------------------------
// Keyboard shortcuts

window.addEventListener("keydown", (e) => {
  const mod = e.metaKey || e.ctrlKey

  // ⌘K / Ctrl+K: quick switcher
  if (mod && e.key.toLowerCase() === "k") {
    e.preventDefault()
    saladCommand("#quick-switcher_dialog", "open")
    return
  }

  // ⌥1-⌥5: jump to the first five channels
  if (e.altKey && /^Digit[1-9]$/.test(e.code)) {
    const link = document.querySelector(`[data-shortcut="${e.code.slice(5)}"]`)
    if (link) {
      e.preventDefault()
      link.click()
    }
  }
})

// "Copy text" in a message's ⋮ / right-click menu. The menus are shared by
// every message, so the item knows its message only by the open menu's
// context: the `phx-value-id` SaladUI writes on it while the menu is open.
window.addEventListener("salad-chat:copy", (e) => {
  const id = e.detail?.id ?? e.target?.getAttribute?.("phx-value-id")
  const text =
    e.detail?.text ??
    document.querySelector(`[data-message-id="m-${id}"] [data-message-text]`)?.innerText
  if (text) navigator.clipboard?.writeText(text.trim()).catch(() => {})
})

// The server asks for the thread sheet when a thread opens. On desktop the
// thread lives in the resizable pane instead, so only phones get the sheet.
window.addEventListener("phx:thread-opened", () => {
  if (isMobile()) saladCommand("#thread-sheet", "open")
})

// The layout shell never scrolls; only its panes do. Focusing an input near
// the bottom (iOS Safari, scrollIntoView) can still scroll a clipped/hidden
// ancestor, which then can't be scrolled back by the user. Undo that.
document.addEventListener(
  "scroll",
  (e) => {
    const el = e.target
    if (el instanceof Element && el.hasAttribute("data-no-scroll")) {
      el.scrollTop = 0
      el.scrollLeft = 0
    }
  },
  true,
)

// iOS/iPadOS Safari: with the keyboard (or its shortcut bar) up, the visible
// area is shorter than the layout viewport and Safari pans the page to keep
// the focused composer in view, pushing the header and sidebar top off
// screen. Fit the app shell to the visible height instead (--app-height, see
// app.css) and undo the pan.
if (window.visualViewport) {
  const viewport = window.visualViewport
  let frame = null
  const fit = () => {
    frame = null
    const root = document.documentElement
    if (viewport.height < window.innerHeight - 1) {
      root.style.setProperty("--app-height", `${Math.round(viewport.height)}px`)
    } else {
      root.style.removeProperty("--app-height")
    }
    if (window.scrollY !== 0 || viewport.offsetTop !== 0) window.scrollTo(0, 0)
  }
  const schedule = () => frame ?? (frame = requestAnimationFrame(fit))
  viewport.addEventListener("resize", schedule)
  viewport.addEventListener("scroll", schedule)
  window.addEventListener("focusin", schedule)
}

// Tapping an @mention in a message opens that person's profile card, like
// hovering a sender's name. One popover serves every mention: anchor it on
// the mention, show that person's card, open it.
document.addEventListener("click", (e) => {
  const mention = e.target.closest?.("[data-mention]")
  const anchor = document.getElementById("mention-profile-anchor")
  if (!mention || !anchor) return

  const rect = mention.getBoundingClientRect()
  Object.assign(anchor.style, {
    left: `${rect.left}px`,
    top: `${rect.top}px`,
    width: `${rect.width}px`,
    height: `${rect.height}px`,
  })
  document.querySelectorAll("[data-profile]").forEach((card) => {
    card.hidden = card.dataset.profile !== mention.dataset.mention
  })
  // After this click's own outside-click handling (which closes a popover
  // already open on another mention), so it reopens at the new anchor.
  setTimeout(() => saladCommand("#mention-profile", "open"), 0)
})

// ---------------------------------------------------------------------------
// Hooks

const insertAtCursor = (el, text) => {
  const start = el.selectionStart ?? el.value.length
  const end = el.selectionEnd ?? el.value.length
  el.value = el.value.slice(0, start) + text + el.value.slice(end)
  el.selectionStart = el.selectionEnd = start + text.length
  el.focus()
  el.dispatchEvent(new Event("input", {bubbles: true}))
}

// The `@query` right before the caret ("@" at the start or after a space or
// bracket), or null. `start` is the index of the "@".
const mentionAt = (el) => {
  const caret = el.selectionStart ?? 0
  if (caret !== el.selectionEnd) return null
  const match = el.value.slice(0, caret).match(/(^|[\s([{])@([a-z0-9_]*)$/i)
  return match && {query: match[2].toLowerCase(), start: caret - match[2].length - 1}
}

// The composer textarea: Enter sends, Shift+Enter adds a newline. Emoji and
// slash commands are inserted through custom DOM events. Typing "@" asks the
// server for people to mention; while that list is open the textarea keeps
// focus and ↑ ↓ move the highlight, Enter/Tab pick, Escape dismisses
// (WAI-ARIA combobox with aria-activedescendant).
const Composer = {
  mentionOptions() {
    const list = document.getElementById(`${this.el.dataset.composer}-mentions`)
    return list ? Array.from(list.querySelectorAll("[role=option]")) : []
  },

  applyMention() {
    const options = this.mentionOptions()
    if (options.length === 0) {
      this.el.removeAttribute("aria-activedescendant")
      return
    }
    this.mentionIndex = Math.min(Math.max(this.mentionIndex || 0, 0), options.length - 1)
    options.forEach((option, i) => option.setAttribute("aria-selected", String(i === this.mentionIndex)))
    const active = options[this.mentionIndex]
    this.el.setAttribute("aria-activedescendant", active.id)
    active.scrollIntoView({block: "nearest"})
  },

  syncMention() {
    const at = mentionAt(this.el)
    // Escape dismissed this "@"; a new one (or leaving it) re-arms.
    if (at && at.start === this.dismissedAt) return
    if (!at || at.start !== this.dismissedAt) this.dismissedAt = null
    const query = at ? at.query : null
    if (query === this.mentionQuery) return
    this.mentionQuery = query
    this.mentionIndex = 0
    this.pushEvent("mention_query", {composer: this.el.dataset.composer, query})
  },

  closeMention({dismiss = false} = {}) {
    if (dismiss) this.dismissedAt = mentionAt(this.el)?.start ?? null
    if (this.mentionQuery === null || this.mentionQuery === undefined) return
    this.mentionQuery = null
    this.pushEvent("mention_query", {composer: this.el.dataset.composer, query: null})
  },

  pickMention(handle) {
    const at = mentionAt(this.el)
    if (!at) return
    const caret = this.el.selectionStart
    const text = `@${handle} `
    this.el.value = this.el.value.slice(0, at.start) + text + this.el.value.slice(caret)
    this.el.selectionStart = this.el.selectionEnd = at.start + text.length
    this.el.focus({preventScroll: true})
    this.el.dispatchEvent(new Event("input", {bubbles: true}))
  },

  // Mention chips: the textarea can't style part of its text, so an overlay
  // behind it (same box, font and wrapping, transparent text) draws a chip
  // background under every @handle of a known person.
  readMentionHandles() {
    try {
      this.mentionHandles = new Set(JSON.parse(this.el.dataset.mentionHandles || "[]"))
    } catch {
      this.mentionHandles = new Set()
    }
  },

  renderHighlights() {
    const overlay = document.getElementById(`${this.el.dataset.composer}-highlights`)
    if (!overlay) return
    const ta = this.el
    const style = getComputedStyle(ta)
    for (const property of [
      "fontFamily", "fontSize", "fontWeight", "fontStyle", "letterSpacing", "wordSpacing",
      "lineHeight", "tabSize", "textIndent", "boxSizing", "paddingTop", "paddingBottom",
      "paddingLeft", "borderTopWidth", "borderRightWidth", "borderBottomWidth", "borderLeftWidth",
    ]) {
      overlay.style[property] = style[property]
    }
    // A visible scrollbar narrows the textarea's text box.
    const scrollbar =
      ta.offsetWidth - ta.clientWidth -
      parseFloat(style.borderLeftWidth) - parseFloat(style.borderRightWidth)
    overlay.style.paddingRight = `${parseFloat(style.paddingRight) + scrollbar}px`
    overlay.style.borderStyle = "solid"
    overlay.style.borderColor = "transparent"
    Object.assign(overlay.style, {
      top: `${ta.offsetTop}px`,
      left: `${ta.offsetLeft}px`,
      width: `${ta.offsetWidth}px`,
      height: `${ta.offsetHeight}px`,
    })

    const escape = (text) =>
      text.replace(/[&<>"]/g, (c) => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;"})[c])
    // Same rule as message_format.ex: "@" not preceded by a word char, @, & or #.
    overlay.innerHTML =
      escape(ta.value).replace(/(^|[^\w@&#;])@([a-z][a-z0-9_]*)/gi, (whole, before, handle) =>
        this.mentionHandles.has(handle.toLowerCase()) ? `${before}<mark>@${handle}</mark>` : whole,
      ) + "\u200b"
    overlay.scrollTop = ta.scrollTop
  },

  updated() {
    this.readMentionHandles()
    this.renderHighlights()
  },

  destroyed() {
    this.resizeObserver?.disconnect()
  },

  mounted() {
    this.el.__composer = this
    this.readMentionHandles()
    const render = () => this.renderHighlights()
    this.el.addEventListener("input", render)
    this.el.addEventListener("scroll", render)
    this.resizeObserver = new ResizeObserver(render)
    this.resizeObserver.observe(this.el)
    render()

    const sync = () => this.syncMention()
    this.el.addEventListener("input", sync)
    this.el.addEventListener("click", sync)
    this.el.addEventListener("keyup", (e) => {
      if (["ArrowLeft", "ArrowRight", "Home", "End"].includes(e.key)) sync()
    })
    this.el.addEventListener("blur", () => {
      // A click on an option keeps focus (mousedown is prevented), so a real
      // blur means the user left the composer.
      this.blurTimer = setTimeout(() => this.closeMention(), 150)
    })
    this.el.addEventListener("focus", () => clearTimeout(this.blurTimer))
    this.el.addEventListener("salad-chat:mention", (e) => this.pickMention(e.detail.handle))

    this.el.addEventListener("keydown", (e) => {
      const options = this.mentionOptions()
      if (options.length > 0 && !e.isComposing) {
        if (e.key === "ArrowDown" || e.key === "ArrowUp") {
          e.preventDefault()
          const step = e.key === "ArrowDown" ? 1 : -1
          this.mentionIndex = ((this.mentionIndex || 0) + step + options.length) % options.length
          this.applyMention()
          return
        }
        if ((e.key === "Enter" && !e.shiftKey) || e.key === "Tab") {
          e.preventDefault()
          this.pickMention(options[this.mentionIndex || 0].dataset.handle)
          return
        }
        if (e.key === "Escape") {
          e.preventDefault()
          e.stopPropagation()
          this.closeMention({dismiss: true})
          return
        }
      }

      if (e.key === "Enter" && !e.shiftKey && !e.isComposing) {
        e.preventDefault()
        this.el.form?.requestSubmit()
      } else if (e.key === "Escape" && this.el.dataset.escape) {
        e.preventDefault()
        this.pushEvent(this.el.dataset.escape, {})
      }
    })
    this.el.addEventListener("salad-chat:insert", (e) => insertAtCursor(this.el, e.detail.text))
    // Pasted files (a screenshot) attach like dropped ones: SaladUI's
    // attachFiles hands them to the composer's live_file_input.
    this.el.addEventListener("paste", (e) => {
      const files = e.clipboardData?.files
      const input = this.el.form?.querySelector("input[type=file]")
      if (!files?.length || !input) return
      e.preventDefault()
      attachFiles(input, files)
    })
    this.el.addEventListener("salad-chat:set-text", (e) => {
      this.el.value = ""
      insertAtCursor(this.el, e.detail.text)
    })
    this.handleEvent("composer:set-text", ({id, text}) => {
      if (id !== this.el.id) return
      this.el.value = ""
      insertAtCursor(this.el, text)
    })
    this.handleEvent("composer:clear", ({id}) => {
      if (id !== this.el.id) return
      this.el.value = ""
      this.mentionQuery = null
      this.dismissedAt = null
      this.renderHighlights()
    })
    this.handleEvent(
      "composer:focus",
      ({id}) => id === this.el.id && this.el.focus({preventScroll: true}),
    )
  },
}

// The @mention list under a composer: keeps the composer's highlight across
// LiveView patches, and keeps focus in the textarea when an option is clicked.
const MentionList = {
  mounted() {
    this.el.addEventListener("mousedown", (e) => e.preventDefault())
    this.updated()
  },
  updated() {
    document.getElementById(this.el.dataset.input)?.__composer?.applyMention()
  },
  destroyed() {
    document.getElementById(this.el.dataset.input)?.removeAttribute("aria-activedescendant")
  },
}

export const Hooks = {Composer, MentionList}
