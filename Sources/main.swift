import Cocoa
import Foundation

// MARK: - Data Models
struct PriceInfo {
    var price: String = "--"
    var yesterdayPrice: String = "--"
    var changeRate: String = ""      // 如 "+2.43%"
    var changeAmount: String = ""    // 如 "+26.93"
    var dayHigh: String = "--"       // 当日最高价
    var dayLow: String = "--"        // 当日最低价

    var isUp: Bool {
        if let rate = Double(changeRate.replacingOccurrences(of: "%", with: "").replacingOccurrences(of: "+", with: "")) {
            return rate >= 0
        }
        return changeRate.hasPrefix("+") || (!changeRate.hasPrefix("-") && !changeRate.isEmpty)
    }
}

struct GoldPrices {
    var minsheng = PriceInfo()
    var london = PriceInfo()
    var newyork = PriceInfo()
    var lastUpdate: Date?

    func priceInfo(for key: String) -> PriceInfo {
        switch key {
        case "minsheng": return minsheng
        case "london": return london
        case "newyork": return newyork
        default: return PriceInfo()
        }
    }
}

struct APIResponse: Codable {
    struct ResultData: Codable {
        struct Datas: Codable {
            let price: String?
            let yesterdayPrice: String?
            let upAndDownRate: String?
            let upAndDownAmt: String?
        }
        let datas: Datas?
    }
    let resultData: ResultData?
}

// MARK: - Price History Manager
class PriceHistoryManager {
    static let shared = PriceHistoryManager()

    private let historyKey = "priceHistory"
    private var history: [String: [String: [Double]]] = [:] // [date: [bankKey: [prices]]]

    private init() {
        loadHistory()
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([String: [String: [Double]]].self, from: data) {
            history = decoded
        }
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // 记录价格
    func recordPrice(_ price: Double, for bankKey: String) {
        let today = todayKey()
        if history[today] == nil {
            history[today] = [:]
        }
        if history[today]?[bankKey] == nil {
            history[today]?[bankKey] = []
        }
        history[today]?[bankKey]?.append(price)
        saveHistory()
    }

    // 获取当日最高/最低价
    func getHighLow(for bankKey: String) -> (high: Double?, low: Double?) {
        let today = todayKey()
        guard let prices = history[today]?[bankKey], !prices.isEmpty else {
            return (nil, nil)
        }
        return (prices.max(), prices.min())
    }

    // 清理旧数据（保留最近7天）
    func cleanupOldData() {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        history = history.filter { key, _ in
            guard let date = formatter.date(from: key) else { return false }
            return date >= sevenDaysAgo
        }
        saveHistory()
    }
}

// MARK: - Price Card View
class PriceCardView: NSView {
    private let iconLabel = NSTextField()
    private let nameLabel = NSTextField()
    private let priceLabel = NSTextField()
    private let changeLabel = NSTextField()
    private let highLowLabel = NSTextField()

    private var lastPrice: String = ""
    private var cardStyle: CardStyle = .domestic

    enum CardStyle {
        case domestic   // 金色
        case international  // 蓝色
    }

    init(style: CardStyle) {
        self.cardStyle = style
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 12

        // Set background based on style
        let bgColor: NSColor
        switch cardStyle {
        case .domestic:
            bgColor = NSColor(red: 1.0, green: 0.92, blue: 0.7, alpha: 0.3)  // 暖金色
        case .international:
            bgColor = NSColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.3)  // 冷蓝色
        }
        layer?.backgroundColor = bgColor.cgColor

        // Title row: Icon + Name
        let titleRow = NSStackView()
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 6
        titleRow.translatesAutoresizingMaskIntoConstraints = false

        // Icon
        iconLabel.font = NSFont.systemFont(ofSize: 14)
        iconLabel.backgroundColor = .clear
        iconLabel.isBezeled = false
        iconLabel.isEditable = false
        iconLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleRow.addArrangedSubview(iconLabel)

        // Name
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = NSColor.labelColor
        nameLabel.backgroundColor = .clear
        nameLabel.isBezeled = false
        nameLabel.isEditable = false
        titleRow.addArrangedSubview(nameLabel)

        // Price row: Price | Change
        let priceRow = NSStackView()
        priceRow.orientation = .horizontal
        priceRow.alignment = .centerY
        priceRow.distribution = .fill
        priceRow.spacing = 8
        priceRow.translatesAutoresizingMaskIntoConstraints = false

        // Spacer
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        priceRow.addArrangedSubview(spacer)

        // Price - large, bold
        priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        priceLabel.textColor = NSColor.labelColor
        priceLabel.backgroundColor = .clear
        priceLabel.isBezeled = false
        priceLabel.isEditable = false
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceRow.addArrangedSubview(priceLabel)

        // Change - with background
        changeLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        changeLabel.backgroundColor = .clear
        changeLabel.isBezeled = false
        changeLabel.isEditable = false
        changeLabel.alignment = .center
        changeLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceRow.addArrangedSubview(changeLabel)

        // High/Low row
        highLowLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        highLowLabel.textColor = NSColor.secondaryLabelColor
        highLowLabel.backgroundColor = .clear
        highLowLabel.isBezeled = false
        highLowLabel.isEditable = false
        highLowLabel.alignment = .center

        // Container
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .centerX
        container.spacing = 4
        container.translatesAutoresizingMaskIntoConstraints = false
        container.edgeInsets = NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)

        container.addArrangedSubview(titleRow)
        container.addArrangedSubview(priceRow)
        container.addArrangedSubview(highLowLabel)

        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func update(name: String, icon: String, info: PriceInfo) {
        iconLabel.stringValue = icon
        nameLabel.stringValue = name
        priceLabel.stringValue = info.price

        // Check for price change and trigger flash
        if lastPrice != info.price && !lastPrice.isEmpty {
            flashBackground(isUp: info.isUp)
        }
        lastPrice = info.price

        // Update change label with background color
        if !info.changeRate.isEmpty {
            let arrow = info.isUp ? "↑" : "↓"
            changeLabel.stringValue = " \(arrow)\(info.changeRate) "
            let textColor: NSColor = info.isUp ? .systemRed : .systemGreen
            changeLabel.textColor = textColor
            // Add background
            changeLabel.wantsLayer = true
            changeLabel.layer?.cornerRadius = 4
            changeLabel.layer?.backgroundColor = textColor.withAlphaComponent(0.15).cgColor
        } else {
            changeLabel.stringValue = ""
            changeLabel.layer?.backgroundColor = CGColor.clear
        }

        // Update high/low
        var highLowText = ""
        if info.dayHigh != "--" && info.dayLow != "--" {
            highLowText = "▲\(info.dayHigh)   ▼\(info.dayLow)"
        } else if info.dayHigh != "--" {
            highLowText = "▲\(info.dayHigh)"
        } else if info.dayLow != "--" {
            highLowText = "▼\(info.dayLow)"
        }
        highLowLabel.stringValue = highLowText
    }

    private func flashBackground(isUp: Bool) {
        let flashColor = isUp
            ? NSColor.systemRed.withAlphaComponent(0.2)
            : NSColor.systemGreen.withAlphaComponent(0.2)

        let originalColor = layer?.backgroundColor

        layer?.backgroundColor = flashColor.cgColor

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.allowsImplicitAnimation = true
            layer?.backgroundColor = originalColor
        }
    }
}

// MARK: - International Card View (multiple items)
class InternationalCardView: NSView {
    private let iconLabel = NSTextField()
    private let titleLabel = NSTextField()
    private var priceRows: [(name: String, label: NSTextField, change: NSTextField)] = []

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
        layer?.cornerRadius = 12
        layer?.backgroundColor = NSColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.3).cgColor

        // Title row
        let titleRow = NSStackView()
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 6
        titleRow.translatesAutoresizingMaskIntoConstraints = false

        iconLabel.font = NSFont.systemFont(ofSize: 14)
        iconLabel.stringValue = "🌍"
        iconLabel.backgroundColor = .clear
        iconLabel.isBezeled = false
        iconLabel.isEditable = false
        titleRow.addArrangedSubview(iconLabel)

        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.stringValue = "国际金价"
        titleLabel.textColor = NSColor.labelColor
        titleLabel.backgroundColor = .clear
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleRow.addArrangedSubview(titleLabel)

        // Container
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .centerX
        container.spacing = 6
        container.translatesAutoresizingMaskIntoConstraints = false
        container.edgeInsets = NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)

        container.addArrangedSubview(titleRow)

        // Add price rows
        for (name, _) in [("伦敦金", "london"), ("纽约金", "newyork")] {
            let row = NSStackView()
            row.orientation = .horizontal
            row.alignment = .centerY
            row.distribution = .fill
            row.spacing = 8
            row.translatesAutoresizingMaskIntoConstraints = false

            // Name
            let nameLabel = NSTextField()
            nameLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            nameLabel.stringValue = name
            nameLabel.textColor = NSColor.secondaryLabelColor
            nameLabel.backgroundColor = .clear
            nameLabel.isBezeled = false
            nameLabel.isEditable = false
            nameLabel.setContentHuggingPriority(.required, for: .horizontal)
            row.addArrangedSubview(nameLabel)

            // Spacer
            let spacer = NSView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            row.addArrangedSubview(spacer)

            // Price
            let priceLabel = NSTextField()
            priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 16, weight: .bold)
            priceLabel.textColor = NSColor.labelColor
            priceLabel.backgroundColor = .clear
            priceLabel.isBezeled = false
            priceLabel.isEditable = false
            priceLabel.alignment = .right
            priceLabel.setContentHuggingPriority(.required, for: .horizontal)
            row.addArrangedSubview(priceLabel)

            // Change
            let changeLabel = NSTextField()
            changeLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
            changeLabel.backgroundColor = .clear
            changeLabel.isBezeled = false
            changeLabel.isEditable = false
            changeLabel.alignment = .center
            changeLabel.setContentHuggingPriority(.required, for: .horizontal)
            row.addArrangedSubview(changeLabel)

            container.addArrangedSubview(row)
            priceRows.append((name: name, label: priceLabel, change: changeLabel))
        }

        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func update(london: PriceInfo, newyork: PriceInfo) {
        let data: [(String, PriceInfo)] = [("伦敦金", london), ("纽约金", newyork)]

        for (index, (_, info)) in data.enumerated() {
            guard index < priceRows.count else { continue }
            let row = priceRows[index]

            row.label.stringValue = info.price

            if !info.changeRate.isEmpty {
                let arrow = info.isUp ? "↑" : "↓"
                row.change.stringValue = " \(arrow)\(info.changeRate) "
                let textColor: NSColor = info.isUp ? .systemRed : .systemGreen
                row.change.textColor = textColor
                row.change.wantsLayer = true
                row.change.layer?.cornerRadius = 4
                row.change.layer?.backgroundColor = textColor.withAlphaComponent(0.15).cgColor
            } else {
                row.change.stringValue = ""
                row.change.layer?.backgroundColor = CGColor.clear
            }
        }
    }
}

// MARK: - Gold Price Service
class GoldPriceService {
    static let shared = GoldPriceService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        session = URLSession(configuration: config)
    }

    func fetchAllPrices() async -> GoldPrices {
        var prices = GoldPrices()

        async let minsheng = fetchMinsheng()
        async let international = fetchInternationalGold()

        prices.minsheng = await minsheng

        let intlPrices = await international
        prices.london = intlPrices.london
        prices.newyork = intlPrices.newyork

        prices.lastUpdate = Date()

        // 记录国内金价历史并更新最高/最低价
        updateHighLow(&prices.minsheng, for: "minsheng")

        // 清理旧数据
        PriceHistoryManager.shared.cleanupOldData()

        return prices
    }

    private func updateHighLow(_ info: inout PriceInfo, for bankKey: String) {
        guard let price = Double(info.price), price > 0 else { return }
        PriceHistoryManager.shared.recordPrice(price, for: bankKey)
        let (high, low) = PriceHistoryManager.shared.getHighLow(for: bankKey)
        if let h = high { info.dayHigh = String(format: "%.2f", h) }
        if let l = low { info.dayLow = String(format: "%.2f", l) }
    }

    private func fetchMinsheng() async -> PriceInfo {
        var info = PriceInfo()
        guard let url = URL(string: "https://api.jdjygold.com/gw/generic/hj/h5/m/latestPrice") else { return info }
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(APIResponse.self, from: data)
            if let datas = response.resultData?.datas {
                info.price = datas.price ?? "--"
                info.yesterdayPrice = datas.yesterdayPrice ?? "--"
                info.changeRate = datas.upAndDownRate ?? ""
                info.changeAmount = datas.upAndDownAmt ?? ""
            }
        } catch {
            print("Minsheng fetch error: \(error)")
        }
        return info
    }

    // 获取国际金价（伦敦金、纽约金）
    private func fetchInternationalGold() async -> (london: PriceInfo, newyork: PriceInfo) {
        var london = PriceInfo()
        var newyork = PriceInfo()

        // 使用新浪财经 API
        guard let url = URL(string: "https://hq.sinajs.cn/list=hf_XAU,hf_GC") else {
            print("❌ Invalid URL for international gold")
            return (london, newyork)
        }

        var request = URLRequest(url: url)
        request.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")

        do {
            let (data, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 International gold API status: \(httpResponse.statusCode)")
            }
            // 新浪 API 返回 GB18030 编码，优先尝试，然后 fallback 到 UTF-8/ASCII
            let gb18030 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
            if let text = String(data: data, encoding: gb18030) ?? String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
                print("📦 API response length: \(text.count) chars")
                let lines = text.components(separatedBy: ";")
                for line in lines {
                    if line.contains("hf_XAU") {
                        print("🔍 Parsing XAU (London): \(line.prefix(100))...")
                        london = parseSinaData(line)
                        print("✅ London price: \(london.price)")
                    } else if line.contains("hf_GC") {
                        print("🔍 Parsing GC (NewYork): \(line.prefix(100))...")
                        newyork = parseSinaData(line)
                        print("✅ NewYork price: \(newyork.price)")
                    }
                }
            }
        } catch {
            print("❌ International gold fetch error: \(error)")
        }

        return (london, newyork)
    }

    // 解析新浪数据：当前价,昨收,开盘,当前价2,最高,最低,时间,昨收(备用),...
    // 格式: "5191.60,5141.430,5191.60,5191.90,5210.20,5122.02,16:41:00,5141.43,..."
    private func parseSinaData(_ line: String) -> PriceInfo {
        var info = PriceInfo()
        guard let start = line.firstIndex(of: "\""),
              let end = line.lastIndex(of: "\"") else {
            print("❌ Cannot find quotes in line")
            return info
        }
        let content = String(line[line.index(after: start)..<end])
        let parts = content.components(separatedBy: ",")
        print("📊 Parts count: \(parts.count), first: \(parts.first ?? "nil")")

        // 字段0: 当前价, 字段1: 昨收, 字段4: 最高价, 字段5: 最低价, 字段7: 昨收(备用)
        if parts.count > 7 {
            if let currentPrice = Double(parts[0]) {
                info.price = String(format: "%.2f", currentPrice)

                // 尝试获取昨收价（字段1或字段7）
                var yesterdayPrice: Double? = nil
                if let yp = Double(parts[1]), yp > 0 {
                    yesterdayPrice = yp
                } else if let yp = Double(parts[7]), yp > 0 {
                    yesterdayPrice = yp
                }

                if let yp = yesterdayPrice {
                    info.yesterdayPrice = String(format: "%.2f", yp)
                    let change = currentPrice - yp
                    let changePercent = (change / yp) * 100
                    let sign = change >= 0 ? "+" : ""
                    info.changeAmount = "\(sign)\(String(format: "%.2f", change))"
                    info.changeRate = "\(sign)\(String(format: "%.2f", changePercent))%"
                }

                // 解析最高价（字段4）
                if let high = Double(parts[4]), high > 0 {
                    info.dayHigh = String(format: "%.2f", high)
                }

                // 解析最低价（字段5）
                if let low = Double(parts[5]), low > 0 {
                    info.dayLow = String(format: "%.2f", low)
                }
            }
        }
        return info
    }
}

// MARK: - Floating Window
class FloatingWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 200),
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
        super.init(frame: NSRect(x: 0, y: 0, width: 220, height: 200))
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
        visualEffect.material = .sidebar
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

        // Card container
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .centerX
        container.spacing = 10
        container.translatesAutoresizingMaskIntoConstraints = false
        container.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        // Domestic card (gold)
        domesticCard = PriceCardView(style: .domestic)
        container.addArrangedSubview(domesticCard!)

        // International card (blue)
        internationalCard = InternationalCardView()
        container.addArrangedSubview(internationalCard!)

        visualEffect.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            container.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor)
        ])
    }

    func updatePrices(_ prices: GoldPrices) {
        domesticCard?.update(name: "民生银行积存金", icon: "🪙", info: prices.minsheng)
        internationalCard?.update(london: prices.london, newyork: prices.newyork)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var prices = GoldPrices()
    private var refreshTimer: Timer?
    private var refreshInterval: TimeInterval = 5.0

    // 状态栏显示选项
    private var statusBarPriceKey: String = "minsheng"
    private let priceOptions: [(key: String, name: String)] = [
        ("minsheng", "民生银行"),
        ("london", "伦敦金"),
        ("newyork", "纽约金")
    ]

    // Floating window
    private var floatingWindow: FloatingWindow?
    private var floatingContentView: FloatingContentView?
    private var showFloatingWindowItem: NSMenuItem!

    // Menu items
    private var minshengItem: NSMenuItem!
    private var londonItem: NSMenuItem!
    private var newyorkItem: NSMenuItem!
    private var lastUpdateItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 读取保存的状态栏显示选项
        if let saved = UserDefaults.standard.string(forKey: "statusBarPriceKey") {
            statusBarPriceKey = saved
        }

        setupStatusItem()
        setupMenu()
        setupFloatingWindow()
        startRefreshing()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "金: --"
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        }
    }

    private func setupMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "金价监控", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())

        // Floating window toggle
        showFloatingWindowItem = NSMenuItem(title: "显示悬浮窗", action: #selector(toggleFloatingWindow), keyEquivalent: "f")
        showFloatingWindowItem.target = self
        menu.addItem(showFloatingWindowItem)
        menu.addItem(NSMenuItem.separator())

        // 国内金价
        let domesticHeader = NSMenuItem(title: "── 国内金价 ──", action: nil, keyEquivalent: "")
        domesticHeader.isEnabled = false
        menu.addItem(domesticHeader)

        minshengItem = NSMenuItem(title: "民生银行: --", action: nil, keyEquivalent: "")
        minshengItem.isEnabled = false
        menu.addItem(minshengItem)

        menu.addItem(NSMenuItem.separator())

        // 国际金价
        let intlHeader = NSMenuItem(title: "── 国际金价 ──", action: nil, keyEquivalent: "")
        intlHeader.isEnabled = false
        menu.addItem(intlHeader)

        londonItem = NSMenuItem(title: "伦敦金: --", action: nil, keyEquivalent: "")
        londonItem.isEnabled = false
        menu.addItem(londonItem)

        newyorkItem = NSMenuItem(title: "纽约金: --", action: nil, keyEquivalent: "")
        newyorkItem.isEnabled = false
        menu.addItem(newyorkItem)

        menu.addItem(NSMenuItem.separator())

        lastUpdateItem = NSMenuItem(title: "更新时间: --", action: nil, keyEquivalent: "")
        lastUpdateItem.isEnabled = false
        menu.addItem(lastUpdateItem)

        menu.addItem(NSMenuItem.separator())

        // 状态栏显示选项
        let statusBarItem = NSMenuItem(title: "状态栏显示", action: nil, keyEquivalent: "")
        let statusBarSubmenu = NSMenu()
        for option in priceOptions {
            let item = NSMenuItem(title: option.name, action: #selector(changeStatusBarPrice(_:)), keyEquivalent: "")
            item.representedObject = option.key
            item.target = self
            if option.key == statusBarPriceKey { item.state = .on }
            statusBarSubmenu.addItem(item)
        }
        statusBarItem.submenu = statusBarSubmenu
        menu.addItem(statusBarItem)

        // Refresh interval
        let intervalItem = NSMenuItem(title: "刷新间隔", action: nil, keyEquivalent: "")
        let intervalSubmenu = NSMenu()
        for seconds in [3, 5, 10, 30, 60] {
            let item = NSMenuItem(title: "\(seconds)秒", action: #selector(changeInterval(_:)), keyEquivalent: "")
            item.tag = seconds
            item.target = self
            if TimeInterval(seconds) == refreshInterval { item.state = .on }
            intervalSubmenu.addItem(item)
        }
        intervalItem.submenu = intervalSubmenu
        menu.addItem(intervalItem)

        let refreshItem = NSMenuItem(title: "立即刷新", action: #selector(manualRefresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let updateItem = NSMenuItem(title: "检查更新", action: #selector(checkForUpdate), keyEquivalent: "u")
        updateItem.target = self
        menu.addItem(updateItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func setupFloatingWindow() {
        floatingWindow = FloatingWindow()
        floatingContentView = FloatingContentView()
        floatingWindow?.contentView = floatingContentView
        floatingWindow?.positionAtTopRight()
    }

    private func startRefreshing() {
        Task { await refreshPrices() }
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { await self?.refreshPrices() }
        }
    }

    @MainActor
    private func refreshPrices() async {
        prices = await GoldPriceService.shared.fetchAllPrices()
        updateUI()
    }

    @MainActor
    private func updateUI() {
        // Status bar - 只显示价格，不显示涨跌
        if let button = statusItem.button {
            let info = prices.priceInfo(for: statusBarPriceKey)
            button.title = "金: \(info.price)"
        }

        // Menu items - 国内
        minshengItem.title = formatMenuItemWithHighLow(name: "民生银行", info: prices.minsheng, unit: "元/克")

        // Menu items - 国际
        londonItem.title = formatMenuItemWithHighLow(name: "伦敦金", info: prices.london, unit: "$/oz")
        newyorkItem.title = formatMenuItemWithHighLow(name: "纽约金", info: prices.newyork, unit: "$/oz")

        if let lastUpdate = prices.lastUpdate {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            lastUpdateItem.title = "更新时间: \(formatter.string(from: lastUpdate))"
        }

        // Floating window
        floatingContentView?.updatePrices(prices)
    }

    private func formatMenuItemWithHighLow(name: String, info: PriceInfo, unit: String) -> String {
        var text = "\(name): \(info.price) \(unit)"
        if !info.changeRate.isEmpty {
            let arrow = info.isUp ? "📈" : "📉"
            text += " \(arrow)\(info.changeRate)"
        }
        // 添加最高/最低价
        if info.dayHigh != "--" && info.dayLow != "--" {
            text += " [\(info.dayLow)~\(info.dayHigh)]"
        }
        return text
    }

    @objc private func toggleFloatingWindow() {
        if floatingWindow?.isVisible == true {
            floatingWindow?.orderOut(nil)
            showFloatingWindowItem.title = "显示悬浮窗"
        } else {
            floatingWindow?.orderFront(nil)
            showFloatingWindowItem.title = "隐藏悬浮窗"
        }
    }

    @MainActor @objc private func changeStatusBarPrice(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }

        // 更新选中状态
        if let submenu = sender.menu {
            for item in submenu.items { item.state = .off }
        }
        sender.state = .on

        // 保存选项
        statusBarPriceKey = key
        UserDefaults.standard.set(key, forKey: "statusBarPriceKey")

        // 更新显示
        updateUI()
    }

    @objc private func changeInterval(_ sender: NSMenuItem) {
        if let submenu = sender.menu {
            for item in submenu.items { item.state = .off }
        }
        sender.state = .on
        refreshInterval = TimeInterval(sender.tag)
        startRefreshing()
    }

    @objc private func manualRefresh() {
        Task { await refreshPrices() }
    }

    @objc private func checkForUpdate() {
        Task { await performUpdateCheck() }
    }

    @MainActor
    private func performUpdateCheck() async {
        let currentVersion = "1.5.0"
        let repoURL = "https://api.github.com/repos/PiaoyangGuohai1/GoldPrice/releases/latest"

        guard let url = URL(string: repoURL) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tagName = json["tag_name"] as? String {
                let latestVersion = tagName.replacingOccurrences(of: "v", with: "")

                if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                    let alert = NSAlert()
                    alert.messageText = "发现新版本"
                    alert.informativeText = "当前版本: v\(currentVersion)\n最新版本: v\(latestVersion)\n\n是否前往下载？"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "前往下载")
                    alert.addButton(withTitle: "稍后再说")

                    if alert.runModal() == .alertFirstButtonReturn {
                        if let downloadURL = URL(string: "https://github.com/PiaoyangGuohai1/GoldPrice/releases/latest") {
                            NSWorkspace.shared.open(downloadURL)
                        }
                    }
                } else {
                    let alert = NSAlert()
                    alert.messageText = "已是最新版本"
                    alert.informativeText = "当前版本 v\(currentVersion) 已是最新。"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "好")
                    alert.runModal()
                }
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "检查更新失败"
            alert.informativeText = "无法连接到服务器，请稍后再试。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "好")
            alert.runModal()
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
