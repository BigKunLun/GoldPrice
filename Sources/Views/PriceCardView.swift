import Cocoa
import Foundation

// MARK: - Price Card View (单行紧凑版)
class PriceCardView: NSView {
    private let mainStack = NSStackView()
    private let topRow = NSStackView()
    private let iconImage = NSImageView()
    private let nameLabel = NSTextField()

    private let changeStack = NSStackView()
    private let changeIcon = NSImageView()
    private let changeLabel = NSTextField()

    private let priceLabel = NSTextField()
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
        mainStack.spacing = 2
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        topRow.orientation = .horizontal
        topRow.alignment = .centerY
        topRow.spacing = 6
        topRow.translatesAutoresizingMaskIntoConstraints = false

        iconImage.image = NSImage(systemSymbolName: "yensign.circle.fill", accessibilityDescription: "Currency")
        iconImage.contentTintColor = .systemYellow
        iconImage.symbolConfiguration = .init(pointSize: 13, weight: .regular)
        topRow.addArrangedSubview(iconImage)

        nameLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = NSColor.secondaryLabelColor
        nameLabel.backgroundColor = .clear
        nameLabel.isBezeled = false
        nameLabel.isEditable = false
        topRow.addArrangedSubview(nameLabel)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        topRow.addArrangedSubview(spacer)

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

        topRow.addArrangedSubview(changeStack)

        mainStack.addArrangedSubview(topRow)

        priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 26, weight: .bold)
        priceLabel.textColor = NSColor.labelColor
        priceLabel.backgroundColor = .clear
        priceLabel.isBezeled = false
        priceLabel.isEditable = false
        mainStack.addArrangedSubview(priceLabel)

        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.isHidden = true
        mainStack.addArrangedSubview(chartView)

        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            topRow.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            chartView.widthAnchor.constraint(equalTo: mainStack.widthAnchor)
        ])
    }

    func update(name: String, icon: String, info: PriceInfo) {
        if name.contains("民生") {
            iconImage.image = NSImage(systemSymbolName: "yensign.circle.fill", accessibilityDescription: "CNY")
            bankKey = "minsheng"
        } else {
            iconImage.image = NSImage(systemSymbolName: "dollarsign.circle.fill", accessibilityDescription: "USD")
            bankKey = "other"
        }

        nameLabel.stringValue = name
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
            chartView.update(with: records)
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
