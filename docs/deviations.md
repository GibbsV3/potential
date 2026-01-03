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
