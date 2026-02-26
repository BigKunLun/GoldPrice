import Cocoa
import Foundation

// MARK: - Mini Chart View
class MiniChartView: NSView {
    private var records: [PriceRecord] = []
    private var highIndex: Int?
    private var lowIndex: Int?
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

    func update(with records: [PriceRecord]) {
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
        
        let drawRect = bounds.insetBy(dx: padding, dy: padding)
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
            gradient.draw(in: bounds, angle: 90) // 90 is bottom to top? No, usually 270 or -90 for top to bottom.
            // Let's stick to standard angle. 90 is vertical.
            // Actually, in Cocoa, 90 is vertical up.
        }
        NSGraphicsContext.restoreGraphicsState()
        
        // Stroke the line
        path.lineWidth = 1.2
        lineColor.setStroke()
        path.stroke()
        
        // Draw dots
        func drawDot(at index: Int, color: NSColor) {
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
        }
        
        if let hi = highIndex {
            drawDot(at: hi, color: .systemRed)
        }
        
        if let li = lowIndex {
            drawDot(at: li, color: .systemGreen)
        }
    }
}
