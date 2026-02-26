import Cocoa
import Foundation

// MARK: - International Card View
class InternationalCardView: NSView {
    // Removed titleRow
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
        // Removed edgeInsets as we use layout constraints now
        // container.edgeInsets = NSEdgeInsets(top: 0, left: 12, bottom: 4, right: 12)

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
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            londonRow.container.widthAnchor.constraint(equalTo: container.widthAnchor),
            newyorkRow.container.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])
    }

    private func createPriceRow(name: String) -> (container: NSStackView, price: NSTextField, changeIcon: NSImageView, changeLabel: NSTextField) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 0
        row.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = createLabel(name, fontSize: 13, weight: .regular, color: .labelColor)
        row.addArrangedSubview(nameLabel)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(spacer)

        let priceLabel = createLabel("--", fontSize: 15, weight: .bold, color: .labelColor, monospaced: true)
        priceLabel.alignment = .right
        priceLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        row.addArrangedSubview(priceLabel)

        let gap = NSView()
        gap.widthAnchor.constraint(equalToConstant: 8).isActive = true
        row.addArrangedSubview(gap)

        let changeStack = NSStackView()
        changeStack.orientation = .horizontal
        changeStack.alignment = .centerY
        changeStack.spacing = 2
        changeStack.translatesAutoresizingMaskIntoConstraints = false
        changeStack.widthAnchor.constraint(equalToConstant: 75).isActive = true

        let changeSpacer = NSView()
        changeSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        changeStack.addArrangedSubview(changeSpacer)

        let changeIcon = NSImageView()
        changeIcon.symbolConfiguration = .init(pointSize: 10, weight: .bold)
        changeStack.addArrangedSubview(changeIcon)

        let changeLabel = createLabel("", fontSize: 12, weight: .medium, color: .secondaryLabelColor, monospaced: true)
        changeStack.addArrangedSubview(changeLabel)

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
