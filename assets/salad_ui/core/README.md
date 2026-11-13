# SaladUI Core Module

The framework-level JavaScript underneath every interactive SaladUI component:
component base class, state machine, registry/factory, LiveView bridge, and a
handful of small DOM utilities used by individual components.

For narrative documentation see `docs/` at the repo root, in particular:

- **[Component Lifecycle](../../../docs/component_lifecycle.md)** — the
  authoritative reference for `Component`'s mount/transition/update/destroy
  lifecycle and the extension-hook contract subclasses must follow.
- **[Architecture Overview](../../../docs/js_architecture_overview.md)** —
  the system as a whole (registry → factory → component → LiveView).
- **[State Machine Flow](../../../docs/js_state_transition_flow.md)** —
  diagrammed transition execution, with and without animation.

## Files

| File | Exports | Responsibility |
|---|---|---|
| `component.js` | `Component` (default), `AriaManager` (internal) | Base class every interactive component extends: option/event-mapping parsing, state machine wiring, part querying, key/mouse event binding, ARIA attribute application, and the lifecycle hooks (`setupComponentEvents`/`teardownComponentEvents`/`afterMount`/`beforeDestroy`). See [Component Lifecycle](../../../docs/component_lifecycle.md). |
| `state-machine.js` | `StateMachine` (default) | Pure state/transition engine: looks up the next state for an event, runs exit → update → `onStateChanged` → enter in order, and supports the `onStateChanged` callback returning a promise (animation) before running the enter handler. Has no DOM dependency. |
| `factory.js` | `registry` (a `ComponentRegistry` instance) | Maps a `data-component` type string to a component class and instantiates it: `new ComponentClass(el, hookContext)` → `setupEvents()` → `afterMount()`, each called exactly once. This is the **only** place that should call `setupEvents()`/`afterMount()` on a registry-managed component. |
| `hook.js` | `SaladUIHook` | The Phoenix LiveView hook (`phx-hook="SaladUI"`) that bridges server and client: `mounted()` creates the component via the registry, `updated()` fully destroys and recreates it on every DOM patch, `destroyed()` tears it down. Also relays `saladui:command` server events into `component.handleCommand()`. |
| `collection.js` | `Collection` (default) | Manages a set of selectable/focusable items (single or multiple selection, disabled items) for components like `select`, `menu`, `accordion`, `radio-group`. |
| `focus-trap.js` | `FocusTrap` (default) | Confines Tab/Shift+Tab focus within an element (dialogs, sheets) and restores the previously focused element on `deactivate()`. With `contain: false` (non-modal dialogs) it only moves focus in and back out, without looping Tab. |
| `scroll-lock.js` | `lockScroll`, `isScrollLocked`, `scrollLockCount`, `resetScrollLock`, `scrollbarWidth` | Reference-counted page scroll lock for modal surfaces (taken through `modal-layer.js`, and directly by the sidebar's mobile sheet): the first `lockScroll()` sets `overflow: hidden` on `<html>`/`<body>` and pads `<body>` by the scrollbar width (none under `scrollbar-gutter: stable`); the page's inline styles are restored when the last lock is released. `lockScroll()` returns an idempotent release function; components hold at most one and release it on close and in `beforeDestroy()`. While locked, `<body>` carries `data-scroll-locked` and `--removed-body-scroll-bar-size`, which `salad_ui.css` uses for react-remove-scroll-bar's `right-scroll-bar-position` / `width-before-scroll-bar` classes. |
| `modal-layer.js` | `ModalLayer`, `sync`, `isModalBlocking`, `modalLayerCount`, `resetModalLayers` | Radix-style modal behaviour for dialog/sheet/alert dialog, drawer and a modal dropdown menu. While the topmost modal layer is open: `<body>` gets `pointer-events: none` and the layer `pointer-events: auto` (DismissableLayer's `disableOutsidePointerEvents`), everything outside it gets `aria-hidden` (the `aria-hidden` package's `hideOthers()`; `aria-live` regions kept, the page's own values restored), wheel/touch scrolling outside it is cancelled (react-remove-scroll), and the page scroll is locked. Layers stack in opening order; content portaled out of a layer with `Portal.move()` counts as part of it. A `MutationObserver` re-applies everything after LiveView patches. Components call `activate()` on open, `releaseInteraction()` when closing starts and `deactivate()` once closed (and in `beforeDestroy()`); `modal: false` layers block nothing. |
| `detached-triggers.js` | `listen`, `listenAttribute`, `readContext`, `ContextValues`, `DetachedAnchor`, `watchTrigger`, `setTriggerState`, `focusFallback` | Shared instances (one dropdown menu, context menu, tooltip or hover card for a whole list): triggers rendered outside the root carry `data-salad-for="<root id>"` and a JSON `data-salad-context`. `listen(id, type, handler)` (and `listenAttribute(name, ...)` for the text tooltips' `data-salad-tooltip`) keeps one `document` listener per event type for every instance; `ContextValues` writes the open trigger's context onto the items as `phx-value-*`; `watchTrigger()` reports the trigger leaving the page (the menu closes) or a patch reverting its open state. An opt-in SaladUI extension with no Radix equivalent. |
| `click-outside.js` | `ClickOutsideMonitor` (default) | Attaches `document`-level `click`/`touchend` listeners (only while `start()`-ed) and invokes a callback when a click lands outside a given set of elements. Must be `start()`/`stop()`-paired with the state that should be listening, and `destroy()`-ed in `teardownComponentEvents()` — see [Common Pitfalls](../../../docs/component_lifecycle.md#common-pitfalls) for what goes wrong if it isn't. |
| `portal.js` | `Portal` (default) | Moves an element to a different DOM parent (typically `document.body`) to escape `overflow`/`z-index` stacking contexts, and can restore it to its original position. `Portal.portaledElements()` / `Portal.originalParent()` let modal layers treat portaled content as part of the layer it came from. |
| `positioner.js` | `Positioner` (default) | Pure positioning math: computes fixed-position coordinates for a floating element relative to a reference element, given placement/alignment/flip options. No side effects. |
| `positioned-element.js` | `PositionedElement` (default) | Composes `Positioner` + `Portal` + `ScrollManager` + `FocusTrap` into the full floating-element behavior (popover, select content, tooltip, hover-card): activate/deactivate, reposition on scroll/resize, optional portal + focus trap. |
| `scroll-manager.js` | `ScrollManager` (default) | Watches scroll/resize on a target's scrollable ancestors (throttled via `requestAnimationFrame`) and the target's size (via `ResizeObserver`), invoking a callback to reposition it. |
| `utils.js` | `animateTransition`, `executeAnimation`, `addOrRemoveClasses`, `queryDOM` | Animation/transition class helpers driven by the `animations` config in `data-options`, plus `queryDOM` — the filtered DOM walk `Component.queryParts()` uses to find `data-part` elements. |

## How a component gets wired up

```
data-component="dialog" + phx-hook="SaladUI"
        │
        ▼
SaladUIHook.mounted() → registry.create("dialog", el, hookContext)
        │
        ▼
new DialogComponent(el, hookContext)   // extends Component
        │
        ▼
instance.setupEvents()   ← called once, by factory.js
        │
        ▼
instance.afterMount()    ← called once, by factory.js
        │
        ▼
component is live: transition(event, params) drives everything from here
```

Full detail, including the destroy/update paths and the extension-hook
contract (`setupComponentEvents`/`teardownComponentEvents`/`afterMount`/
`beforeDestroy`), is in
[docs/component_lifecycle.md](../../../docs/component_lifecycle.md).

## Adding a utility here vs. a component

Files in this directory should have **no dependency on a specific
component** — `FocusTrap`, `ClickOutsideMonitor`, `Positioner`, etc. are all
usable by any component that needs them. Component-specific behavior
(state machine config, ARIA config, DOM structure assumptions) belongs in
`assets/salad_ui/components/*.js`, not here.
