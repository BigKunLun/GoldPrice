import Cocoa
import Foundation

// MARK: - Floating Window
class FloatingWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 250),
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

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 260, height: 230))
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
        visualEffect.material = .hudWindow // Darker/Modern look
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
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
        container.alignment = .leading
        container.spacing = 4 // Reduced spacing between sections
        container.translatesAutoresizingMaskIntoConstraints = false
        container.edgeInsets = NSEdgeInsets(top: 12, left: 16, bottom: 8, right: 16)

        // Domestic card
        domesticCard = PriceCardView()
        domesticCard!.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(domesticCard!)

        // International card
        internationalCard = InternationalCardView()
        internationalCard!.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(internationalCard!)

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
    }
}
