# Deviations

- Context: Dashboard list sections
  What screenshot suggested: Flat card stack with custom row styling.
  What we implemented: iOS inset grouped sections with native spacing and separators.
  Why: iOS HIG - Lists and Tables (grouped lists for hierarchy and clarity).
  Tradeoffs: Slightly less card-like, but more native to iOS.
  Open questions: None.

- Context: Task metadata
  What screenshot suggested: Per-task due dates displayed under titles.
  What we implemented: No due dates on the dashboard.
  Why: iOS HIG - Focus and Information Architecture (avoid adding data not in requirements).
  Tradeoffs: Less context per task until due dates are specified.
  Open questions: Should due dates be added to the task model later?

- Context: Tab bar styling
  What screenshot suggested: Floating capsule tab bar with text-only tabs.
  What we implemented: Custom floating capsule tab bar with text-only tabs.
  Why: iOS HIG - Tab Bars (customized appearance to match user-requested Apple-style control).
  Tradeoffs: Uses a custom tab scaffold instead of the system tab bar.
  Open questions: Should we add haptics on tab selection?

- Context: Routines screen layout
  What screenshot suggested: Centered header with floating bottom add button and always-visible delete icons on each card.
  What we implemented: iOS large-title nav bar with trailing add button, leading Edit/Done toggle that reveals delete controls, grouped cards with native switches for activation.
  Why: iOS HIG - Navigation Bars (primary actions in the trailing position) and Edit Mode (destructive controls appear after entering edit).
  Tradeoffs: Add button currently shows a placeholder action until the creation flow is defined.
  Open questions: What is the desired add-routine flow (fields, default weights/tasks, week assignment)?

- Context: Edit routine screen
  What screenshot suggested: Tasks split by routine with a floating bottom add button, squared day chips, and no explicit priority control.
  What we implemented: Cupertino modal edit form with Cancel/Save nav buttons, inset grouped sections, a single Tasks header with an inline add button, capsule weekday chips, and a 5-segment priority selector (stored but not yet used in scoring).
  Why: iOS HIG - Forms (modal sheets with Cancel/Save), Lists and Tables (inset grouped sections for settings-style input), Controls (segmented chips for multi-select days), and primary action placement for inline add instead of floating FAB.
  Tradeoffs: Tasks are flat instead of grouped; add button is inline rather than floating; priority is captured but not yet applied to calculations.
  Open questions: Should Save auto-dismiss without confirmation? How should priority map to routine weighting? Should task ordering be editable?

- Context: Task add/edit sheet
  What screenshot suggested: Full-screen form with title, description, weight, notes, and a bottom navigation bar.
  What we implemented: A Cupertino modal sheet presented full screen with task name, priority selector, and a multiline details field; weight input and the bottom navigation bar were removed.
  Why: iOS HIG - Modality and Sheets (use full-screen modals for focused edits) and System Controls (keep weighting via existing priority control to avoid redundant inputs).
  Tradeoffs: Weight now derives from priority levels instead of manual entry.
  Open questions: Should tasks support richer metadata like checklists or due times?

- Context: History calendar sheet
  What screenshot suggested: A dark, Monday-start calendar with pink rings and no obvious month pinning.
  What we implemented: A Cupertino popup calendar using Sunday-start weeks (matching app calculations), semantic accent rings, and a pinned anchor-month header with nearby months for quick scroll.
  Why: iOS HIG - Consistency (align week boundaries and accent usage across the app) and System Colors (prefer semantic accent rather than screenshot-specific tint).
  Tradeoffs: Week alignment differs from the screenshot, and only a limited month range is preloaded for snappy load.
  Open questions: Should we switch to Monday-first weeks or extend navigation beyond the two-month lookahead?
