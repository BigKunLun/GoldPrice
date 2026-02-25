# Tasks

- [x] Task 1: Refactor `InternationalCardView` to use `NSGridView` for perfect column alignment.
  - [x] SubTask 1.1: Replace `NSStackView` loop with `NSGridView`.
  - [x] SubTask 1.2: Define 3 columns: [Name (Left), Price (Right, Monospaced), Change (Right)].
  - [x] SubTask 1.3: Ensure consistent spacing between columns.

- [x] Task 2: Refactor `PriceCardView` to use SF Symbols and optimize visual hierarchy.
  - [x] SubTask 2.1: Replace `🪙` with `yensign.circle.fill` (or `bitcoinsign.circle.fill` if more appropriate).
  - [x] SubTask 2.2: Replace `↑` with `arrow.up.forward` / `arrow.down.forward` SF Symbols.
  - [x] SubTask 2.3: Adjust font weights and sizes to make "Price" the clear focal point but less "blocky".
  - [x] SubTask 2.4: Optimize High/Low display (e.g., smaller font, lighter color, clearer labels like `H:` / `L:`).

- [x] Task 3: Refactor `InternationalCardView` header and iconography.
  - [x] SubTask 3.1: Replace `🌍` with `globe` SF Symbol.
  - [x] SubTask 3.2: Adjust header font size and color (Secondary Label Color).
  - [x] SubTask 3.3: Ensure vertical rhythm matches `PriceCardView`.

- [x] Task 4: Global layout adjustments in `FloatingContentView`.
  - [x] SubTask 4.1: Reduce vertical spacing between Domestic and International sections.
  - [x] SubTask 4.2: Adjust window size if necessary.
  - [x] SubTask 4.3: Ensure padding is consistent (16pt).
  - [ ] SubTask 4.1: Reduce vertical spacing between Domestic and International sections.
  - [ ] SubTask 4.2: Adjust window size if necessary.
  - [ ] SubTask 4.3: Ensure padding is consistent (16pt).

# Task Dependencies
- Task 4 depends on Task 1 & 2 & 3.
