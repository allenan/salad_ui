// Client-side glue for Salad Chat: LiveView hooks plus a few global
// listeners (keyboard shortcuts, theme, opening the thread sheet on phones).

import DialogComponent from "salad_ui/components/dialog"

const saladCommand = (selector, command, params = {}) => {
  const el = document.querySelector(selector)
  if (!el) return
  el.dispatchEvent(
    new CustomEvent("salad_ui:command", {detail: {command, params}, bubbles: false}),
  )
}

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

// The server asks for the thread sheet when a thread opens. On desktop the
// thread lives in the resizable pane instead, so only phones get the sheet.
window.addEventListener("phx:thread-opened", () => {
  if (isMobile()) saladCommand("#thread-sheet", "open")
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

// The composer textarea: Enter sends, Shift+Enter adds a newline. Emoji and
// slash commands are inserted through custom DOM events.
const Composer = {
  mounted() {
    this.el.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !e.shiftKey && !e.isComposing) {
        e.preventDefault()
        this.el.form?.requestSubmit()
      } else if (e.key === "Escape" && this.el.dataset.escape) {
        e.preventDefault()
        this.pushEvent(this.el.dataset.escape, {})
      }
    })
    this.el.addEventListener("salad-chat:insert", (e) => insertAtCursor(this.el, e.detail.text))
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
      if (id === this.el.id) this.el.value = ""
    })
    this.handleEvent("composer:focus", ({id}) => id === this.el.id && this.el.focus())
  },
}

// The message list. Sticks to the bottom while new messages arrive (unless
// the reader scrolled up), and keeps the reading position when older history
// is prepended at the top.
// TODO(salad-pass-2): use message_scroller once SaladUI ships it.
const ChatScroll = {
  mounted() {
    this.content = this.el.querySelector("[data-scroll-content]") || this.el
    this.stick = true
    this.lastHeight = this.content.scrollHeight
    this.firstId = this.firstRowId()
    this.scrollToBottom()

    this.el.addEventListener("scroll", () => {
      this.stick = this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight < 120
    })

    this.observer = new ResizeObserver(() => this.contentResized())
    this.observer.observe(this.content)

    this.handleEvent("chat:scroll-bottom", () => {
      this.stick = true
      this.scrollToBottom()
    })
  },
  updated() {
    this.contentResized()
  },
  destroyed() {
    this.observer?.disconnect()
  },
  contentResized() {
    const height = this.content.scrollHeight
    const firstId = this.firstRowId()
    const delta = height - this.lastHeight

    if (firstId !== this.firstId && delta > 0 && !this.stick) {
      // Older messages were prepended: keep the same message in view.
      this.el.scrollTop += delta
    } else if (this.stick) {
      this.scrollToBottom()
    }

    this.lastHeight = height
    this.firstId = firstId
  },
  firstRowId() {
    return this.el.querySelector("[data-row]")?.id
  },
  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight
  },
}

export const Hooks = {Composer, ChatScroll}

// ---------------------------------------------------------------------------
// Keep open dialogs and sheets open across LiveView patches.
//
// SaladUI renders `data-state="closed"` / `hidden` on overlay roots and
// parts, and its hook rebuilds a component whenever LiveView patches it. A
// dialog whose content re-renders (form validation, a new reply in the thread
// sheet, presence changes) therefore snaps shut. Until SaladUI preserves this
// state itself, keep the client-owned attributes of *open* dialogs, and skip
// rebuilding them while open.
const CLIENT_ATTRS = ["data-state", "hidden", "aria-hidden", "aria-expanded"]

export const keepOpenOverlays = (from, to) => {
  if (from.nodeType !== Node.ELEMENT_NODE || !from.dataset) return
  const isRoot = from.dataset.component === "dialog"
  const root = isRoot ? from : from.dataset.part && from.closest('[data-component="dialog"]')
  if (!root || root.dataset.state !== "open") return
  if (!isRoot && from.closest("[data-component]") !== root) return

  for (const attr of CLIENT_ATTRS) {
    if (from.hasAttribute(attr)) to.setAttribute(attr, from.getAttribute(attr))
    else to.removeAttribute(attr)
  }
}

DialogComponent.prototype.skipReinitialize = function () {
  return this.state === "open"
}
