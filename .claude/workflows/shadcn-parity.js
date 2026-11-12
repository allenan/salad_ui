export const meta = {
  name: 'shadcn-parity',
  description: 'Close every SaladUI vs shadcn/ui gap: implement, adversarially review, integrate, then loop a completeness critic until no gaps remain',
  whenToUse: 'Bring SaladUI to feature parity with shadcn/ui. Pass args.only for a pilot run on a subset of item ids.',
  phases: [
    { title: 'Setup', detail: 'integration worktree, already-merged detection' },
    { title: 'Implement', detail: 'one worktree agent per gap item, dependency-ordered' },
    { title: 'Review', detail: 'parity lens + quality lens per item, fix loop' },
    { title: 'Integrate', detail: 'serial merge into parity/integration, full gates' },
    { title: 'Critique', detail: 'completeness critics re-diff vs shadcn; new gaps loop back' },
    { title: 'Report', detail: 'update docs/shadcn-parity.md status' },
  ],
}

// ---------------------------------------------------------------- config
const A = args || {}
const CFG = {
  repo: A.repo || '/Users/andrew/code/personal/salad/salad_ui',
  integrationPath: A.integrationPath || '/Users/andrew/code/personal/salad/salad_ui-parity',
  integrationBranch: A.integrationBranch || 'parity/integration',
  baseRef: A.baseRef || 'origin/main',
  shadcnRef: A.shadcnRef || 'dd41d19e2f80ff6891951f7ced74c2c9a650b065',
  push: A.push === true,
  maxFixRounds: A.maxFixRounds ?? 2,
  maxCriticRounds: A.maxCriticRounds ?? 3,
  only: A.only || null,
  includeStyles: A.includeStyles === true,
  decisions: Object.assign({
    field: 'Add `field` alongside `form`; mark `form` as legacy in docs (no removal).',
    calendar: 'Server-rendered month grid (LiveComponent-free function component + small JS hook for focus/keyboard and month navigation without a round trip when possible).',
    dataTable: 'Ship a documented recipe + `SaladUI.DataTable` helper functions (sort/filter/paginate params, column visibility) on top of table/dropdown/pagination/checkbox — not a monolithic component.',
    chart: 'Keep Chart.js; add a shadcn-style `chart_container` config (labels, colors -> --chart-N tokens), styled tooltip + legend matching shadcn.',
    dropFormsPlugin: 'Keep @tailwindcss/forms for now; neutralise its resets inside SaladUI components where they conflict.',
    styles: 'Out of scope unless includeStyles=true.',
  }, A.decisions || {}),
}

// ---------------------------------------------------------------- work items
// deps are item ids; an item starts only after all deps are integrated.
const ALL_INTERACTIVE = ['dropdown-menu-sub-radio', 'popover-parts', 'tabs-orientation-variant', 'slider-range', 'select-size-scroll',
  'calendar', 'date-picker', 'combobox', 'context-menu', 'menubar', 'navigation-menu', 'drawer', 'input-otp', 'carousel', 'resizable']

const ITEMS = [
  // Foundation (serialised by deps — both touch nearly every file)
  { id: 'tailwind-drift', refs: ['button', 'badge', 'checkbox', 'input', 'sidebar'], deps: [],
    spec: `Fix Tailwind v4 drift (docs/shadcn-parity.md §3b): (1) replace hsl(var(--sidebar-border)) with var(--sidebar-border) in lib/salad_ui/sidebar.ex and lib/salad_ui/helpers.ex — tokens are oklch; (2) align shadow scale with shadcn v4 (shadow-xs on buttons/inputs/checkbox, shadow-sm on card); (3) add shadcn's aria-invalid error styling (aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40) to input, textarea, select trigger, checkbox, radio, switch and set aria-invalid automatically when a FormField has errors; (4) destructive button/badge use text-white like shadcn but keep --destructive-foreground token defined for back-compat; (5) h-N w-N -> size-N where equal; (6) bump tailwind pin to 4.3.5 in config/config.exs and storybook/config/config.exs. @tailwindcss/forms decision: ${'${DECISION:dropFormsPlugin}'}.` },
  { id: 'data-slot', refs: ['*'], deps: ['tailwind-drift'],
    spec: 'Add data-slot attributes to every rendered part of every existing component, using exactly shadcn\'s slot names (e.g. data-slot="card-header", "dropdown-menu-item"). Fetch each matching shadcn file to copy names. Update/extend tests to assert slots on a representative part per component.' },

  // Existing-component deltas (§2)
  { id: 'small-deltas', refs: ['button', 'badge', 'card', 'dialog', 'alert-dialog', 'command', 'switch'], deps: ['data-slot'],
    spec: 'Button sizes xs, icon-xs, icon-sm, icon-lg; badge variants ghost + link (and link/as rendering); card_action; dialog_close; alert_dialog_media; command_separator; switch size="sm". Match shadcn classes.' },
  { id: 'avatar', refs: ['avatar'], deps: ['data-slot'], spec: 'Avatar size (sm/default/lg), avatar_group, avatar_group_count, avatar_badge.' },
  { id: 'popover-parts', refs: ['popover'], deps: ['data-slot'], spec: 'popover_header, popover_title, popover_description, popover_anchor (positioning relative to anchor element instead of trigger).' },
  { id: 'dropdown-menu-sub-radio', refs: ['dropdown-menu'], deps: ['data-slot'],
    spec: 'Dropdown sub-menus (dropdown_menu_sub, _sub_trigger, _sub_content) with hover/ArrowRight open, ArrowLeft close, nested focus management; dropdown_menu_radio_group + _radio_item with on-value-changed. Full keyboard + ARIA per WAI-ARIA menu pattern. JS tests required.' },
  { id: 'tabs-orientation-variant', refs: ['tabs'], deps: ['data-slot'], spec: 'Tabs orientation="vertical" (ArrowUp/Down keys, aria-orientation) and tabs_list variant="line".' },
  { id: 'slider-range', refs: ['slider'], deps: ['data-slot'], spec: 'Slider with multiple thumbs/range (value as list), vertical orientation, float step, form submission of each value, keyboard per thumb. Keep single-value API backward compatible.' },
  { id: 'select-size-scroll', refs: ['select'], deps: ['data-slot'], spec: 'select_trigger size="sm"; select_scroll_up_button / select_scroll_down_button for long lists.' },
  { id: 'scroll-area-scrollbar', refs: ['scroll-area'], deps: ['data-slot'], spec: 'scroll_bar part with horizontal + vertical orientation; verify horizontal scrolling works.' },
  { id: 'chart-theming', refs: ['chart'], deps: ['data-slot'], spec: 'Chart parity. Decision: ${DECISION:chart}. Cover shadcn chart docs examples (area, bar, line, pie, radar, radial) at least one each in storybook.' },

  // Tier 1 primitives
  { id: 'field', refs: ['field'], deps: ['data-slot'], spec: 'Field family: field_set, field_legend, field_group, field, field_content, field_label, field_title, field_description, field_separator, field_error. Accept Phoenix.HTML.FormField; field_error renders translated errors. orientation vertical/horizontal/responsive. Decision: ${DECISION:field}.' },
  { id: 'input-group', refs: ['input-group'], deps: ['small-deltas'], spec: 'input_group, input_group_addon (align inline-start/inline-end/block-start/block-end), input_group_button, input_group_text, input_group_input, input_group_textarea. Clicking addon focuses control.' },
  { id: 'button-group', refs: ['button-group'], deps: ['small-deltas'], spec: 'button_group (orientation), button_group_separator, button_group_text.' },
  { id: 'item', refs: ['item'], deps: ['data-slot'], spec: 'Item family incl. variants/sizes: item_group, item_separator, item, item_media, item_content, item_title, item_description, item_actions, item_header, item_footer; as-link rendering.' },
  { id: 'tiny-primitives', refs: ['empty', 'kbd', 'spinner', 'aspect-ratio'], deps: ['data-slot'], spec: 'empty (+header/media/title/description/content), kbd + kbd_group, spinner, aspect_ratio.' },
  { id: 'native-select', refs: ['native-select'], deps: ['data-slot'], spec: 'native_select with options/optgroups, size, FormField support, aria-invalid.' },
  { id: 'typography', refs: [], docs: ['typography'], deps: ['data-slot'], spec: 'Typography components matching shadcn docs page (h1-h4, p, blockquote, list, inline_code, lead, large, small, muted, table).' },

  // Tier 2 interactive
  { id: 'calendar', refs: ['calendar'], deps: ['small-deltas'], spec: 'Calendar: single/multiple/range modes, min/max, disabled dates, week start, multiple months, caption dropdowns, keyboard grid nav, FormField integration. Decision: ${DECISION:calendar}.' },
  { id: 'date-picker', refs: [], docs: ['date-picker'], deps: ['calendar', 'popover-parts'], spec: 'Date picker (popover + calendar + trigger/input) incl. range and presets, as in shadcn docs examples. Submits ISO dates via hidden inputs.' },
  { id: 'combobox', refs: ['combobox'], deps: ['popover-parts', 'input-group'], spec: 'Combobox: single + multiple (chips), client filtering, server-side filtering via phx-change/debounce, empty state, groups, FormField integration. Full combobox ARIA pattern.' },
  { id: 'context-menu', refs: ['context-menu'], deps: ['dropdown-menu-sub-radio'], spec: 'Context menu with all dropdown item types (checkbox, radio, sub, shortcut, separator, label), opened at pointer, long-press on touch.' },
  { id: 'menubar', refs: ['menubar'], deps: ['dropdown-menu-sub-radio'], spec: 'Menubar with roving focus between menus, hover-switching once open, all item types incl. subs.' },
  { id: 'navigation-menu', refs: ['navigation-menu'], deps: ['data-slot'], spec: 'Navigation menu: list/item/trigger/content/link/indicator/viewport, hover + keyboard, animated viewport sizing.' },
  { id: 'drawer', refs: ['drawer'], deps: ['data-slot'], spec: 'Drawer (vaul-style): directions, drag-to-dismiss, snap points, background scale optional, handle; drawer_trigger/content/header/footer/title/description/close.' },
  { id: 'input-otp', refs: ['input-otp'], deps: ['data-slot'], spec: 'input_otp, _group, _slot, _separator; paste, pattern (digits/alnum), caret, single hidden real input for form submission, autocomplete="one-time-code".' },
  { id: 'carousel', refs: ['carousel'], deps: ['small-deltas'], spec: 'Carousel: content/item/previous/next, horizontal/vertical, loop, keyboard, slides-per-view via basis classes, API events (on-select). Prefer CSS scroll-snap + small JS, no new npm dependency unless justified.' },
  { id: 'resizable', refs: ['resizable'], deps: ['data-slot'], spec: 'resizable_panel_group/panel/handle (with_handle), horizontal/vertical, min/max/default sizes, keyboard resize, optional persistence (localStorage key), nested groups.' },
  { id: 'data-table', refs: [], docs: ['data-table'], deps: ['dropdown-menu-sub-radio', 'small-deltas'], spec: 'Data table. Decision: ${DECISION:dataTable}. Reproduce the shadcn docs example (sorting, filtering, pagination, column visibility, row selection) as a storybook LiveView example using streams.' },

  // Tier 3 chat kit
  { id: 'chat-markup', refs: ['message', 'bubble', 'marker'], deps: ['avatar'], spec: 'Message family, Bubble family (all variants, alignment, grouping, reactions, collapsible content), Marker family.' },
  { id: 'attachment', refs: ['attachment'], deps: ['small-deltas'], spec: 'Attachment family incl. upload state; helper to render from a Phoenix.LiveView.UploadEntry (progress, errors, cancel action).' },
  { id: 'message-scroller', refs: ['message-scroller'], deps: ['chat-markup'], spec: 'Message scroller: stick-to-bottom while streaming, prepend history without jump, jump-to-message, scroll-to-latest button. Must work with phx-update="stream" inserts at both ends.' },
  { id: 'trace', refs: [], docs: ['trace'], deps: ['chat-markup'], spec: 'Trace building blocks (reasoning, tool calls, sources) per shadcn docs, on top of collapsible.' },
  { id: 'code-block', refs: [], docs: ['code-block'], deps: ['small-deltas'], spec: 'Code block: header, line numbers, diff mode, terminal style, copy button. Server-side highlighting via Makeup (optional dep, degrade to plain) instead of Shiki.' },
  { id: 'questionnaire', refs: [], docs: ['questionnaire'], deps: ['field', 'small-deltas'], spec: 'Questionnaire: multi-step single/multiple/freeform/skippable questions; server-driven step state works without JS.' },

  // Platform
  { id: 'direction-rtl', refs: ['direction'], deps: ALL_INTERACTIVE, spec: 'RTL support: honour dir="rtl" on html/ancestor in every positioned/keyboard component (side/align flipping, arrow-key direction, sidebar side, slider). Add a storybook RTL toggle and tests.' },
  { id: 'mix-salad-add', refs: [], deps: ['__ALL_COMPONENTS__'], spec: 'Add `mix salad.add <component...>` (Igniter) that copies selected components + their component/JS dependencies, mirroring salad.install conventions (prefix, color scheme). Include a dependency map and tests.' },
  { id: 'blocks', refs: [], deps: ['__ALL_COMPONENTS__'], spec: 'Port shadcn blocks as storybook examples + copyable HEEx templates: dashboard-01, sidebar-07, login-03, signup-03, and one chat/AI block. Fetch from apps/v4/registry/new-york-v4/blocks.' },
]
if (CFG.includeStyles) ITEMS.push({ id: 'style-presets', refs: [], deps: ['__ALL_COMPONENTS__'],
  spec: 'shadcn visual styles (vega, nova, maia, lyra, mira, luma, rhea, sera; apps/v4/registry/styles/*.css). Design + implement a style preset mechanism for both library and installed modes, then port all 8.' })

const COMPONENT_IDS = ITEMS.filter(i => !['direction-rtl', 'mix-salad-add', 'blocks', 'style-presets'].includes(i.id)).map(i => i.id)
for (const it of ITEMS) it.deps = it.deps.flatMap(d => d === '__ALL_COMPONENTS__' ? COMPONENT_IDS.concat(['direction-rtl']) : [d])
  .filter(d => d !== it.id)

const fill = s => s.replace(/\$\{DECISION:(\w+)\}/g, (_, k) => CFG.decisions[k])

// ---------------------------------------------------------------- shared prompt text
const ENV = `Toolchain: run \`export ASDF_ELIXIR_VERSION=1.20.0-otp-28 ASDF_ERLANG_VERSION=28.3.3\` in every shell. In a fresh checkout run \`mix deps.get\` and \`(cd assets && npm ci)\` first.`
const GATES = `Gates (all must pass): \`mix compile --warnings-as-errors\`, \`mix format --check-formatted\`, \`mix test\`, \`mix credo\` (no new issues), \`cd assets && npm test && npm run lint && npm run format:check\`. Baseline before this project: 203 Elixir + 242 JS tests green.`
const SHADCN = `shadcn source is pinned at ${CFG.shadcnRef}. Fetch with gh, e.g.
  gh api "repos/shadcn-ui/ui/contents/apps/v4/registry/new-york-v4/ui/<name>.tsx?ref=${CFG.shadcnRef}" --jq .content | base64 -d
  gh api "repos/shadcn-ui/ui/contents/apps/v4/content/docs/components/radix/<name>.mdx?ref=${CFG.shadcnRef}" --jq .content | base64 -d
  examples: list "repos/shadcn-ui/ui/contents/apps/v4/registry/new-york-v4/examples?ref=${CFG.shadcnRef}" and read files starting with <name>-.
Copy shadcn's Tailwind classes nearly verbatim (Tailwind v4, oklch tokens already in place) and use its data-slot names.`
const SHARED_FILES = `Do NOT edit these shared registration files — the integrator applies them from your manifest: lib/salad_ui.ex, lib/mix/tasks/salad.install.ex, lib/mix/tasks/salad.setup.ex, storybook/assets/js/storybook.js, README.md, CHANGELOG.md, docs/shadcn-parity.md.`
const CONVENTIONS = `Follow repo conventions (CLAUDE.md; docs/implement_simple_component.md, docs/complex_component_guide.md, docs/js_component_patterns.md). Mirror the closest existing SaladUI component's structure. Deliverables per component: lib/salad_ui/<name>.ex with @moduledoc + attr docs; assets/salad_ui/components/<name>.js if interactive (extends Component, registers itself, ARIA config, keyboard nav); test/salad_ui/<name>_test.exs; assets/test/<name>.test.mjs if JS; storybook/storybook/salad_ui_component/<name>.story.exs covering every shadcn docs example for this component. LiveView-native where it helps (FormField support, on-* event attrs, SaladUI.LiveView.send_command commands).
Commits: conventional style, e.g. "feat(<id>): ...". Per the user's global rule, NO AI/tool attribution anywhere — no Co-Authored-By, no "Generated with" lines.`

const IMPL_SCHEMA = { type: 'object', required: ['branch', 'commit', 'gatesPassed', 'manifest', 'summary'], properties: {
  branch: { type: 'string' }, commit: { type: 'string' }, gatesPassed: { type: 'boolean' },
  gateOutput: { type: 'string', description: 'tail of any failing gate output' },
  manifest: { type: 'object', required: ['elixirModules', 'jsFiles'], properties: {
    elixirModules: { type: 'array', items: { type: 'string' }, description: 'new modules to add to `use SaladUI` imports, e.g. SaladUI.Field' },
    jsFiles: { type: 'array', items: { type: 'string' }, description: 'new assets/salad_ui/components/*.js to add to install task + storybook imports' },
    readmeLines: { type: 'array', items: { type: 'string' } },
    changelog: { type: 'string' },
    other: { type: 'string', description: 'any other shared-file change needed' } } },
  summary: { type: 'string' } } }

const REVIEW_SCHEMA = { type: 'object', required: ['verdict', 'gaps'], properties: {
  verdict: { type: 'string', enum: ['pass', 'fail'] },
  gaps: { type: 'array', items: { type: 'object', required: ['severity', 'description'], properties: {
    severity: { type: 'string', enum: ['must', 'should'] }, description: { type: 'string' }, evidence: { type: 'string' } } } } } }

const INTEGRATE_SCHEMA = { type: 'object', required: ['merged', 'gatesPassed'], properties: {
  merged: { type: 'boolean' }, commit: { type: 'string' }, gatesPassed: { type: 'boolean' }, failure: { type: 'string' } } }

const CRITIC_SCHEMA = { type: 'object', required: ['gaps'], properties: { gaps: { type: 'array', items: {
  type: 'object', required: ['id', 'spec', 'refs', 'deps'], properties: {
    id: { type: 'string', description: 'kebab-case, unique, not reusing an existing item id' },
    spec: { type: 'string' }, refs: { type: 'array', items: { type: 'string' } },
    deps: { type: 'array', items: { type: 'string' } } } } } } }

// ---------------------------------------------------------------- setup
phase('Setup')
const setup = await agent(`Prepare the integration worktree for the SaladUI shadcn-parity project.
Repo: ${CFG.repo} (origin = allenan/salad_ui fork, upstream = bluzky/salad_ui).
1. cd ${CFG.repo}; git fetch origin.
2. If ${CFG.integrationPath} is not already a worktree, run: git worktree add ${CFG.integrationPath} -B ${CFG.integrationBranch} ${CFG.baseRef} — unless branch ${CFG.integrationBranch} already exists, in which case add the worktree on the existing branch without resetting it.
3. If docs/shadcn-parity.md or .claude/workflows/shadcn-parity.js exist uncommitted in ${CFG.repo} but not in the integration branch, copy them in and commit "docs: add shadcn parity catalog and workflow" (no AI attribution).
4. In the worktree: ${ENV} Then run the gates once to confirm a green baseline. ${GATES}
5. List branches matching parity/* (excluding ${CFG.integrationBranch}) already merged into ${CFG.integrationBranch}: git branch --merged ${CFG.integrationBranch} --list 'parity/*'.
${CFG.push ? `6. git push -u origin ${CFG.integrationBranch}; if no open PR exists from it, open a draft PR into main on allenan/salad_ui titled "shadcn/ui parity" (body: link docs/shadcn-parity.md; no AI attribution).` : '6. Do not push.'}
Return JSON fields: baselineGreen (bool), mergedItemIds (ids = branch names without the "parity/" prefix), notes.`,
  { phase: 'Setup', label: 'setup', schema: { type: 'object', required: ['baselineGreen', 'mergedItemIds'], properties: {
    baselineGreen: { type: 'boolean' }, mergedItemIds: { type: 'array', items: { type: 'string' } }, notes: { type: 'string' } } } })

if (!setup || !setup.baselineGreen) {
  log('Baseline is not green in the integration worktree — stopping before any implementation.')
  return { stopped: 'baseline-not-green', setup }
}

// ---------------------------------------------------------------- scheduler
const results = {}            // id -> {status, ...}
const promises = {}
for (const id of setup.mergedItemIds) results[id] = { status: 'integrated', note: 'merged in a previous run' }

let lock = Promise.resolve()
const serial = fn => { const p = lock.then(fn, fn); lock = p.catch(() => {}); return p }

function depDone(d, runSet) {
  if (promises[d]) return promises[d]
  if (results[d]) return Promise.resolve(results[d])
  if (CFG.only && !runSet.has(d)) return Promise.resolve({ status: 'integrated', note: 'assumed (outside --only subset)' })
  return Promise.resolve({ status: 'unknown' })
}

async function runItem(item, runSet) {
  await null // let runBatch register every item's promise before deps are resolved
  const deps = await Promise.all(item.deps.map(d => depDone(d, runSet)))
  const bad = item.deps.filter((d, i) => deps[i].status !== 'integrated')
  if (bad.length) { log(`${item.id}: blocked by ${bad.join(', ')}`); return (results[item.id] = { status: 'blocked', blockedBy: bad }) }

  const branch = `parity/${item.id}`
  const spec = fill(item.spec)
  const refs = `shadcn refs: ui files [${item.refs.join(', ') || 'none'}]${item.docs ? `; docs pages [${item.docs.join(', ')}]` : ''}.`

  // implement
  let impl = await agent(`Implement SaladUI parity item "${item.id}".
Task: ${spec}
${refs}
Setup: you are in a fresh git worktree of ${CFG.repo}. Run: git checkout -B ${branch} ${CFG.integrationBranch}
${ENV}
${SHADCN}
${CONVENTIONS}
${SHARED_FILES}
${GATES}
When gates pass, commit on ${branch}, then run \`git switch --detach\` so the branch is free for other worktrees. Return the manifest of shared-file changes the integrator must apply.`,
    { phase: 'Implement', label: `impl:${item.id}`, isolation: 'worktree', schema: IMPL_SCHEMA })
  if (!impl) return (results[item.id] = { status: 'failed', stage: 'implement' })

  // review + fix loop
  let review = null
  for (let round = 0; round <= CFG.maxFixRounds; round++) {
    const [parity, quality] = await parallel([
      () => agent(`Adversarial PARITY review of branch ${branch} (item "${item.id}": ${spec}) against shadcn/ui.
${refs}
${SHADCN}
Read the diff read-only from ${CFG.repo}: git diff ${CFG.integrationBranch}...${branch} (and git show ${branch}:<path>).
Your job is to find what is missing or different, not to approve. Check: every sub-part/exported function, every variant/size/orientation, props/attrs, data-slot names, class strings, and that EVERY example in the shadcn docs page can be expressed with this API (list any that cannot). Mark "must" for missing functionality, "should" for cosmetic drift. verdict=fail if any "must".`,
        { phase: 'Review', label: `parity:${item.id}#${round}`, schema: REVIEW_SCHEMA }),
      () => agent(`Adversarial QUALITY review of branch ${branch} (item "${item.id}": ${spec}).
You are in a fresh worktree: git checkout --detach ${branch}. ${ENV}
Re-run the gates yourself; do not trust the implementer. ${GATES}
Then check: WAI-ARIA pattern + keyboard behaviour for this widget; LiveView integration (FormField support where relevant, on-* events, send_command, survives LiveView re-render/patch without losing JS state, works inside phx-update="stream" where relevant); tests actually exercise behaviour (not just render); no edits to shared files: ${SHARED_FILES}; no AI attribution in commit messages (git log ${CFG.integrationBranch}..${branch}).
Mark "must" for failing gates, broken a11y/keyboard, LiveView breakage, or shared-file edits. verdict=fail if any "must".`,
        { phase: 'Review', label: `quality:${item.id}#${round}`, isolation: 'worktree', schema: REVIEW_SCHEMA }),
    ])
    const gaps = [parity, quality].filter(Boolean).flatMap(r => r.gaps)
    const must = gaps.filter(g => g.severity === 'must')
    review = { gaps, must: must.length }
    if (parity && quality && !must.length) break
    if (round === CFG.maxFixRounds) break
    log(`${item.id}: round ${round + 1} — ${must.length} must-fix gaps`)
    const fixed = await agent(`Fix review findings on branch ${branch} (item "${item.id}": ${spec}).
You are in a fresh worktree: git checkout ${branch}. ${ENV}
Findings (fix every "must"; fix "should" when cheap):
${JSON.stringify(gaps, null, 1)}
${refs}
${SHADCN}
${CONVENTIONS}
${SHARED_FILES}
${GATES}
Commit on ${branch}, then \`git switch --detach\`. Return the full, updated manifest.`,
      { phase: 'Review', label: `fix:${item.id}#${round + 1}`, isolation: 'worktree', schema: IMPL_SCHEMA })
    if (fixed) impl = fixed
  }
  if (review.must) { log(`${item.id}: still ${review.must} must-fix gaps after ${CFG.maxFixRounds} fix rounds — needs human`); return (results[item.id] = { status: 'needs-human', review, branch }) }

  // integrate (serialised)
  const integ = await serial(() => agent(`Integrate branch ${branch} into ${CFG.integrationBranch}.
Work in ${CFG.integrationPath} (already on ${CFG.integrationBranch}). ${ENV}
1. Record HEAD as PRE. git merge --no-ff ${branch} -m "merge(${item.id}): ${item.id.replace(/-/g, ' ')}". Resolve conflicts preserving both sides' intent.
2. Apply this manifest to the shared files: ${JSON.stringify(impl.manifest)}
   - lib/salad_ui.ex: add imports to \`use SaladUI\` (alphabetical) and list components in the moduledoc category section.
   - lib/mix/tasks/salad.install.ex JS import list and storybook/assets/js/storybook.js: add each new JS file.
   - README component list / CHANGELOG "Unreleased" when given.
   - docs/shadcn-parity.md: mark item "${item.id}" done (✅) where it appears.
3. ${GATES}
4. If gates fail and the fix is small and clearly integration-related, fix it. Otherwise git reset --hard PRE and report merged=false with the failure.
5. Commit (no AI attribution). ${CFG.push ? `git push origin ${CFG.integrationBranch}.` : 'Do not push.'}`,
    { phase: 'Integrate', label: `integrate:${item.id}`, schema: INTEGRATE_SCHEMA }))
  if (!integ || !integ.merged || !integ.gatesPassed) {
    log(`${item.id}: integration failed — ${integ ? integ.failure : 'agent died'}`)
    return (results[item.id] = { status: 'integration-failed', failure: integ && integ.failure, branch })
  }
  log(`${item.id}: integrated (${integ.commit})`)
  return (results[item.id] = { status: 'integrated', commit: integ.commit, should: review.gaps.filter(g => g.severity === 'should') })
}

async function runBatch(items) {
  const runSet = new Set(items.map(i => i.id))
  for (const it of items) promises[it.id] = runItem(it, runSet).catch(e => (results[it.id] = { status: 'failed', error: String(e) }))
  return Promise.all(items.map(it => promises[it.id]))
}

// ---------------------------------------------------------------- main loop
let todo = ITEMS.filter(i => !results[i.id] && (!CFG.only || CFG.only.includes(i.id)))
const dropped = CFG.only ? ITEMS.filter(i => !CFG.only.includes(i.id)).map(i => i.id) : []
if (dropped.length) log(`Pilot run: ${todo.length} items; skipping ${dropped.length} (${dropped.join(', ')})`)
log(`Scheduling ${todo.length} items (${Object.keys(results).length} already integrated)`)

phase('Implement')
await runBatch(todo)

let criticRounds = 0
if (!CFG.only) {
  while (criticRounds < CFG.maxCriticRounds) {
    criticRounds++
    phase('Critique')
    const known = Object.keys(results)
    const lenses = [
      'INVENTORY/API lens: for every shadcn ui file and docs page (registry/new-york-v4/ui + content/docs/components/radix), compare sub-parts, variants, sizes, props and data-slots against SaladUI in the integration worktree.',
      'BEHAVIOUR/EXAMPLES lens: for every shadcn docs page, walk each example and check SaladUI can reproduce it (structure, interaction, keyboard, a11y). Also re-check docs/shadcn-parity.md §2 and §3b items.',
    ]
    const found = (await parallel(lenses.map((lens, i) => () => agent(`Completeness critic for SaladUI ↔ shadcn/ui parity.
${lens}
SaladUI code: ${CFG.integrationPath} (branch ${CFG.integrationBranch}). ${SHADCN}
Already handled item ids (do not re-propose unless clearly still broken, in which case use id "<old-id>-followup-${criticRounds}"): ${known.join(', ')}.
Items marked needs-human/failed are known; skip them: ${known.filter(k => results[k].status !== 'integrated').join(', ') || 'none'}.
Return only REAL remaining gaps as work items (spec precise enough for an implementer). React-only concepts (Portal, Provider, asChild internals) are not gaps. Empty list if parity is reached.`,
      { phase: 'Critique', label: `critic:${i ? 'behaviour' : 'inventory'}#${criticRounds}`, schema: CRITIC_SCHEMA })))).filter(Boolean)
    const seen = new Set(known)
    const fresh = []
    for (const g of found.flatMap(r => r.gaps)) if (!seen.has(g.id)) { seen.add(g.id); fresh.push({ id: g.id, refs: g.refs, deps: g.deps.filter(d => results[d] || seen.has(d)), spec: g.spec }) }
    log(`Critic round ${criticRounds}: ${fresh.length} new gaps${fresh.length ? ' — ' + fresh.map(f => f.id).join(', ') : ''}`)
    if (!fresh.length) break
    phase('Implement')
    await runBatch(fresh)
  }
}

// ---------------------------------------------------------------- report
phase('Report')
const byStatus = {}
for (const [id, r] of Object.entries(results)) (byStatus[r.status] = byStatus[r.status] || []).push(id)
await agent(`Update ${CFG.integrationPath}/docs/shadcn-parity.md with a "Status" section at the top: a table of item id → status from this JSON, plus the open "should" findings per integrated item, and note the shadcn ref ${CFG.shadcnRef}.
${JSON.stringify(results)}
Commit "docs: update shadcn parity status" (no AI attribution). ${CFG.push ? `Push ${CFG.integrationBranch} to origin.` : 'Do not push.'}`,
  { phase: 'Report', label: 'report' })

return { byStatus, criticRounds, done: !CFG.only && Object.values(results).every(r => r.status === 'integrated'), results }
