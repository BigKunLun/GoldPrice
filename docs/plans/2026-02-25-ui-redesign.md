# UI Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign the floating window with native macOS glass effect, card-based layout, and price change flash animation.

**Architecture:** Replace current solid background with NSVisualEffectView for glass effect. Create new PriceCardView component for each gold price. Use system native colors for dark/light mode adaptation.

**Tech Stack:** Swift 5.9, AppKit (Cocoa), NSVisualEffectView, NSAnimationContext

---

### Task 1: Create PriceCardView Component

**Files:**
- Modify: `Sources/main.swift` (add new class after PriceHistoryManager)

**Step 1: Add PriceCardView class**

Add the following class after `PriceHistoryManager` (around line 115):

```swift
// MARK: - Price Card View
class PriceCardView: NSView {
    private let nameLabel = NSTextField()
    private let priceLabel = NSTextField()
    private let changeLabel = NSTextField()
    private let highLabel = NSTextField()
    private let lowLabel = NSTextField()

    private var lastPrice: String = ""

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.1).cgColor

        let mainRow = NSStackView()
        mainRow.orientation = .horizontal
        mainRow.alignment = .centerY
        mainRow.distribution = .fill
        mainRow.spacing = 6

        // Name
        nameLabel.font = NSFont.systemFont(ofSize: 11)
        nameLabel.textColor = NSColor.secondaryLabelColor
        nameLabel.backgroundColor = .clear
        nameLabel.isBezeled = false
        nameLabel.isEditable = false
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)
        mainRow.addArrangedSubview(nameLabel)

        // Spacer
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        mainRow.addArrangedSubview(spacer)

        // Price
        priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        priceLabel.textColor = NSColor.labelColor
        priceLabel.backgroundColor = .clear
        priceLabel.isBezeled = false
        priceLabel.isEditable = false
        priceLabel.alignment = .right
        mainRow.addArrangedSubview(priceLabel)

        // Change
        changeLabel.font = NSFont.systemFont(ofSize: 11)
        changeLabel.backgroundColor = .clear
        changeLabel.isBezeled = false
        changeLabel.isEditable = false
        changeLabel.setContentHuggingPriority(.required, for: .horizontal)
        mainRow.addArrangedSubview(changeLabel)

        // Sub row (high/low)
        let subRow = NSStackView()
        subRow.orientation = .horizontal
        subRow.alignment = .centerY
        subRow.spacing = 8

        let subSpacer = NSView()
        subSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        highLabel.font = NSFont.systemFont(ofSize: 10)
        highLabel.textColor = NSColor.tertiaryLabelColor
        highLabel.backgroundColor = .clear
        highLabel.isBezeled = false
        highLabel.isEditable = false

        lowLabel.font = NSFont.systemFont(ofSize: 10)
        lowLabel.textColor = NSColor.tertiaryLabelColor
        lowLabel.backgroundColor = .clear
        lowLabel.isBezeled = false
        lowLabel.isEditable = false

        subRow.addArrangedSubview(subSpacer)
        subRow.addArrangedSubview(highLabel)
        subRow.addArrangedSubview(lowLabel)

        // Container
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .fill
        container.spacing = 2
        container.translatesAutoresizingMaskIntoConstraints = false
        container.edgeInsets = NSEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

        container.addArrangedSubview(mainRow)
        container.addArrangedSubview(subRow)

        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func update(name: String, info: PriceInfo) {
        nameLabel.stringValue = name
        priceLabel.stringValue = info.price

        // Check for price change and trigger flash
        if lastPrice != info.price && !lastPrice.isEmpty {
            flashBackground(isUp: info.isUp)
        }
        lastPrice = info.price

        // Update change label
        if !info.changeRate.isEmpty {
            let arrow = info.isUp ? "↑" : "↓"
            changeLabel.stringValue = "\(arrow) \(info.changeRate)"
            changeLabel.textColor = info.isUp ? NSColor.systemRed : NSColor.systemGreen
        } else {
            changeLabel.stringValue = ""
        }

        // Update high/low
        if info.dayHigh != "--" {
            highLabel.stringValue = "▲\(info.dayHigh)"
        } else {
            highLabel.stringValue = ""
        }
        if info.dayLow != "--" {
            lowLabel.stringValue = "▼\(info.dayLow)"
        } else {
            lowLabel.stringValue = ""
        }
    }

    private func flashBackground(isUp: Bool) {
        let flashColor = isUp
            ? NSColor.systemRed.withAlphaComponent(0.15)
            : NSColor.systemGreen.withAlphaComponent(0.15)

        layer?.backgroundColor = flashColor.cgColor

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.allowsImplicitAnimation = true
            layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.1).cgColor
        }
    }
}
```

**Step 2: Build to verify no syntax errors**

Run: `./build.sh`
Expected: Build success

---

### Task 2: Replace FloatingContentView with Glass Effect

**Files:**
- Modify: `Sources/main.swift` (FloatingContentView class)

**Step 1: Rewrite FloatingContentView with glass effect and cards**

Replace the entire `FloatingContentView` class with:

```swift
// MARK: - Floating Content View
class FloatingContentView: NSView {
    private var cards: [String: PriceCardView] = [:]
    private let cardKeys = ["minsheng", "london", "newyork"]
    private let cardNames = [
        "minsheng": "民生",
        "london": "伦敦金",
        "newyork": "纽约金"
    ]

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 180, height: 120))
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        // Glass effect background
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.translatesAutoresizingMaskIntoConstraints = false

        addSubview(visualEffect)
        NSLayoutConstraint.activate([
            visualEffect.topAnchor.constraint(equalTo: topAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: bottomAnchor),
            visualEffect.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Card container
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .fill
        container.spacing = 4
        container.translatesAutoresizingMaskIntoConstraints = false
        container.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        for key in cardKeys {
            let card = PriceCardView()
            cards[key] = card
            container.addArrangedSubview(card)
        }

        visualEffect.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            container.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor)
        ])
    }

    func updatePrices(_ prices: GoldPrices) {
        for key in cardKeys {
            if let card = cards[key], let name = cardNames[key] {
                card.update(name: name, info: prices.priceInfo(for: key))
            }
        }
    }
}
```

**Step 2: Build and verify**

Run: `./build.sh`
Expected: Build success

---

### Task 3: Update FloatingWindow

**Files:**
- Modify: `Sources/main.swift` (FloatingWindow class)

**Step 1: Simplify FloatingWindow**

Replace the `FloatingWindow` class with:

```swift
// MARK: - Floating Window
class FloatingWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 120),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
    }

    func positionAtTopRight() {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.maxX - self.frame.width - 20
            let y = screenRect.maxY - self.frame.height - 20
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}
```

**Step 2: Build and verify**

Run: `./build.sh`
Expected: Build success

---

### Task 4: Update AppDelegate setupFloatingWindow

**Files:**
- Modify: `Sources/main.swift` (AppDelegate.setupFloatingWindow method)

**Step 1: Simplify setupFloatingWindow**

Replace the `setupFloatingWindow` method in `AppDelegate` with:

```swift
private func setupFloatingWindow() {
    floatingWindow = FloatingWindow()
    floatingContentView = FloatingContentView()
    floatingWindow?.contentView = floatingContentView
    floatingWindow?.positionAtTopRight()
}
```

**Step 2: Build and verify**

Run: `./build.sh`
Expected: Build success

---

### Task 5: Remove unused code and test

**Files:**
- Modify: `Sources/main.swift`

**Step 1: Remove unused properties in FloatingContentView**

Remove these unused properties from FloatingContentView (now replaced):
- `priceLabels`
- `changeLabels`
- `highLabels`
- `lowLabels`
- `timeLabel`

These are no longer needed as the new `PriceCardView` handles all display.

**Step 2: Remove unused helper methods**

Remove these methods from FloatingContentView (now replaced):
- `createLabel`
- `addPriceRow`
- `addPriceRowWithHighLow`
- `updatePriceDisplayWithHighLow`

**Step 3: Build and run**

Run: `./build.sh && open JDGold.app`
Expected: App launches with new glass effect UI

**Step 4: Verify visually**

- Check glass effect background
- Check card layout
- Check font sizes and colors
- Check price change flash (wait for price updates)

---

### Task 6: Commit changes

**Step 1: Stage and commit**

```bash
git add Sources/main.swift docs/plans/
git commit -m "feat: redesign UI with glass effect and card layout

- Replace solid background with NSVisualEffectView for native glass effect
- Create PriceCardView component for each gold price
- Use system native colors for dark/light mode adaptation
- Add price change flash animation
- Remove section titles and update time for cleaner layout
- Fix international gold price encoding (GB18030 support)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Create PriceCardView component | main.swift |
| 2 | Rewrite FloatingContentView | main.swift |
| 3 | Simplify FloatingWindow | main.swift |
| 4 | Update setupFloatingWindow | main.swift |
| 5 | Remove unused code & test | main.swift |
| 6 | Commit | - |
