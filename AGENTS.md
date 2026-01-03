# AGENTS.md — Potential MVP (Apple-style)

## Mission
Implement an Potential MVP that **feels like a real Apple app** while tracking **daily % of goals achieved** and supporting **weekly routine customization**. Screenshots are **inspiration only**; when they conflict with Apple patterns, prefer **iOS Human Interface Guidelines (HIG)** and Cupertino conventions.

Speed is prioritized, but code quality must remain **FAANG-level clean**.

---

## Non-Negotiables (Strict Rulebook)

### iOS look & behavior
- Use **Cupertino widgets wherever possible**.
- Follow iOS navigation, spacing, typography, and interaction patterns even if screenshots differ.
- Use **SF Pro only** (system font). Do not add custom fonts.
- Use **iOS-style motion** (spring-like, subtle) and **haptics** where appropriate.
- Prefer **“feel over pixel-perfect.”**

### Feedback handling
- Feedback is **intent-based**.
- Ask clarifying questions **aggressively** before implementing if any instruction is ambiguous.
- If you deviate from user instructions, you must:
  1) explain why,
  2) cite the Apple guideline rationale (by concept/section name),
  3) propose an alternative that preserves the user’s intent.

### Architecture
- State management: **BLoC** (flutter_bloc).
- Navigation: **GoRouter**.
- Fully wire state (no “UI only” screens). Use mock/in-memory repositories.
- No backend, no auth.

### Documentation expectations
- Comment design rationale (brief, purposeful).
- Explain deviations from screenshots explicitly.
- Keep changes small, reviewable, and consistent.

---

## Product Requirements (What to build)

### Core concept
- The app tracks **daily “% of goals achieved”**.
- Users can define **routines** and **tasks** for those routines.
- Users can assign **importance/weight** to routines/tasks; the daily score reflects that weighting.
- Users can customize routines **throughout the week** (day-by-day applicability).

### MVP scope
- Local-only persistence (choose a simple local store; no restrictions).
- Enough screens to create/edit routines & tasks, see daily progress, and review weekly configuration.

---

## Design System (Apple-style Tokens)

Create a small design system inferred from iOS conventions (not from screenshots):
- **Typography tokens**: map to iOS text styles (e.g., largeTitle, title1, body, footnote, caption).
- **Spacing scale**: a small set of spacing constants (e.g., 4/8/12/16/20/24/32).
- **Radii**: subtle, consistent rounding (avoid “over-rounded”).
- **Color**: start with system semantic colors (label, secondaryLabel, systemBackground, secondarySystemBackground, separator).
- **Elevations/shadows**: minimal; prefer iOS-style separators and grouped backgrounds.

Rules:
- Prefer semantic tokens (`AppTextStyle.body`, `AppSpace.m`, `AppColor.separator`) over raw literals.
- Centralize tokens and avoid per-widget bespoke styling.
- Dark mode should work by default via semantic colors.

---

## UX Patterns to Prefer (iOS HIG aligned)
- Navigation:
  - Large titles where appropriate.
  - Back behavior is consistent; avoid custom back buttons unless necessary.
  - Use modal sheets for creation/edit flows when it fits iOS patterns.
- Lists:
  - Prefer iOS grouped list aesthetics for settings-like screens.
  - Use separators and system background groupings.
- Controls:
  - Use native-feeling toggles, steppers, segmented controls where appropriate.
- Feedback:
  - Use haptics on primary actions (save/complete/commit) and selection changes (subtle).
- Motion:
  - Subtle transitions; avoid heavy custom animations.
  - Animations should reinforce hierarchy and state change, not decoration.

---

## Engineering Standards (FAANG-level cleanliness)

### Code organization
Suggested structure (adjust as needed, but keep layering consistent):
- `lib/app/` (app bootstrap, router, theme, DI)
- `lib/design_system/` (tokens, components)
- `lib/features/<feature_name>/`
  - `data/` (models, repositories, local storage)
  - `domain/` (entities, usecases if needed)
  - `presentation/` (pages, widgets, bloc)

### BLoC rules
- BLoCs should be small and feature-scoped.
- State should be immutable and equatable.
- Prefer explicit events and states over “do everything” events.
- Keep UI dumb: UI dispatches events; BLoC owns logic.

### GoRouter rules
- Define routes centrally with typed/structured parameters.
- Keep navigation declarative and consistent with iOS patterns.
- Avoid deeply nested routes unless there is clear hierarchy.

### Data rules (local-only)
- Use an in-memory repository first, then add persistence cleanly behind an interface.
- Keep data models versionable and avoid “giant JSON blobs” without structure.

---

## Screenshot-Driven Workflow (Inspiration Only)

### Process per screen
1. **Interpretation**
   - Identify the screen’s purpose and hierarchy.
   - Identify iOS patterns that match the intent.
2. **Questions (mandatory if unclear)**
   - Ask clarifying questions before coding when:
     - the primary action is ambiguous,
     - a component could be multiple iOS patterns,
     - the data model implied by the UI is unclear.
3. **Implementation**
   - Build using Cupertino-first components and design tokens.
   - Wire state fully (mock repo ok).
4. **Explain deviations**
   - If you diverge from screenshot visuals, add a short rationale comment and log it (see below).

---

## Deviation Logging (Required)
Maintain a lightweight record of intentional deviations:
- Create `docs/deviations.md` (or similar) with entries:
  - **Context** (screen/feature)
  - **What screenshot suggested**
  - **What we implemented**
  - **Why** (Apple guideline concept)
  - **Tradeoffs**
  - **Open questions**

Keep it brief. This is to ensure traceability and alignment.

---

## Clarifying Questions Protocol (Aggressive by design)
Before implementing a screen/feature, ask questions such as:
- What is the **single primary action** on this screen?
- What is the **source of truth** for progress (%): tasks completed, weighted tasks, weighted routines, or both?
- How should **importance/weight** behave?
  - linear multiplier? capped? normalized daily to 100?
- Weekly customization:
  - routines assigned per weekday, or tasks vary by weekday?
- What’s the desired empty state behavior?
- What is the “done” meaning: completed for the day, or permanently completed?

If the user’s instruction conflicts with iOS conventions, ask:
- “Do you want strict iOS behavior, or should we preserve this screenshot behavior even if it’s not iOS-standard?”

---

## Definition of Done (Per PR / Change)
A change is done when:
- UI feels iOS-native (Cupertino-first; correct hierarchy).
- State is wired through BLoC with predictable transitions.
- No obvious hardcoded styling outside the design system.
- Deviation rationale is documented when applicable.
- Basic accessibility sanity:
  - tappable targets are reasonable,
  - text scales without breaking layout,
  - semantic labels where needed.

---

## Performance & Optimization
No special performance constraints for MVP, but:
- Avoid unnecessary rebuilds in lists.
- Use const constructors where meaningful.
- Keep animations lightweight.

---

## What NOT to do
- Do not implement Material-first UI then “skin” it to look iOS.
- Do not copy screenshot pixel values blindly.
- Do not add a backend/auth.
- Do not ignore feedback; if unclear, ask questions.

---

## Success Criteria (What matters most)
- The app **feels like a real Apple app**.
- The agent **does not deviate from instructions** without explicit reasoning + guideline-based justification.
- Speed is valued, but the codebase must remain clean and extensible.
