
# {{APP_NAME}} -- Aesthetics & UI Fix Prompt

## Core Definitions

| ID         | Value                                        |
| ---------- | -------------------------------------------- |
| `frontend` | {{FRONTEND_FRAMEWORK}} on `{{FRONTEND_URL}}` |
| `backend`  | {{BACKEND_FRAMEWORK}} on `{{BACKEND_URL}}`   |
| `themes`   | {{THEMES}}                                   |
| `tool`     | playwright-cli                               |

---

## Primary Goal

Work autonomously to identify and fix all visual and UI defects in the locally running application. Use playwright-cli to screenshot every page, state, and interactive component. Fix every issue found. Re-screenshot after each fix to confirm resolution.

**YOU CANNOT STOP UNTIL EVERY VISUAL DEFECT IS IDENTIFIED, FIXED, AND CONFIRMED RESOLVED.**

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

Take screenshots of every state listed below in **each theme variant**. Do not skip any state or theme. Identify defects in each.

### Theme Switching

Before starting each theme pass, toggle the application theme using the theme switcher. Confirm the active theme is applied globally before taking any screenshots in that pass.

### Authentication Pages

- Login page (empty form)
- Login page with validation errors (submit empty form)
- Register page (empty form) (if applicable)
- Register page with validation errors (if applicable)

### Main Application -- Desktop (1280px wide)

{{DESKTOP_STATES}}

### Main Application -- Mobile (375px wide)

{{MOBILE_STATES}}

All states above must be screenshotted once per theme variant.

---

## Defect Categories to Inspect

For every screenshot, inspect and fix defects in the following categories:

### Visibility

- Text that is invisible or near-invisible due to insufficient contrast against its background
- Elements hidden behind other elements unintentionally
- Overflow: content clipped or cut off without indication
- Transparent backgrounds revealing unintended layers
- White or light flashes on dark theme during transitions or page load

### Layout & Alignment

- Warped, stretched, or squashed elements (images, avatars, icons, buttons)
- Misaligned items within a row or column (vertical or horizontal alignment broken)
- Elements overflowing their containers and breaking adjacent layout
- Inconsistent spacing (gaps, padding, margins) between similar elements
- Grid or flex layout collapsing incorrectly at any breakpoint

### Typography

- Text overflow without ellipsis or wrapping
- Line height causing text overlap
- Font weight or size inconsistencies across similar elements
- Truncated labels missing tooltip or accessible alternative

### Interactive States

- Buttons or inputs with no visible focus ring
- Hover states absent or broken
- Disabled states indistinguishable from enabled states
- Loading spinners or skeletons not centered or sized correctly

### Dark Theme Integrity

- Hard-coded light colors (white backgrounds, black text) visible in dark theme
- Borders or dividers invisible on dark backgrounds
- Input placeholder text invisible
- Scrollbar styles inconsistent with dark theme

### Light Theme Integrity

- Hard-coded dark colors (dark backgrounds, white text) visible in light theme
- Borders or dividers invisible on light backgrounds
- Input placeholder text invisible or too light
- Scrollbar styles inconsistent with light theme
- Elements that remain dark-themed and do not respond to the light theme toggle

### Responsive Behaviour

- Sidebar or navigation not collapsing correctly on narrow viewports
- Input elements or action buttons falling off screen on mobile
- Images or media overflowing their container on small screens
- Touch targets smaller than 44px on mobile

---

## Fix Workflow

For each defect found:

1. Screenshot and note the exact element, page, and viewport where the defect appears.
2. Locate the relevant component or style in the frontend source.
3. Apply the targeted fix (CSS class correction, style override, component structure adjustment).
4. Save -- hot-reload picks up the change automatically.
5. Screenshot the same state again to confirm the fix is resolved.
6. Do NOT move to the next defect until the current one is visually confirmed.

---

## Constraints

- **Do NOT change application logic, API calls, or backend code.** Fix only frontend visuals (templates, styles, CSS classes, component structure).
- **Do NOT modify `spec.md`** or any specification documents.
- **Never alter** authentication flow, data handling, or WebSocket behaviour as a side effect of visual changes.
- After all fixes, run type checking -- it MUST pass with zero errors: `{{TYPE_CHECK_COMMAND}}`

---

## Autonomous Work Expectations -- CRITICAL

### Context Window Management

Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off.

### Completion Mandate -- ABSOLUTE

- **YOU CANNOT STOP** until every defect found is fixed and visually confirmed.
- **DO NOT** stop early -- work until every screenshot is clean.
- Do NOT stop tasks due to token budget concerns.
- NEVER artificially stop any task early regardless of context remaining.

### Work Cycle

1. Screenshot all states in **dark theme** at 1280px (desktop).
2. Screenshot all states in **dark theme** at 375px (mobile).
3. Screenshot all states in **light theme** at 1280px (desktop).
4. Screenshot all states in **light theme** at 375px (mobile).
5. Compile the full defect list, tagged by theme and viewport.
6. Fix each defect -- screenshot in the affected theme and viewport to confirm -- repeat.
7. Final pass: re-screenshot all states in both themes at both viewports to confirm zero remaining defects.
8. Run type checking -- confirm zero errors.

---

## Completion Criteria

Work is **NOT** complete until:

- Every page and state has been screenshotted in each theme at both 1280px and 375px
- Every defect in all categories above has been identified and fixed
- Every fix has been confirmed with a follow-up screenshot in the affected theme and viewport
- A final full-pass screenshot review shows zero remaining defects in all themes
- Type checking passes with zero errors
- Each theme renders correctly with no bleed from other themes at any viewport
- Theme switching transitions cleanly with no visual artefacts

**DO NOT STOP EARLY. WORK CONTINUOUSLY UNTIL COMPLETE.**
