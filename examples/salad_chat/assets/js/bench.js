// Client side of /bench (lib/salad_chat_web/live/bench_live.ex): timing
// instrumentation, the `inert` no-op SaladUI hook, the page-level tooltip and
// menu of the `delegated` variant, and an auto-runner that loads every
// variant/N in a plan and stores the numbers in localStorage.
//
// Run all:   open /bench, then in the console: benchRun({reps: 3})
// Results:   JSON.parse(localStorage["bench:results"])

const params = new URLSearchParams(location.search)
export const isBench = location.pathname === "/bench"
const variant = params.get("variant") || "hooks"
const n = Number(params.get("n") || 500)
const auto = params.get("auto") === "1"
// measureUserAgentSpecificMemory() waits for a GC (~20 s), so it is opt-in.
const mem = params.get("mem") === "1"

const B = (window.__bench = {
  variant,
  n,
  hookMounts: 0,
  hookMountMs: 0,
  hookUpdates: 0,
  hookUpdateMs: 0,
  hookDestroys: 0,
  longtasks: [],
  lvReplies: [],
})

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
// Resolves after the next frame has been produced (rAF, then a task).
const painted = () =>
  new Promise((r) =>
    requestAnimationFrame(() => {
      const ch = new MessageChannel()
      ch.port1.onmessage = () => r(performance.now())
      ch.port2.postMessage(0)
    }),
  )
const median = (xs) => {
  const s = xs.filter((x) => x != null).sort((a, b) => a - b)
  return s.length ? s[Math.floor(s.length / 2)] : null
}
const r1 = (x) => (x == null ? null : Math.round(x * 10) / 10)

if (isBench) {
  try {
    new PerformanceObserver((list) => {
      for (const e of list.getEntries()) B.longtasks.push({start: e.startTime, dur: e.duration})
    }).observe({type: "longtask", buffered: true})
  } catch (_e) {}

  // Time-stamp every LiveView reply as it arrives, before Phoenix parses it.
  const WS = window.WebSocket
  window.WebSocket = class extends WS {
    constructor(...args) {
      super(...args)
      this.addEventListener("message", (e) => {
        if (typeof e.data !== "string") return
        const head = e.data.slice(0, 160)
        if (head.includes('"lv:') && head.includes('"phx_reply"')) {
          B.lvReplies.push({at: performance.now(), bytes: e.data.length})
        }
      })
    }
  }
}

export const markConnect = (liveSocket) => {
  // LiveView's debug logging (persisted per tab) would skew the timings.
  if (isBench) liveSocket.disableDebug()
  B.connectAt = performance.now()
}

// Wraps SaladUI's hook to time its callbacks; `inert` skips SaladUI's JS.
export function benchSaladHook(base) {
  if (!isBench) return base
  const inert = variant === "inert"
  return {
    ...base,
    mounted() {
      const s = performance.now()
      if (!inert) base.mounted.call(this)
      const e = performance.now()
      B.hookMounts++
      B.hookMountMs += e - s
      B.lastHookAt = e
    },
    beforeUpdate() {
      if (!inert) base.beforeUpdate.call(this)
    },
    updated() {
      const s = performance.now()
      if (!inert) base.updated.call(this)
      B.hookUpdates++
      B.hookUpdateMs += performance.now() - s
    },
    destroyed() {
      if (!inert) base.destroyed.call(this)
      B.hookDestroys++
    },
  }
}

const longtasksIn = (from, to) => {
  const lts = B.longtasks.filter((l) => l.start >= from - 1 && l.start <= to)
  return {count: lts.length, ms: r1(lts.reduce((a, l) => a + l.dur, 0))}
}

const visible = (el) => !!el && el.checkVisibility()

// Resolves once cond() holds (checked on every DOM mutation), or null on timeout.
const waitFor = (cond, timeout = 3000) =>
  new Promise((resolve) => {
    if (cond()) return resolve(performance.now())
    const obs = new MutationObserver(() => {
      if (cond()) {
        obs.disconnect()
        clearTimeout(t)
        resolve(performance.now())
      }
    })
    obs.observe(document.body, {attributes: true, childList: true, subtree: true})
    const t = setTimeout(() => {
      obs.disconnect()
      resolve(null)
    }, timeout)
  })

async function heap() {
  const out = {usedJSHeapMB: r1(performance.memory?.usedJSHeapSize / 1048576)}
  if (mem && window.crossOriginIsolated && performance.measureUserAgentSpecificMemory) {
    const m = await Promise.race([performance.measureUserAgentSpecificMemory(), sleep(30000)])
    if (m) {
      out.uasmMB = r1(m.bytes / 1048576)
      const by = {}
      for (const b of m.breakdown)
        for (const t of b.types) by[t] = (by[t] || 0) + b.bytes / b.types.length
      out.uasmByType = Object.fromEntries(Object.entries(by).map(([k, v]) => [k, r1(v / 1048576)]))
    }
  }
  return out
}

const BenchDone = {
  mounted() {
    B.doneHookAt = performance.now()
    painted().then((t) => {
      B.mountPaintedAt = t
      this.run()
    })
  },

  status(text) {
    const el = document.getElementById("bench-status")
    if (el) el.textContent = text
  },

  async run() {
    this.status("measuring…")
    await sleep(1200) // let long-task entries arrive
    const join = B.lvReplies[0]
    const mount = {
      total: r1(B.mountPaintedAt - B.connectAt),
      client: join ? r1(B.mountPaintedAt - join.at) : null,
      joinKB: join ? r1(join.bytes / 1024) : null,
      hookMounts: B.hookMounts,
      hookMountMs: r1(B.hookMountMs),
      longtasks: longtasksIn(B.connectAt, B.mountPaintedAt),
      nodes: document.getElementsByTagName("*").length,
    }
    const memory = await heap()

    const mid = Math.max(1, Math.floor(n / 2))
    const updates = []
    for (let rev = 1; rev <= 3; rev++) {
      updates.push(await this.timedPush("update_one", {id: mid, rev}, () => {
        const p = document.querySelector(`#rows-${mid} p`)
        return p && p.textContent.includes(`(edited ${rev})`)
      }))
      await sleep(250)
    }
    const prepend = await this.timedPush("prepend", {}, () => document.getElementById("rows--1"))
    await sleep(300)
    const interaction = await this.interact(mid)

    const result = {variant, n, mount, memory, prepend, updates, update: median(updates.map((u) => u.total)), interaction}
    window.__benchResult = result
    this.status("done")

    if (auto) {
      const results = JSON.parse(localStorage.getItem("bench:results") || "[]")
      results.push(result)
      localStorage.setItem("bench:results", JSON.stringify(results))
      const plan = JSON.parse(localStorage.getItem("bench:plan") || "[]")
      const i = Number(localStorage.getItem("bench:i") || 0) + 1
      localStorage.setItem("bench:i", String(i))
      if (i < plan.length) {
        await sleep(500)
        location.href = planUrl(plan[i])
      } else {
        localStorage.setItem("bench:done", "1")
        this.status("ALL DONE")
      }
    }
  },

  // pushEvent -> reply -> next painted frame. `client` starts when the
  // reply's bytes arrive (excludes the round trip and server time).
  async timedPush(event, payload, applied) {
    const r0 = B.lvReplies.length
    const before = {m: B.hookMounts, mMs: B.hookMountMs, u: B.hookUpdates, uMs: B.hookUpdateMs}
    const t0 = performance.now()
    await new Promise((res) => this.pushEvent(event, payload, () => res()))
    const appliedAtReply = !!applied()
    const t1 = await painted()
    await sleep(200)
    const msg = B.lvReplies[r0]
    return {
      total: r1(t1 - t0),
      client: msg ? r1(t1 - msg.at) : null,
      replyKB: msg ? r1(msg.bytes / 1024) : null,
      appliedAtReply,
      hookMounts: B.hookMounts - before.m,
      hookMountMs: r1(B.hookMountMs - before.mMs),
      hookUpdates: B.hookUpdates - before.u,
      hookUpdateMs: r1(B.hookUpdateMs - before.uMs),
      longtasks: longtasksIn(t0, t1),
    }
  },

  // Synthetic hover / click on row `mid`: time until the popup is visible
  // and painted, minus the configured open delay for tooltips.
  async interact(mid) {
    const row = document.getElementById(`rows-${mid}`)
    if (!row || !(variant === "hooks" || variant === "delegated")) return null
    const out = {}
    const ev = (el, type, init = {}) =>
      el.dispatchEvent(new MouseEvent(type, {bubbles: true, cancelable: true, view: window, ...init}))

    if (variant === "hooks") {
      const tip = row.querySelector(`[id$="-reply-tip"]`)
      const trig = tip.querySelector('[data-part="trigger"]')
      const content = tip.querySelector('[data-part="content"]')
      let t0 = performance.now()
      ev(trig, "mouseover")
      let shown = await waitFor(() => visible(content))
      out.tooltip = shown ? r1((await painted()) - t0 - 150) : null
      ev(trig, "mouseout", {relatedTarget: document.body})
      await sleep(400)

      const menu = row.querySelector(`[id$="-more"]`)
      t0 = performance.now()
      menu.querySelector('[data-part="trigger"]').click()
      shown = await waitFor(() => menu.dataset.state === "open")
      out.menu = shown ? r1((await painted()) - t0) : null
      menu.dispatchEvent(new CustomEvent("salad_ui:command", {detail: {command: "close", params: {}}}))
      await sleep(400)

      const ctx = row.querySelector(`[id$="-context"]`)
      const ctxTrig = ctx.querySelector('[data-part="trigger"]')
      const r = ctxTrig.getBoundingClientRect()
      t0 = performance.now()
      ev(ctxTrig, "contextmenu", {clientX: r.left + 20, clientY: r.top + 10, button: 2})
      shown = await waitFor(() => ctx.dataset.state === "open")
      out.contextMenu = shown ? r1((await painted()) - t0) : null
      ctx.dispatchEvent(new CustomEvent("salad_ui:command", {detail: {command: "close", params: {}}}))
      await sleep(400)
    } else {
      const tipEl = document.querySelector("[data-shared-tooltip]")
      const menuEl = document.querySelector("[data-shared-menu]")
      const trig = row.querySelector('[data-tooltip="Reply in thread"]')
      let t0 = performance.now()
      ev(trig, "mouseover")
      let shown = await waitFor(() => visible(tipEl))
      out.tooltip = shown ? r1((await painted()) - t0 - 150) : null
      ev(trig, "mouseout", {relatedTarget: document.body})
      await sleep(400)

      t0 = performance.now()
      row.querySelector("[data-menu]").click()
      shown = await waitFor(() => visible(menuEl))
      out.menu = shown ? r1((await painted()) - t0) : null
      document.dispatchEvent(new KeyboardEvent("keydown", {key: "Escape", bubbles: true}))
      await sleep(400)

      const r = row.getBoundingClientRect()
      t0 = performance.now()
      ev(row.firstElementChild, "contextmenu", {clientX: r.left + 20, clientY: r.top + 10, button: 2})
      shown = await waitFor(() => visible(menuEl))
      out.contextMenu = shown ? r1((await painted()) - t0) : null
      document.dispatchEvent(new KeyboardEvent("keydown", {key: "Escape", bubbles: true}))
      await sleep(400)
    }
    return out
  },
}

// The redesign prototype: one tooltip and one menu for the whole page,
// driven by document-level event delegation.
const BenchShared = {
  mounted() {
    const tip = this.el.querySelector("[data-shared-tooltip]")
    const menu = this.el.querySelector("[data-shared-menu]")
    let timer = null
    let current = null
    let menuFor = null

    const place = (el, x, y, alignRight) => {
      el.hidden = false
      const w = el.offsetWidth
      const h = el.offsetHeight
      const left = Math.min(Math.max(4, alignRight ? x - w : x), innerWidth - w - 4)
      const top = y + h > innerHeight - 4 ? y - h : y
      el.style.left = `${left}px`
      el.style.top = `${Math.max(4, top)}px`
    }
    const closeMenu = () => {
      menu.hidden = true
      menuFor = null
    }

    this.onOver = (e) => {
      const t = e.target.closest?.("[data-tooltip]")
      if (!t || t === current) return
      clearTimeout(timer)
      timer = setTimeout(() => {
        current = t
        tip.textContent = t.dataset.tooltip
        tip.hidden = false
        const r = t.getBoundingClientRect()
        tip.style.left = `${r.left + r.width / 2 - tip.offsetWidth / 2}px`
        tip.style.top = `${r.top - tip.offsetHeight - 8}px`
      }, 150)
    }
    this.onOut = (e) => {
      const t = e.target.closest?.("[data-tooltip]")
      if (!t || (e.relatedTarget && t.contains(e.relatedTarget))) return
      clearTimeout(timer)
      current = null
      tip.hidden = true
    }
    this.onClick = (e) => {
      const item = e.target.closest?.("[data-menu-action],[data-menu-emoji]")
      if (item && menu.contains(item)) {
        this.pushEvent("menu_action", {id: menuFor, action: item.dataset.menuAction, emoji: item.dataset.menuEmoji})
        return closeMenu()
      }
      const b = e.target.closest?.("[data-menu]")
      if (b) {
        menuFor = b.dataset.menu
        const r = b.getBoundingClientRect()
        place(menu, r.right, r.bottom + 4, true)
      } else if (!menu.contains(e.target)) closeMenu()
    }
    this.onContext = (e) => {
      const row = e.target.closest?.("[data-menu-row]")
      if (!row) return
      e.preventDefault()
      menuFor = row.dataset.menuRow
      place(menu, e.clientX, e.clientY, false)
    }
    this.onKey = (e) => e.key === "Escape" && closeMenu()

    document.addEventListener("mouseover", this.onOver)
    document.addEventListener("mouseout", this.onOut)
    document.addEventListener("click", this.onClick)
    document.addEventListener("contextmenu", this.onContext)
    document.addEventListener("keydown", this.onKey)
  },
  destroyed() {
    document.removeEventListener("mouseover", this.onOver)
    document.removeEventListener("mouseout", this.onOut)
    document.removeEventListener("click", this.onClick)
    document.removeEventListener("contextmenu", this.onContext)
    document.removeEventListener("keydown", this.onKey)
  },
}

export const BenchHooks = {BenchDone, BenchShared}

const planUrl = (p) => `/bench?variant=${p.variant}&n=${p.n}&auto=1${p.mem ? "&mem=1" : ""}`

// Start a full run: every variant x N, `reps` times, interleaved.
window.benchRun = ({reps = 3, ns = [100, 500, 1000, 2000], variants = ["hooks", "inert", "plain", "delegated"]} = {}) => {
  const plan = []
  // The first rep also measures memory (slow, see heap()).
  for (let r = 0; r < reps; r++) for (const nn of ns) for (const v of variants) plan.push({variant: v, n: nn, mem: r === 0})
  localStorage.setItem("bench:plan", JSON.stringify(plan))
  localStorage.setItem("bench:i", "0")
  localStorage.setItem("bench:results", "[]")
  localStorage.removeItem("bench:done")
  location.href = planUrl(plan[0])
}

// Medians per variant x N from the stored results.
window.benchSummary = () => {
  const results = JSON.parse(localStorage.getItem("bench:results") || "[]")
  const groups = {}
  for (const r of results) (groups[`${r.variant}|${r.n}`] ||= []).push(r)
  return Object.entries(groups).map(([k, rs]) => {
    const [v, nn] = k.split("|")
    const m = (f) => r1(median(rs.map(f)))
    return {
      variant: v,
      n: Number(nn),
      runs: rs.length,
      mountTotal: m((r) => r.mount.total),
      mountClient: m((r) => r.mount.client),
      hookMountMs: m((r) => r.mount.hookMountMs),
      longtaskMs: m((r) => r.mount.longtasks.ms),
      longtaskCount: m((r) => r.mount.longtasks.count),
      joinKB: m((r) => r.mount.joinKB),
      nodes: m((r) => r.mount.nodes),
      heapMB: m((r) => r.memory.uasmMB),
      domMB: m((r) => r.memory.uasmByType?.DOM),
      jsMB: m((r) => r.memory.uasmByType?.JavaScript),
      jsHeapMB: m((r) => r.memory.usedJSHeapMB),
      prependTotal: m((r) => r.prepend.total),
      prependClient: m((r) => r.prepend.client),
      prependHookMs: m((r) => r.prepend.hookMountMs),
      updateTotal: m((r) => r.update),
      updateClient: m((r) => median(r.updates.map((u) => u.client))),
      updateHookMs: m((r) => median(r.updates.map((u) => u.hookUpdateMs))),
      tooltip: m((r) => r.interaction?.tooltip),
      menu: m((r) => r.interaction?.menu),
      contextMenu: m((r) => r.interaction?.contextMenu),
    }
  })
}
