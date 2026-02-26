import Cocoa
import Foundation

// MARK: - Mini Chart View
class MiniChartView: NSView {
    private var records: [PriceRecord] = []
    private var highIndex: Int?
    private var lowIndex: Int?
    private var highLabelText: String?
    private var lowLabelText: String?
    private var isUp: Bool = true
    private let padding: CGFloat = 8
    private let dotRadius: CGFloat = 2.5

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: 60)
    }

    func update(with records: [PriceRecord], high: String? = nil, low: String? = nil) {
        self.highLabelText = high
        self.lowLabelText = low
        
        let sortedRecords = records.sorted { $0.timestamp < $1.timestamp }
        
        // Filter out consecutive duplicate prices to compress flat lines
        var filteredRecords: [PriceRecord] = []
        if let first = sortedRecords.first {
            filteredRecords.append(first)
            for i in 1..<sortedRecords.count {
                let current = sortedRecords[i]
                let previous = filteredRecords.last!
                
                // Keep record if price changed, or if it's the last record
                if current.price != previous.price || i == sortedRecords.count - 1 {
                    filteredRecords.append(current)
                }
            }
        }
        
        self.records = filteredRecords
        
        if self.records.count >= 2 {
            let first = self.records.first!.price
            let last = self.records.last!.price
            isUp = last >= first
            
            // Recalculate high/low indices based on filtered records
            let prices = self.records.map { $0.price }
            if let maxPrice = prices.max(), let minPrice = prices.min() {
                highIndex = prices.firstIndex(of: maxPrice)
                lowIndex = prices.firstIndex(of: minPrice)
            }
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard records.count >= 2 else { return }
        
        let prices = records.map { $0.price }
        guard let minPrice = prices.min(), let maxPrice = prices.max() else { return }
        let priceRange = maxPrice - minPrice
        let safeRange = priceRange == 0 ? 1.0 : priceRange
        
        let timeLabelHeight: CGFloat = 14
        let drawRect = NSRect(
            x: bounds.minX + padding,
            y: bounds.minY + timeLabelHeight,
            width: bounds.width - (padding * 2),
            height: bounds.height - timeLabelHeight - padding
        )
        
        let stepX = drawRect.width / CGFloat(records.count - 1)
        
        // Build the line path
        let path = NSBezierPath()
        
        for (i, record) in records.enumerated() {
            let x = drawRect.minX + CGFloat(i) * stepX
            let normalizedY = (record.price - minPrice) / safeRange
            let y = drawRect.minY + CGFloat(normalizedY) * drawRect.height
            let point = NSPoint(x: x, y: y)
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.line(to: point)
            }
        }
        
        // Gradient fill
        NSGraphicsContext.saveGraphicsState()
        let fillPath = path.copy() as! NSBezierPath
        
        // Close the path to form a filled region
        // Extend to bottom of drawRect (not bounds.minY because of padding)
        let lastX = drawRect.minX + CGFloat(records.count - 1) * stepX
        fillPath.line(to: NSPoint(x: lastX, y: drawRect.minY))
        fillPath.line(to: NSPoint(x: drawRect.minX, y: drawRect.minY))
        fillPath.close()
        fillPath.addClip()
        
        let lineColor: NSColor = isUp ? .systemRed : .systemGreen
        if let gradient = NSGradient(
            starting: lineColor.withAlphaComponent(0.18),
            ending: lineColor.withAlphaComponent(0.0)
        ) {
            gradient.draw(in: bounds, angle: 90)
        }
        NSGraphicsContext.restoreGraphicsState()
        
        // Stroke the line
        path.lineWidth = 1.2
        lineColor.setStroke()
        path.stroke()
        
        // Draw dots and labels
        func drawDotAndLabel(at index: Int, color: NSColor, text: String?) {
            let x = drawRect.minX + CGFloat(index) * stepX
            let normalizedY = (records[index].price - minPrice) / safeRange
            let y = drawRect.minY + CGFloat(normalizedY) * drawRect.height
            
            let dotRect = NSRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
            
            // White outline
            let outlinePath = NSBezierPath(ovalIn: dotRect.insetBy(dx: -0.5, dy: -0.5))
            NSColor.white.withAlphaComponent(0.6).setStroke()
            outlinePath.lineWidth = 0.5
            outlinePath.stroke()
            
            // Fill
            let dotPath = NSBezierPath(ovalIn: dotRect)
            color.setFill()
            dotPath.fill()
            
            // Draw Label
            if let labelText = text {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
                let string = NSAttributedString(string: labelText, attributes: attributes)
                let size = string.size()
                
                // Position logic
                // If point is high, draw above? Or if it's near top, draw below?
                // Default: High label above, Low label below.
                // Ensure it stays within bounds.
                
                var labelY = y + 4 // Default above
                
                // If it's the low point, draw below
                if index == lowIndex {
                    labelY = y - size.height - 4
                }
                
                // Adjust X to be centered on point
                var labelX = x - (size.width / 2)
                
                // Clamp X to bounds
                if labelX < bounds.minX + 2 { labelX = bounds.minX + 2 }
                if labelX + size.width > bounds.maxX - 2 { labelX = bounds.maxX - size.width - 2 }
                
                // Clamp Y to bounds
                if labelY < bounds.minY { labelY = y + 4 } // Flip if too low
                if labelY + size.height > bounds.maxY { labelY = y - size.height - 4 } // Flip if too high
                
                string.draw(at: NSPoint(x: labelX, y: labelY))
            }
        }
        
        if let hi = highIndex {
            drawDotAndLabel(at: hi, color: .systemRed, text: highLabelText)
        }
        
        if let li = lowIndex {
            drawDotAndLabel(at: li, color: .systemGreen, text: lowLabelText)
        }
        
        // Draw time axis labels
        let timeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        func drawTimeLabel(text: String, x: CGFloat) {
            let string = NSAttributedString(string: text, attributes: timeAttributes)
            let size = string.size()
            string.draw(at: NSPoint(x: x - size.width / 2, y: bounds.minY + 2))
        }
        
        // Start time (left)
        if let firstRecord = records.first {
            let startTime = formatter.string(from: firstRecord.timestamp)
            drawTimeLabel(text: startTime, x: drawRect.minX)
        }
        
        // End time (right)
        if let lastRecord = records.last {
            let endTime = formatter.string(from: lastRecord.timestamp)
            drawTimeLabel(text: endTime, x: drawRect.maxX)
        }
        
        // Middle time (if span is large enough)
        if records.count >= 4 {
            let midIndex = records.count / 2
            let midRecord = records[midIndex]
            let midTime = formatter.string(from: midRecord.timestamp)
            let midX = drawRect.minX + CGFloat(midIndex) * stepX
            drawTimeLabel(text: midTime, x: midX)
        }
    }
}
