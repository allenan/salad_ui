export const meta = {
  name: 'shadcn-parity',
  description: 'Trimmed SaladUI -> shadcn/ui parity: one agent per grouped item (implement + gate + push), one reviewer-fixer for JS items, one completeness critic',
  whenToUse: 'Bring SaladUI to shadcn/ui parity. args.done = item ids already on parity/integration; args.only = pilot subset.',
  phases: [
    { title: 'Implement', detail: 'one worktree agent per item; rebases + pushes to parity/integration' },
    { title: 'Review', detail: 'JS items only: one reviewer that fixes in place' },
    { title: 'Critique', detail: 'one critic per round (max 2); writes status + changelog' },
  ],
}

// ---------------------------------------------------------------- config
const A = args || {}
const CFG = {
  repo: A.repo || '/Users/andrew/code/personal/salad/salad_ui',
  branch: A.integrationBranch || 'parity/integration',
  shadcnRef: A.shadcnRef || 'dd41d19e2f80ff6891951f7ced74c2c9a650b065',
  only: A.only || null,
  done: A.done || [],
  criticRounds: A.criticRounds ?? 2,
  includeStyles: A.includeStyles === true,
  decisions: Object.assign({
    field: 'Add `field` alongside `form`; mark `form` legacy in docs (no removal).',
    calendar: 'Server-rendered month grid + small JS for focus/keyboard.',
    dataTable: 'Documented recipe + `SaladUI.DataTable` helpers (sort/filter/paginate params, column visibility) on table/dropdown/pagination/checkbox; not a monolith.',
    chart: 'Keep Chart.js; add shadcn-style chart_container config (labels, colors -> --chart-N), styled tooltip + legend.',
  }, A.decisions || {}),
}
const D = k => CFG.decisions[k]

// ---------------------------------------------------------------- items
// kind: 'css' = markup/classes only (no reviewer); 'js' = interactive (one reviewer-fixer).
// deps: ids that must be pushed to the integration branch before this starts.
const ITEMS = [
  { id: 'tailwind-drift', kind: 'css', deps: [], refs: ['button', 'badge', 'checkbox', 'input', 'toggle', 'tooltip'],
    spec: 'Tailwind v4 drift (docs/shadcn-parity.md §3b): shadow scale like shadcn v4; aria-invalid error styling on input/textarea/select trigger/checkbox/radio/switch/toggle (also set aria-invalid="true" — never a bare attribute — when a FormField has errors); destructive button/badge text-white (keep --destructive-foreground defined); h-N w-N -> size-N. A branch parity/tailwind-drift with prior work exists — resume it.' },
  { id: 'data-slot', kind: 'css', deps: ['tailwind-drift'], refs: ['*'],
    spec: 'Add data-slot attributes to every rendered part of every existing component using exactly shadcn\'s slot names (fetch each matching shadcn file). One assertion per component in tests.' },

  { id: 'small-deltas', kind: 'css', deps: ['data-slot'], refs: ['button', 'badge', 'card', 'dialog', 'alert-dialog', 'command', 'switch', 'avatar', 'scroll-area'],
    spec: 'Button sizes xs/icon-xs/icon-sm/icon-lg; badge ghost+link variants and link rendering (href -> <a>); card_action; dialog_close; alert_dialog_media; command_separator; switch size sm; avatar size + avatar_group + avatar_group_count + avatar_badge; scroll_area horizontal scrollbar.' },
  { id: 'overlay-deltas', kind: 'js', deps: ['data-slot'], refs: ['popover', 'tabs', 'select'],
    spec: 'popover_header/title/description + popover_anchor; tabs orientation="vertical" (Up/Down keys, aria-orientation) + tabs_list variant="line"; select_trigger size="sm" + scroll up/down buttons.' },
  { id: 'dropdown-menu-sub-radio', kind: 'js', deps: ['data-slot'], refs: ['dropdown-menu'],
    spec: 'Sub-menus (sub/sub_trigger/sub_content; ArrowRight opens, ArrowLeft closes, hover) and radio_group/radio_item with on-value-changed. WAI-ARIA menu pattern.' },
  { id: 'slider-range', kind: 'js', deps: ['data-slot'], refs: ['slider'],
    spec: 'Multiple thumbs/range (value list), vertical orientation, float step, one form input per thumb, per-thumb keyboard. Single-value API stays compatible.' },
  { id: 'chart-theming', kind: 'js', deps: ['data-slot'], refs: ['chart'], spec: `Chart parity. ${D('chart')} One storybook example each: area, bar, line, pie, radar, radial.` },

  { id: 'form-primitives', kind: 'css', deps: ['data-slot'], refs: ['field', 'native-select'],
    spec: `Field family (field_set/legend/group, field, field_content/label/title/description/separator/error; orientation vertical/horizontal/responsive; FormField-aware errors) and native_select (options/optgroups, size, FormField, aria-invalid). ${D('field')}` },
  { id: 'group-primitives', kind: 'css', deps: ['small-deltas'], refs: ['input-group', 'button-group'],
    spec: 'input_group (+addon with align inline-start/inline-end/block-start/block-end, button, text, input, textarea; clicking an addon focuses the control) and button_group (+separator, +text, orientation).' },
  { id: 'display-primitives', kind: 'css', deps: ['data-slot'], refs: ['item', 'empty', 'kbd', 'spinner', 'aspect-ratio'], docs: ['typography'],
    spec: 'item family (all parts, variants, sizes, link rendering), empty family, kbd + kbd_group, spinner, aspect_ratio, typography components per the shadcn docs page.' },

  { id: 'calendar-date-picker', kind: 'js', deps: ['small-deltas', 'overlay-deltas'], refs: ['calendar'], docs: ['date-picker'],
    spec: `Calendar (single/multiple/range, min/max, disabled dates, week start, multiple months, caption dropdowns, grid keyboard nav, FormField) then date picker (popover + calendar; range + presets; ISO hidden inputs). ${D('calendar')}` },
  { id: 'combobox', kind: 'js', deps: ['overlay-deltas', 'group-primitives'], refs: ['combobox'],
    spec: 'Single + multiple (chips), client filtering and server filtering via phx-change/debounce, empty state, groups, FormField. Combobox ARIA pattern.' },
  { id: 'context-menu-menubar', kind: 'js', deps: ['dropdown-menu-sub-radio'], refs: ['context-menu', 'menubar'],
    spec: 'Context menu (opened at pointer, long-press on touch) and menubar (roving focus across menus, hover-switch once open), both with every dropdown item type incl. subs. Reuse dropdown internals.' },
  { id: 'navigation-menu', kind: 'js', deps: ['data-slot'], refs: ['navigation-menu'], spec: 'list/item/trigger/content/link/indicator/viewport; hover + keyboard; animated viewport sizing.' },
  { id: 'drawer', kind: 'js', deps: ['data-slot'], refs: ['drawer'], spec: 'vaul-style: directions, drag-to-dismiss, snap points, handle; trigger/content/header/footer/title/description/close.' },
  { id: 'input-otp', kind: 'js', deps: ['data-slot'], refs: ['input-otp'], spec: 'input_otp/_group/_slot/_separator; paste, pattern, caret, one hidden real input, autocomplete="one-time-code".' },
  { id: 'carousel', kind: 'js', deps: ['small-deltas'], refs: ['carousel'], spec: 'content/item/previous/next; horizontal/vertical; loop; keyboard; basis-based slides per view; on-select event. CSS scroll-snap + small JS, no new npm dep.' },
  { id: 'resizable', kind: 'js', deps: ['data-slot'], refs: ['resizable'], spec: 'panel_group/panel/handle (with_handle); horizontal/vertical; min/max/default; keyboard resize; optional localStorage persistence; nesting.' },
  { id: 'data-table', kind: 'js', deps: ['dropdown-menu-sub-radio', 'small-deltas'], docs: ['data-table'], refs: [],
    spec: `${D('dataTable')} Reproduce the shadcn docs example (sorting, filtering, pagination, column visibility, row selection) as a storybook LiveView example using streams.` },

  { id: 'chat-kit', kind: 'css', deps: ['small-deltas'], refs: ['message', 'bubble', 'marker', 'attachment'], docs: ['trace'],
    spec: 'Message family; Bubble family (all variants, alignment, grouping, reactions, collapsible content); Marker family; Attachment family incl. helper rendering a Phoenix.LiveView.UploadEntry (progress, errors, cancel); Trace blocks (reasoning, tool calls, sources) on top of collapsible.' },
  { id: 'message-scroller', kind: 'js', deps: ['chat-kit'], refs: ['message-scroller'],
    spec: 'Stick-to-bottom while streaming, prepend history without jump, jump-to-message, scroll-to-latest button; works with phx-update="stream" inserts at both ends.' },
  { id: 'code-block', kind: 'js', deps: ['small-deltas'], refs: [], docs: ['code-block'], spec: 'Header, line numbers, diff mode, terminal style, copy button. Server-side highlighting via Makeup (optional dep, plain fallback).' },
  { id: 'questionnaire', kind: 'js', deps: ['form-primitives'], refs: [], docs: ['questionnaire'], spec: 'Multi-step single/multiple/freeform/skippable questions; server-driven step state works without JS.' },

  { id: 'direction-rtl', kind: 'js', deps: ['overlay-deltas', 'dropdown-menu-sub-radio', 'slider-range', 'calendar-date-picker', 'combobox', 'context-menu-menubar', 'navigation-menu', 'drawer', 'carousel', 'resizable'], refs: ['direction'],
    spec: 'Honour dir="rtl" in every positioned/keyboard component (side/align flip, arrow-key direction, sidebar side, slider). Storybook RTL toggle + tests.' },
  { id: 'mix-salad-add', kind: 'css', deps: ['__ALL__'], refs: [],
    spec: '`mix salad.add <component...>` (Igniter): copies selected components + their component/JS deps, mirroring salad.install (prefix, color scheme); dependency map; tests; extend .github/scripts/installer-e2e/run.sh with an `add` mode and add it to the CI matrix.' },
  { id: 'blocks', kind: 'css', deps: ['__ALL__'], refs: [],
    spec: 'Port shadcn blocks (apps/v4/registry/new-york-v4/blocks) as storybook examples + copyable HEEx: dashboard-01, sidebar-07, login-03, signup-03, one chat block.' },
]
if (CFG.includeStyles) ITEMS.push({ id: 'style-presets', kind: 'css', deps: ['__ALL__'], refs: [], spec: 'Style preset mechanism + all 8 shadcn styles (apps/v4/registry/styles).' })

const LATE = ['mix-salad-add', 'blocks', 'style-presets']
const COMPONENT_IDS = ITEMS.filter(i => !LATE.includes(i.id)).map(i => i.id)
for (const it of ITEMS) it.deps = it.deps.flatMap(d => d === '__ALL__' ? COMPONENT_IDS : [d]).filter(d => d !== it.id)

// ---------------------------------------------------------------- shared prompt text
const SHADCN = `shadcn source pinned at ${CFG.shadcnRef}:
  gh api "repos/shadcn-ui/ui/contents/apps/v4/registry/new-york-v4/ui/<name>.tsx?ref=${CFG.shadcnRef}" --jq .content | base64 -d
  gh api "repos/shadcn-ui/ui/contents/apps/v4/content/docs/components/radix/<name>.mdx?ref=${CFG.shadcnRef}" --jq .content | base64 -d
  examples: files starting with <name>- in repos/shadcn-ui/ui/contents/apps/v4/registry/new-york-v4/examples?ref=${CFG.shadcnRef}
Copy shadcn's Tailwind classes and data-slot names nearly verbatim (Tailwind v4 + oklch tokens are in place).`

const SETUP = `Speed-ups for a fresh worktree: toolchain comes from .tool-versions (asdf). Hex cache is global, so \`mix deps.get\` is quick. Instead of npm ci, symlink node_modules when package-lock.json is unchanged: \`ln -s ${CFG.repo}/assets/node_modules assets/node_modules\` and \`ln -s ${CFG.repo}/storybook/assets/node_modules storybook/assets/node_modules\`.`

const CONVENTIONS = `Follow CLAUDE.md and mirror the closest existing SaladUI component. Per component: lib/salad_ui/<name>.ex (moduledoc + attr docs, working examples); assets/salad_ui/components/<name>.js if interactive (extends Component, self-registers, ARIA config, keyboard); test/salad_ui/<name>_test.exs; assets/test/<name>.test.mjs if JS (use waitFor() from test/helpers/dom.mjs for rAF/timer-driven state, never fixed waits); storybook/storybook/salad_ui_component/<name>.story.exs covering the shadcn docs examples. Register new modules yourself: \`import\` list in lib/salad_ui.ex __using__ (+ moduledoc list), @js_import lists in lib/mix/tasks/salad.setup.ex and salad.install.ex, storybook/assets/js/storybook.js. Do NOT edit CHANGELOG.md or docs/shadcn-parity.md (written at the end). Per the user's global rule: no AI/tool attribution in commits.`

const GATES = `Gates before pushing. Always: \`mix compile --warnings-as-errors && mix format --check-formatted && mix credo && mix test\`, then \`cd storybook && mix deps.get && mix test\` (StorybookSmokeTest mounts every story). If assets/ changed: \`cd assets && npm run lint && npm run format:check && npm test\`. If lib/mix/** or CSS tokens/theme changed: \`.github/scripts/installer-e2e/run.sh setup\` (needs \`mix archive.install hex phx_new --force\` once). Full CI also runs on draft PR #1 after each push, as a backstop.`

const PUSH = (id, subject) => `Land it on ${CFG.branch} (optimistic, no lock; other agents push concurrently):
  1. git fetch origin && git rebase origin/${CFG.branch} (resolve conflicts, keeping both sides; registration lists usually conflict trivially)
  2. squash to one commit: git reset --soft origin/${CFG.branch} && git commit -m "${subject}" (body: what changed; no attribution)
  3. if step 1 pulled in new commits, re-run the "Always" gates
  4. git push origin HEAD:${CFG.branch}; if rejected as non-fast-forward, repeat from 1 (up to 5 times)
  Also keep a local branch: git branch -f parity/${id} HEAD.`

const IMPL_SCHEMA = { type: 'object', required: ['status', 'summary'], properties: {
  status: { type: 'string', enum: ['pushed', 'failed'] },
  commit: { type: 'string' },
  summary: { type: 'string', description: 'what landed, 2-4 sentences' },
  notCovered: { type: 'array', items: { type: 'string' }, description: 'shadcn docs examples or spec points not implemented, if any' },
  failure: { type: 'string' } } }

const REVIEW_SCHEMA = { type: 'object', required: ['fixed', 'remaining'], properties: {
  fixed: { type: 'array', items: { type: 'string' } },
  remaining: { type: 'array', items: { type: 'string' }, description: 'issues found but not fixed, with why' },
  commit: { type: 'string' } } }

const CRITIC_SCHEMA = { type: 'object', required: ['gaps'], properties: { gaps: { type: 'array', items: {
  type: 'object', required: ['id', 'kind', 'spec', 'refs'], properties: {
    id: { type: 'string', description: 'kebab-case, new and unique' },
    kind: { type: 'string', enum: ['css', 'js'] },
    spec: { type: 'string' }, refs: { type: 'array', items: { type: 'string' } } } } } } }

// ---------------------------------------------------------------- scheduler
const results = {}
const promises = {}
for (const id of CFG.done) results[id] = { status: 'pushed', note: 'already on integration branch' }

function depDone(d, runSet) {
  if (promises[d]) return promises[d]
  if (results[d]) return Promise.resolve(results[d])
  if (!runSet.has(d)) return Promise.resolve({ status: 'pushed', note: 'assumed (outside run subset)' })
  return Promise.resolve({ status: 'unknown' })
}

async function runItem(item, runSet) {
  await null // let every item register its promise before resolving deps
  const deps = await Promise.all(item.deps.map(d => depDone(d, runSet)))
  const bad = item.deps.filter((d, i) => deps[i].status !== 'pushed')
  if (bad.length) { log(`${item.id}: blocked by ${bad.join(', ')}`); return (results[item.id] = { status: 'blocked', blockedBy: bad }) }

  const refs = `shadcn ui files: [${item.refs.join(', ') || 'none'}]${item.docs ? `; docs-only pages: [${item.docs.join(', ')}]` : ''}.`
  const subject = `feat(parity/${item.id}): ${item.id.replace(/-/g, ' ')}`

  const impl = await agent(`SaladUI shadcn-parity item "${item.id}".
Task: ${item.spec}
${refs}
Start: you are in a fresh git worktree of ${CFG.repo}. git fetch origin. If local branch parity/${item.id} exists, a previous run did part of this: \`git checkout -B work parity/${item.id} && git merge --no-edit origin/${CFG.branch}\`, then review what's there against the task and finish it. Otherwise \`git checkout -B work origin/${CFG.branch}\`.
${SETUP}
${SHADCN}
${CONVENTIONS}
Before pushing, self-check: walk every example on the shadcn docs page(s) and confirm the API can express it; list any you skip in notCovered.
${GATES}
${PUSH(item.id, subject)}`,
    { phase: 'Implement', label: `impl:${item.id}`, isolation: 'worktree', schema: IMPL_SCHEMA })

  if (!impl || impl.status !== 'pushed') {
    log(`${item.id}: FAILED — ${impl ? impl.failure : 'agent died'}`)
    return (results[item.id] = { status: 'failed', failure: impl && impl.failure })
  }
  log(`${item.id}: pushed ${impl.commit || ''}${impl.notCovered && impl.notCovered.length ? ` (not covered: ${impl.notCovered.length})` : ''}`)
  results[item.id] = { status: 'pushed', commit: impl.commit, summary: impl.summary, notCovered: impl.notCovered || [] }

  // Reviewer-fixer for interactive items. Dependents don't wait for it.
  if (item.kind === 'js') {
    const review = agent(`Review-and-fix SaladUI parity item "${item.id}", already pushed to ${CFG.branch} as commit ${impl.commit || `(subject "${subject}")`}.
Task it implemented: ${item.spec}
${refs}
You are in a fresh worktree: git fetch origin && git checkout -B work origin/${CFG.branch}. ${SETUP}
Inspect: git show ${impl.commit || `$(git log origin/${CFG.branch} --grep '^feat(parity/${item.id})' --format=%H -1)`}.
${SHADCN}
Find and FIX directly (don't just report), limited to this item's code: WAI-ARIA pattern + keyboard behaviour; LiveView integration (FormField, on-* events, send_command, survives re-render/patch, phx-update="stream" where relevant); parity gaps vs shadcn docs examples; tests that only check rendering rather than behaviour. Ignore cosmetic nits and anything outside this item.
If you changed anything: ${GATES} then ${PUSH(item.id, `fix(parity/${item.id}): review fixes`)}
Return what you fixed and anything left unfixed.`,
      { phase: 'Review', label: `review:${item.id}`, isolation: 'worktree', schema: REVIEW_SCHEMA })
      .then(r => { if (r) { results[item.id].review = r; log(`${item.id}: review fixed ${r.fixed.length}, left ${r.remaining.length}`) } })
    reviews.push(review)
  }
  return results[item.id]
}

const reviews = []
async function runBatch(items) {
  const runSet = new Set(items.map(i => i.id))
  for (const it of items) promises[it.id] = runItem(it, runSet).catch(e => (results[it.id] = { status: 'failed', error: String(e) }))
  await Promise.all(items.map(it => promises[it.id]))
  await Promise.all(reviews)
}

// ---------------------------------------------------------------- main
const todo = ITEMS.filter(i => !results[i.id] && (!CFG.only || CFG.only.includes(i.id)))
if (CFG.only) log(`Pilot: ${todo.map(i => i.id).join(', ')} (${ITEMS.length - todo.length - CFG.done.length} items not in this run)`)
log(`Running ${todo.length} items; ${CFG.done.length} already done`)
phase('Implement')
await runBatch(todo)

// ---------------------------------------------------------------- critic (also writes status + changelog)
let round = 0
const finalRound = CFG.only ? 0 : CFG.criticRounds
while (true) {
  const last = round >= finalRound
  phase('Critique')
  const known = Object.keys(results)
  const critic = await agent(`${last ? 'FINAL REPORT' : `Completeness critic round ${round + 1}`} for SaladUI ↔ shadcn/ui parity.
Fresh worktree: git fetch origin && git checkout -B work origin/${CFG.branch}. ${SETUP}
${last ? '' : `${SHADCN}
Compare every shadcn ui file + docs page (registry/new-york-v4/ui, content/docs/components/radix) against SaladUI on this branch: missing components/sub-parts/variants/props, and docs examples that can't be expressed. React-only concepts (Portal, Provider, asChild internals) are not gaps. Known items (don't re-propose unless clearly broken; then use id "<old>-followup"): ${known.join(', ')}.
Return only REAL remaining gaps as small, precise work items (group related ones). Empty list = parity reached.`}
Then, in any case, update docs/shadcn-parity.md with a "Status" section (item -> status table from this JSON, plus notCovered/remaining review issues), and add an "Unreleased" CHANGELOG.md entry summarising what landed (from \`git log origin/main..HEAD --format=%s%n%b\`, user-visible changes and behaviour changes called out). Commit "docs: parity status + changelog" and push to ${CFG.branch} (rebase + retry on rejection). No attribution.
${JSON.stringify(results)}`,
    { phase: 'Critique', label: last ? 'report' : `critic#${round + 1}`, isolation: 'worktree', schema: CRITIC_SCHEMA })
  if (last) break
  const seen = new Set(Object.keys(results))
  const fresh = ((critic && critic.gaps) || []).filter(g => !seen.has(g.id)).map(g => ({ id: g.id, kind: g.kind, refs: g.refs, deps: [], spec: g.spec }))
  log(`Critic round ${round + 1}: ${fresh.length} new gaps${fresh.length ? ' — ' + fresh.map(f => f.id).join(', ') : ''}`)
  round++
  if (!fresh.length) { round = finalRound; continue } // go straight to the final report
  phase('Implement')
  await runBatch(fresh)
}

const byStatus = {}
for (const [id, r] of Object.entries(results)) (byStatus[r.status] = byStatus[r.status] || []).push(id)
return { byStatus, done: !CFG.only && Object.values(results).every(r => r.status === 'pushed'), results }
