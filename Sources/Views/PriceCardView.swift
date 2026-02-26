import Cocoa
import Foundation

// MARK: - Price Card View
class PriceCardView: NSView {
    private let mainStack = NSStackView()
    private let primaryRow = NSStackView()
    // Removed title/icon elements as requested
    
    private let changeStack = NSStackView()
    private let changeIcon = NSImageView()
    private let changeLabel = NSTextField()

    private let priceLabel = NSTextField()
    private let unitLabel = NSTextField()

    private let chartView = MiniChartView()

    private var lastPrice: String = ""
    private var bankKey: String = "minsheng"

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

        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        // Primary Row: Price + Unit + Spacer + Change
        primaryRow.orientation = .horizontal
        primaryRow.alignment = .firstBaseline
        primaryRow.spacing = 4
        primaryRow.translatesAutoresizingMaskIntoConstraints = false

        priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 26, weight: .bold)
        priceLabel.textColor = NSColor.labelColor
        priceLabel.backgroundColor = .clear
        priceLabel.isBezeled = false
        priceLabel.isEditable = false
        primaryRow.addArrangedSubview(priceLabel)

        unitLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        unitLabel.textColor = NSColor.tertiaryLabelColor
        unitLabel.backgroundColor = .clear
        unitLabel.isBezeled = false
        unitLabel.isEditable = false
        unitLabel.stringValue = "元/克"
        primaryRow.addArrangedSubview(unitLabel)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        primaryRow.addArrangedSubview(spacer)

        changeStack.orientation = .horizontal
        changeStack.alignment = .centerY
        changeStack.spacing = 2

        changeIcon.symbolConfiguration = .init(pointSize: 10, weight: .bold)
        changeStack.addArrangedSubview(changeIcon)

        changeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        changeLabel.backgroundColor = .clear
        changeLabel.isBezeled = false
        changeLabel.isEditable = false
        changeStack.addArrangedSubview(changeLabel)

        primaryRow.addArrangedSubview(changeStack)
        mainStack.addArrangedSubview(primaryRow)

        // Chart view
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.isHidden = true
        mainStack.addArrangedSubview(chartView)

        chartView.heightAnchor.constraint(equalToConstant: 60).isActive = true

        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            primaryRow.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            chartView.widthAnchor.constraint(equalTo: mainStack.widthAnchor)
        ])
    }

    func update(name: String, icon: String, info: PriceInfo) {
        if name.contains("民生") {
            bankKey = "minsheng"
            unitLabel.stringValue = "元/克"
        } else {
            bankKey = "other"
            unitLabel.stringValue = "$/oz"
        }

        priceLabel.stringValue = info.price

        if lastPrice != info.price && !lastPrice.isEmpty {
            flashBackground(isUp: info.isUp)
        }
        lastPrice = info.price

        if !info.changeRate.isEmpty {
            let symbol = info.isUp ? "arrow.up" : "arrow.down"
            let color = info.isUp ? NSColor.systemRed : NSColor.systemGreen

            changeIcon.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            changeIcon.contentTintColor = color

            changeLabel.stringValue = info.changeRate
            changeLabel.textColor = color
            changeIcon.isHidden = false
        } else {
            changeLabel.stringValue = ""
            changeIcon.image = nil
            changeIcon.isHidden = true
        }

        let records = PriceHistoryManager.shared.getRecordsInLast24Hours(for: bankKey)
        if records.count >= 2 {
            // Pass high/low info to chart view
            let high = (info.dayHigh != "--") ? info.dayHigh : nil
            let low = (info.dayLow != "--") ? info.dayLow : nil
            chartView.update(with: records, high: high, low: low)
            chartView.isHidden = false
        } else {
            chartView.isHidden = true
        }
    }

    private func flashBackground(isUp: Bool) {
        let flashColor = isUp
            ? NSColor.systemRed.withAlphaComponent(0.15)
            : NSColor.systemGreen.withAlphaComponent(0.15)

        wantsLayer = true
        layer?.backgroundColor = flashColor.cgColor

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            layer?.backgroundColor = CGColor.clear
        }
    }
}
