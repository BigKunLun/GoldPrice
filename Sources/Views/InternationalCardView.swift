import Cocoa
import Foundation

// MARK: - International Card View
class InternationalCardView: NSView {
    private let titleRow = NSStackView()
    private var londonLabels: (price: NSTextField, changeIcon: NSImageView, changeLabel: NSTextField, highLow: NSTextField)!
    private var newyorkLabels: (price: NSTextField, changeIcon: NSImageView, changeLabel: NSTextField, highLow: NSTextField)!

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 6
        container.translatesAutoresizingMaskIntoConstraints = false
        container.edgeInsets = NSEdgeInsets(top: 6, left: 0, bottom: 10, right: 0)

        // Title row: 国际金价
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 5
        titleRow.translatesAutoresizingMaskIntoConstraints = false

        let iconImage = NSImageView()
        iconImage.image = NSImage(systemSymbolName: "globe.asia.australia.fill", accessibilityDescription: "Global")
        iconImage.contentTintColor = .systemBlue
        iconImage.symbolConfiguration = .init(pointSize: 12, weight: .regular)
        titleRow.addArrangedSubview(iconImage)

        let titleLabel = NSTextField()
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        titleLabel.stringValue = "国际金价"
        titleLabel.textColor = NSColor.secondaryLabelColor
        titleLabel.backgroundColor = .clear
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleRow.addArrangedSubview(titleLabel)

        container.addArrangedSubview(titleRow)

        // London section
        let londonRow = createPriceRow(name: "伦敦金")
        let londonHighLow = createHighLowLabel()
        container.addArrangedSubview(londonRow.container)
        container.addArrangedSubview(londonHighLow)

        // New York section
        let newyorkRow = createPriceRow(name: "纽约金")
        let newyorkHighLow = createHighLowLabel()
        container.addArrangedSubview(newyorkRow.container)
        container.addArrangedSubview(newyorkHighLow)

        londonLabels = (londonRow.price, londonRow.changeIcon, londonRow.changeLabel, londonHighLow)
        newyorkLabels = (newyorkRow.price, newyorkRow.changeIcon, newyorkRow.changeLabel, newyorkHighLow)

        // Set custom spacing: tighter between price row and its high/low
        container.setCustomSpacing(2, after: londonRow.container)
        container.setCustomSpacing(8, after: londonHighLow)
        container.setCustomSpacing(2, after: newyorkRow.container)

        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            londonRow.container.widthAnchor.constraint(equalTo: container.widthAnchor),
            newyorkRow.container.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])
    }

    private func createPriceRow(name: String) -> (container: NSStackView, price: NSTextField, changeIcon: NSImageView, changeLabel: NSTextField) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = createLabel(name, fontSize: 13, weight: .regular, color: .labelColor)
        row.addArrangedSubview(nameLabel)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(spacer)

        let priceLabel = createLabel("--", fontSize: 15, weight: .bold, color: .labelColor, monospaced: true)
        row.addArrangedSubview(priceLabel)

        let changeStack = NSStackView()
        changeStack.orientation = .horizontal
        changeStack.alignment = .centerY
        changeStack.spacing = 2

        let changeIcon = NSImageView()
        changeIcon.symbolConfiguration = .init(pointSize: 10, weight: .bold)
        changeStack.addArrangedSubview(changeIcon)

        let changeLabel = createLabel("", fontSize: 12, weight: .medium, color: .secondaryLabelColor, monospaced: true)
        changeStack.addArrangedSubview(changeLabel)

        // Fixed width for change column to maintain alignment
        changeStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true

        row.addArrangedSubview(changeStack)

        return (row, priceLabel, changeIcon, changeLabel)
    }

    private func createHighLowLabel() -> NSTextField {
        let label = NSTextField()
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        label.textColor = NSColor.tertiaryLabelColor
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.stringValue = ""
        label.isHidden = true
        return label
    }

    private func createLabel(_ text: String, fontSize: CGFloat, weight: NSFont.Weight, color: NSColor, monospaced: Bool = false) -> NSTextField {
        let label = NSTextField()
        if monospaced {
            label.font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: weight)
        } else {
            label.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        }
        label.stringValue = text
        label.textColor = color
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        return label
    }

    func update(london: PriceInfo, newyork: PriceInfo) {
        updateRow(labels: londonLabels, info: london)
        updateRow(labels: newyorkLabels, info: newyork)
    }

    private func updateRow(labels: (price: NSTextField, changeIcon: NSImageView, changeLabel: NSTextField, highLow: NSTextField), info: PriceInfo) {
        labels.price.stringValue = info.price

        if !info.changeRate.isEmpty {
            let symbol = info.isUp ? "arrow.up" : "arrow.down"
            let color = info.isUp ? NSColor.systemRed : NSColor.systemGreen

            labels.changeIcon.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            labels.changeIcon.contentTintColor = color

            labels.changeLabel.stringValue = info.changeRate
            labels.changeLabel.textColor = color
            labels.changeIcon.isHidden = false
        } else {
            labels.changeLabel.stringValue = ""
            labels.changeIcon.image = nil
            labels.changeIcon.isHidden = true
        }

        // High/Low
        if info.dayHigh != "--" && info.dayLow != "--" {
            labels.highLow.stringValue = "高 \(info.dayHigh)  低 \(info.dayLow)"
            labels.highLow.isHidden = false
        } else {
            labels.highLow.isHidden = true
        }
    }
}
