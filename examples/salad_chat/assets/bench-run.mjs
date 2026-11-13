// Drives /bench in a headless Chrome over CDP and prints medians per
// variant x N. A visible Chrome window that is occluded throttles timers and
// frames (numbers of ~1 s and 25 s+ page loads), so the run uses its own
// headless instance.
//
//   CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
//   "$CHROME" --headless=new --remote-debugging-port=9333 \
//     --user-data-dir=/tmp/bench-chrome --enable-precise-memory-info \
//     --js-flags=--expose-gc --window-size=1440,900 about:blank &
//   node assets/bench-run.mjs [baseUrl] [reps] > results.json
//
// Env: NS=100,500 VARIANTS=hooks,plain MEM=1 (also measureUserAgentSpecificMemory
// on the first rep; ~20 s per page) TIMEOUT_S=300 EXTRA="&modal=0" (appended to
// every URL).

const base = process.argv[2] || "http://localhost:4107"
const reps = Number(process.argv[3] || 3)
const ns = (process.env.NS || "100,500,1000,2000").split(",").map(Number)
const variants = (process.env.VARIANTS || "hooks,inert,plain,delegated").split(",")
const timeoutS = Number(process.env.TIMEOUT_S || 300)
const debug = process.env.CDP || "http://127.0.0.1:9333"

let ws
let id = 0
const pending = new Map()
const send = (method, params = {}) =>
  new Promise((resolve) => {
    const i = ++id
    pending.set(i, resolve)
    ws.send(JSON.stringify({id: i, method, params}))
  })
const evaluate = async (expression) =>
  (await send("Runtime.evaluate", {expression, returnByValue: true})).result?.result?.value

// A fresh tab per page, closed afterwards, so a page that is still busy
// (e.g. a timed-out one) does not slow down the next.
async function openTab() {
  const target = await (await fetch(`${debug}/json/new?about:blank`, {method: "PUT"})).json()
  ws = new WebSocket(target.webSocketDebuggerUrl)
  ws.addEventListener("message", (e) => {
    const msg = JSON.parse(e.data)
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg)
      pending.delete(msg.id)
    }
  })
  await new Promise((r) => ws.addEventListener("open", r, {once: true}))
  return target
}
async function closeTab(target) {
  ws.close()
  pending.clear()
  await fetch(`${debug}/json/close/${target.id}`).catch(() => {})
  await new Promise((s) => setTimeout(s, 1000))
}

const results = []
for (let r = 0; r < reps; r++) {
  for (const n of ns) {
    for (const variant of variants) {
      const mem = process.env.MEM === "1" && r === 0 ? "&mem=1" : ""
      const url = `${base}/bench?variant=${variant}&n=${n}${mem}${process.env.EXTRA || ""}`
      const tab = await openTab()
      const t0 = Date.now()
      await send("Page.navigate", {url})
      let res = null
      while (!res && Date.now() - t0 < timeoutS * 1000) {
        await new Promise((s) => setTimeout(s, 500))
        const v = await Promise.race([
          evaluate("window.__benchResult && JSON.stringify(window.__benchResult)"),
          new Promise((s) => setTimeout(() => s(null), 5000)),
        ])
        if (v) res = JSON.parse(v)
      }
      const wallS = (Date.now() - t0) / 1000
      await closeTab(tab)
      console.error(`${variant} n=${n} rep=${r} ${res ? "ok" : "TIMEOUT"} ${wallS}s`)
      results.push(res ? {...res, wallS} : {variant, n, timeout: true, wallS})
    }
  }
}

console.log(JSON.stringify(results))
process.exit(0)
