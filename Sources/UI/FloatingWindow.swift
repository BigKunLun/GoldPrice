import Cocoa
import Foundation

// MARK: - Floating Window
class FloatingWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 240),
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

// MARK: - Floating Content View
class FloatingContentView: NSView {
    private var domesticCard: PriceCardView?
    private var internationalCard: InternationalCardView?
    private let updateTimeLabel = NSTextField()

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 260, height: 240))
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true

        // Glass effect background
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 14
        visualEffect.layer?.masksToBounds = true
        visualEffect.translatesAutoresizingMaskIntoConstraints = false

        addSubview(visualEffect)
        NSLayoutConstraint.activate([
            visualEffect.topAnchor.constraint(equalTo: topAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: bottomAnchor),
            visualEffect.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Container
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .centerX
        container.spacing = 0
        container.translatesAutoresizingMaskIntoConstraints = false
        container.edgeInsets = NSEdgeInsets(top: 10, left: 0, bottom: 16, right: 0)

        // Domestic card
        domesticCard = PriceCardView()
        domesticCard!.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(domesticCard!)

        // Separator line removed as per request, using chart axis as separator
        
        // International card
        internationalCard = InternationalCardView()
        internationalCard!.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(internationalCard!)

        // Update time label
        updateTimeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        updateTimeLabel.textColor = NSColor.tertiaryLabelColor
        updateTimeLabel.backgroundColor = .clear
        updateTimeLabel.isBezeled = false
        updateTimeLabel.isEditable = false
        updateTimeLabel.alignment = .center
        updateTimeLabel.stringValue = ""
        updateTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(updateTimeLabel)

        // Custom spacing
        container.setCustomSpacing(8, after: domesticCard!)
        container.setCustomSpacing(6, after: internationalCard!)

        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            domesticCard!.widthAnchor.constraint(equalTo: container.widthAnchor),
            internationalCard!.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])
    }

    func updatePrices(_ prices: GoldPrices) {
        domesticCard?.update(name: "民生", icon: "yensign.circle.fill", info: prices.minsheng)
        internationalCard?.update(london: prices.london, newyork: prices.newyork)

        // Update time
        if let lastUpdate = prices.lastUpdate {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            updateTimeLabel.stringValue = "更新于 \(formatter.string(from: lastUpdate))"
        }
    }
}
