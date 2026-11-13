// Client-side glue for Salad Chat: LiveView hooks plus a few global
// listeners (keyboard shortcuts, theme, opening the thread sheet on phones).

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

// "Copy text" in a message's ⋮ / right-click menu.
window.addEventListener("salad-chat:copy", (e) => {
  navigator.clipboard?.writeText(e.detail.text).catch(() => {})
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

export const Hooks = {Composer}
