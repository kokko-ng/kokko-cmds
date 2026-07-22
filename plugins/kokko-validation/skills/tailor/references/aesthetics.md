<!--
TAILORING NOTES (for the /tailor skill -- delete this entire comment in the tailored output)

Placeholders. Every {{...}} must be resolved. Sources, in order: user hints,
repo inspection, then ask the user. Never invent values.

  APP_NAME                    Application name
  PROGRESS_FILE               Defect ledger path, e.g. prompts/aesthetics-progress.md
  BROWSER_TOOL                Browser automation tool actually available (e.g. playwright-cli, Playwright MCP)
  FRONTEND_FRAMEWORK / FRONTEND_START_COMMAND / FRONTEND_URL
  BACKEND_FRAMEWORK / BACKEND_START_COMMAND / BACKEND_URL
  THEMES                      Theme list, e.g. "dark, light" (single-theme apps: delete the theming block)
  TYPE_CHECK_COMMAND          Command(s) that must pass with zero errors
  DESKTOP_STATES              Real page/state list to screenshot at 1280px (enumerate from the router)
  MOBILE_STATES               Real page/state list to screenshot at 375px

Optional blocks. Delete the whole block -- plus every line elsewhere that
starts with the block name in brackets, e.g. "[theming]" -- when it does not
apply. Strip the bracket tags from lines you keep.

  theming       App has more than one theme.
  registration  App has self-service user registration.

No {{...}} token, no [tag] marker, and none of these notes may remain in the
tailored output.
-->

# {{APP_NAME}} -- Aesthetics & UI Fix Prompt

## Core Definitions

| ID         | Value                                        |
| ---------- | -------------------------------------------- |
| `frontend` | {{FRONTEND_FRAMEWORK}} on `{{FRONTEND_URL}}` |
| `backend`  | {{BACKEND_FRAMEWORK}} on `{{BACKEND_URL}}`   |
| `tool`     | {{BROWSER_TOOL}}                             |
| `ledger`   | `{{PROGRESS_FILE}}`                          |
| [theming] `themes` | {{THEMES}}                           |

---

## Primary Goal

Work autonomously to identify and fix every visual and UI defect in the
locally running application. Use {{BROWSER_TOOL}} to screenshot every page,
state, and interactive component; fix each defect; re-screenshot to confirm.

Completion is defined solely by the checklist in the "Completion, Blockers &
Stopping" section at the end of this prompt -- nothing else.

---

## Defect Ledger -- Read First, Update Always

`{{PROGRESS_FILE}}` is the single source of truth for progress. Conversation
memory does not survive context compaction or fresh-context passes
(multipass); this file does.

- **On start:** if the file exists, read it and resume from the first
  screenshot pass or defect not marked done. If it does not exist, create it
  with one line per screenshot pass (viewport x theme), all `pending`.
- **Defect format:** `D-014 | open / fixed / blocked | page + state | viewport/theme | short note`
  -- append a line the moment a defect is spotted; flip it to `fixed` only
  after the confirming re-screenshot.
- **Update immediately**, never in batches. Append one line to a
  `## Session log` section at the bottom of the file each pass.

---

## Application Setup -- Local

Both servers must be running before any visual testing begins:

```bash
# Backend
{{BACKEND_START_COMMAND}}

# Frontend
{{FRONTEND_START_COMMAND}}
```

Verify the application loads at `{{FRONTEND_URL}}` before starting.

---

## Screenshot Coverage -- Mandatory

Screenshot every state listed below at desktop (1280px wide) and mobile
(375px wide). If the layout has tablet-specific breakpoints, add a 768px pass
for the affected pages. Do not skip any state.

[theming] Repeat full coverage once per theme in {{THEMES}}. Before each
theme's pass, switch to it with the app's theme switcher and confirm it is
applied globally before taking any screenshots.

### Authentication Pages

- Login page (empty form)
- Login page with validation errors (submit empty form)
- [registration] Register page (empty form)
- [registration] Register page with validation errors

### Main Application -- Desktop (1280px)

{{DESKTOP_STATES}}

### Main Application -- Mobile (375px)

{{MOBILE_STATES}}

---

## Defect Categories to Inspect

For every screenshot, inspect and fix defects in the following categories:

### Visibility

- Text invisible or near-invisible due to insufficient contrast against its background
- Elements unintentionally hidden behind other elements
- Overflow: content clipped or cut off without indication
- Transparent backgrounds revealing unintended layers
- White or light flashes during transitions or page load

### Layout & Alignment

- Warped, stretched, or squashed elements (images, avatars, icons, buttons)
- Misaligned items within a row or column
- Elements overflowing their containers and breaking adjacent layout
- Inconsistent spacing (gaps, padding, margins) between similar elements
- Grid or flex layout collapsing incorrectly at any breakpoint

### Typography

- Text overflow without ellipsis or wrapping
- Line height causing text overlap
- Font weight or size inconsistencies across similar elements
- Truncated labels missing a tooltip or accessible alternative

### Interactive States

- Buttons or inputs with no visible focus ring
- Hover states absent or broken
- Disabled states indistinguishable from enabled states
- Loading spinners or skeletons not centered or sized correctly

### Accessibility Quick Wins

- Images missing meaningful alt text
- Icon-only buttons missing an accessible label (aria-label)
- Form inputs missing an associated label
- Keyboard tab order that skips or traps focus on the inspected page

<!-- OPTIONAL: theming -->

### Theme Integrity (per theme in {{THEMES}})

- Hard-coded colors from another theme visible (e.g. white backgrounds or
  black text in dark theme, and vice versa)
- Borders or dividers invisible against the theme background
- Input placeholder text invisible or too faint
- Scrollbar styles inconsistent with the theme
- Elements that do not respond to the theme toggle at all
- Theme switching transitions cleanly with no visual artefacts

<!-- END OPTIONAL: theming -->

### Responsive Behaviour

- Sidebar or navigation not collapsing correctly on narrow viewports
- Input elements or action buttons falling off screen on mobile
- Images or media overflowing their container on small screens
- Touch targets smaller than 44px on mobile

---

## Work Cycle

1. Screenshot all states at 1280px, then at 375px
   [theming] -- repeating per theme in {{THEMES}}.
2. Log every defect found in `{{PROGRESS_FILE}}` as you go.
3. For each defect: locate the component or style in the frontend source,
   apply a targeted fix (CSS class correction, style override, component
   structure adjustment), let hot-reload pick it up, and re-screenshot the
   same state, viewport, and theme to confirm. Do not move on until the fix
   is visually confirmed and the ledger updated.
4. Final pass: re-screenshot ALL states at both viewports
   [theming] in every theme -- to confirm zero remaining defects and no
   regressions from the fixes.
5. Run `{{TYPE_CHECK_COMMAND}}` -- it must pass with zero errors.

**Stuck rule:** after 3 failed fix attempts on the same defect, record what
you tried in `{{PROGRESS_FILE}}`, mark it `blocked`, move on, and revisit
blocked defects at the end.

---

## Constraints

- **Do NOT change application logic, API calls, or backend code.** Fix only
  frontend visuals: templates, styles, CSS classes, component structure.
- **Do NOT modify `spec.md`** or any specification documents.
- **Never alter** authentication flow, data handling, or WebSocket behaviour
  as a side effect of visual changes.

---

## Completion, Blockers & Stopping

**Definition of done -- every box checked:**

- [ ] Every page and state has been screenshotted at 1280px and 375px
- [ ] [theming] Full coverage was repeated in every theme in {{THEMES}}
- [ ] Every defect found is `fixed` in `{{PROGRESS_FILE}}`, each confirmed by
      a follow-up screenshot in the affected state, viewport, and theme
- [ ] The final full pass shows zero remaining defects
- [ ] `{{TYPE_CHECK_COMMAND}}` passes with zero errors
- [ ] `{{PROGRESS_FILE}}` is up to date with no `open` defects or `pending` passes

Work autonomously and persistently toward this checklist. Do not stop because
the defect list is long or context is running low -- context is compacted
automatically, and `{{PROGRESS_FILE}}` carries state across passes.

**The only valid reasons to mark a defect `blocked` instead of fixing it:**

- The fix would require changing application logic, backend code, or specs
  (out of scope here -- log it for a separate task)
- A design decision that belongs to a human (e.g. two plausible intended
  layouts and no way to tell which is right)
- The stuck rule (3 failed fix attempts) fired

Stop only when every pass is complete and every defect is `fixed`, or the
only remaining defects are `blocked`. Then report: what was fixed, and every
blocker from `{{PROGRESS_FILE}}` with what was tried. Never claim a defect is
fixed without the confirming screenshot.
