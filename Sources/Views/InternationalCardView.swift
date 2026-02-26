import Cocoa
import Foundation

// MARK: - International Card View (紧凑版)
class InternationalCardView: NSView {
    private let titleRow = NSStackView()
    private var londonLabels: (price: NSTextField, changeIcon: NSImageView, changeLabel: NSTextField)!
    private var newyorkLabels: (price: NSTextField, changeIcon: NSImageView, changeLabel: NSTextField)!

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
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        // Padding consistent with PriceCardView
        container.edgeInsets = NSEdgeInsets(top: 8, left: 16, bottom: 12, right: 16)

        // Title row: 国际金价 (Section Header Style)
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 6
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

        // Price rows using NSGridView for alignment
        let gridView = NSGridView(views: [])
        gridView.columnSpacing = 12
        gridView.rowSpacing = 6
        gridView.translatesAutoresizingMaskIntoConstraints = false
        
        // London Row
        let londonName = createLabel("伦敦金", fontSize: 13, weight: .regular, color: .labelColor)
        let londonPrice = createLabel("--", fontSize: 15, weight: .bold, color: .labelColor, monospaced: true)
        let (londonChangeStack, londonChangeIcon, londonChangeLabel) = createChangeStack()
        
        // New York Row
        let newyorkName = createLabel("纽约金", fontSize: 13, weight: .regular, color: .labelColor)
        let newyorkPrice = createLabel("--", fontSize: 15, weight: .bold, color: .labelColor, monospaced: true)
        let (newyorkChangeStack, newyorkChangeIcon, newyorkChangeLabel) = createChangeStack()
        
        gridView.addRow(with: [londonName, londonPrice, londonChangeStack])
        gridView.addRow(with: [newyorkName, newyorkPrice, newyorkChangeStack])
        
        // Align columns
        gridView.column(at: 0).xPlacement = .leading
        gridView.column(at: 1).xPlacement = .trailing
        gridView.column(at: 2).xPlacement = .trailing
        
        container.addArrangedSubview(gridView)
        
        londonLabels = (londonPrice, londonChangeIcon, londonChangeLabel)
        newyorkLabels = (newyorkPrice, newyorkChangeIcon, newyorkChangeLabel)

        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
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
    
    private func createChangeStack() -> (NSStackView, NSImageView, NSTextField) {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 2
        
        let icon = NSImageView()
        icon.symbolConfiguration = .init(pointSize: 10, weight: .bold)
        stack.addArrangedSubview(icon)
        
        let label = NSTextField()
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        stack.addArrangedSubview(label)
        
        return (stack, icon, label)
    }

    func update(london: PriceInfo, newyork: PriceInfo) {
        updateRow(labels: londonLabels, info: london)
        updateRow(labels: newyorkLabels, info: newyork)
    }
    
    private func updateRow(labels: (price: NSTextField, changeIcon: NSImageView, changeLabel: NSTextField), info: PriceInfo) {
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
    }
}
