# 金价历史记录与银行更新 实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 添加当日最高/最低价显示功能，并将工商银行和浙商银行替换为招商银行

**Architecture:**
1. 新增 `PriceHistoryManager` 单例类，负责本地存储和查询当日价格历史，使用 UserDefaults 或 JSON 文件存储
2. 修改 `PriceInfo` 增加 `dayHigh` 和 `dayLow` 字段
3. 替换银行数据源：删除 ICBC 和浙商银行相关代码，添加招商银行 API

**Tech Stack:** Swift 5.9, AppKit, UserDefaults (JSON 编码)

---

## Task 1: 扩展 PriceInfo 数据模型

**Files:**
- Modify: `Sources/main.swift:5-17`

**Step 1: 修改 PriceInfo 结构体**

在 `PriceInfo` 结构体中添加最高价和最低价字段：

```swift
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
```

**Step 2: 验证编译**

Run: `cd /Users/shijianing/CodingTime/GoldPrice && swiftc -parse Sources/main.swift 2>&1 || echo "Parse check done"`
Expected: 无错误输出

**Step 3: Commit**

```bash
git add Sources/main.swift
git commit -m "feat: add dayHigh and dayLow fields to PriceInfo"
```

---

## Task 2: 创建价格历史管理器

**Files:**
- Modify: `Sources/main.swift` (在 GoldPriceService 之前插入)

**Step 1: 添加 PriceHistoryManager 类**

在 `// MARK: - Gold Price Service` 注释之前，添加新的类：

```swift
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
```

**Step 2: 验证编译**

Run: `cd /Users/shijianing/CodingTime/GoldPrice && swiftc -parse Sources/main.swift 2>&1 || echo "Parse check done"`
Expected: 无错误输出

**Step 3: Commit**

```bash
git add Sources/main.swift
git commit -m "feat: add PriceHistoryManager for tracking daily high/low prices"
```

---

## Task 3: 修改 GoldPrices 数据结构

**Files:**
- Modify: `Sources/main.swift:19-37`

**Step 1: 替换银行字段**

将 `icbc` 改为 `zhaoShang`，删除 `zheshang`：

```swift
struct GoldPrices {
    var minsheng = PriceInfo()
    var zhaoShang = PriceInfo()  // 招商银行，替换原 icbc
    var london = PriceInfo()
    var newyork = PriceInfo()
    var lastUpdate: Date?

    func priceInfo(for key: String) -> PriceInfo {
        switch key {
        case "minsheng": return minsheng
        case "zhaoShang": return zhaoShang
        case "london": return london
        case "newyork": return newyork
        default: return PriceInfo()
        }
    }
}
```

**Step 2: 验证编译**

Run: `cd /Users/shijianing/CodingTime/GoldPrice && swiftc -parse Sources/main.swift 2>&1 || echo "Parse check done"`
Expected: 会有编译错误（因为其他代码还在引用旧字段），继续下一步

**Step 3: Commit**

```bash
git add Sources/main.swift
git commit -m "refactor: replace icbc/zheshang with zhaoShang in GoldPrices"
```

---

## Task 4: 更新 GoldPriceService

**Files:**
- Modify: `Sources/main.swift:65-146`

**Step 1: 修改 fetchAllPrices 方法**

更新并发获取逻辑，并记录价格历史：

```swift
func fetchAllPrices() async -> GoldPrices {
    var prices = GoldPrices()

    async let minsheng = fetchMinsheng()
    async let zhaoShang = fetchZhaoShang()
    async let international = fetchInternationalGold()

    prices.minsheng = await minsheng
    prices.zhaoShang = await zhaoShang

    let intlPrices = await international
    prices.london = intlPrices.london
    prices.newyork = intlPrices.newyork

    prices.lastUpdate = Date()

    // 记录价格并更新最高/最低价
    updateHighLow(&prices.minsheng, for: "minsheng")
    updateHighLow(&prices.zhaoShang, for: "zhaoShang")
    updateHighLow(&prices.london, for: "london")
    updateHighLow(&prices.newyork, for: "newyork")

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
```

**Step 2: 删除 fetchICBC 和 fetchZheshang，添加 fetchZhaoShang**

删除 `fetchICBC()` 和 `fetchZheshang()` 方法，添加招商银行获取方法：

```swift
private func fetchZhaoShang() async -> PriceInfo {
    var info = PriceInfo()
    // 招商银行积存金 API（京东金融平台）
    guard let url = URL(string: "https://api.jdjygold.com/gw2/generic/jrm/h5/m/cmbLatestPrice?productSku=100035724563") else { return info }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONEncoder().encode(["reqData": ["productSku": "100035724563"]])
    do {
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(APIResponse.self, from: data)
        if let datas = response.resultData?.datas {
            info.price = datas.price ?? "--"
            info.yesterdayPrice = datas.yesterdayPrice ?? "--"
            info.changeRate = datas.upAndDownRate ?? ""
            info.changeAmount = datas.upAndDownAmt ?? ""
        }
    } catch {
        print("ZhaoShang fetch error: \(error)")
    }
    return info
}
```

**Step 3: 验证编译**

Run: `cd /Users/shijianing/CodingTime/GoldPrice && swiftc -parse Sources/main.swift 2>&1 || echo "Parse check done"`
Expected: 仍有错误（UI 部分引用旧字段），继续

**Step 4: Commit**

```bash
git add Sources/main.swift
git commit -m "feat: add fetchZhaoShang and price history recording"
```

---

## Task 5: 更新 FloatingContentView UI

**Files:**
- Modify: `Sources/main.swift:244-374`

**Step 1: 修改 setupUI 中的银行列表**

将银行行改为民生银行和招商银行，并添加最高/最低价显示：

```swift
private func setupUI() {
    wantsLayer = true
    layer?.cornerRadius = 12
    layer?.backgroundColor = NSColor(white: 0.1, alpha: 0.85).cgColor

    let container = NSStackView()
    container.orientation = .vertical
    container.alignment = .leading
    container.spacing = 4
    container.translatesAutoresizingMaskIntoConstraints = false
    container.edgeInsets = NSEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)

    // Title - 国内金价
    let domesticTitle = createLabel("国内金价 (元/克)", size: 11, bold: true, color: .white)
    container.addArrangedSubview(domesticTitle)

    // 国内价格 - 带最高/最低价
    addPriceRowWithHighLow(to: container, key: "minsheng", name: "民生银行")
    addPriceRowWithHighLow(to: container, key: "zhaoShang", name: "招商银行")

    // Separator
    let sep = NSBox()
    sep.boxType = .separator
    sep.translatesAutoresizingMaskIntoConstraints = false
    container.addArrangedSubview(sep)
    sep.widthAnchor.constraint(equalToConstant: 200).isActive = true

    // Title - 国际金价
    let intlTitle = createLabel("国际金价 (美元/盎司)", size: 11, bold: true, color: .white)
    container.addArrangedSubview(intlTitle)

    // 国际价格
    addPriceRow(to: container, key: "london", name: "伦敦金　")
    addPriceRow(to: container, key: "newyork", name: "纽约金　")

    // Time
    timeLabel = createLabel("--:--:--", size: 10, bold: false, color: NSColor.lightGray)
    container.addArrangedSubview(timeLabel)

    addSubview(container)
    NSLayoutConstraint.activate([
        container.topAnchor.constraint(equalTo: topAnchor),
        container.bottomAnchor.constraint(equalTo: bottomAnchor),
        container.leadingAnchor.constraint(equalTo: leadingAnchor),
        container.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])
}
```

**Step 2: 添加新的 addPriceRowWithHighLow 方法**

在 `addPriceRow` 方法后添加：

```swift
private func addPriceRowWithHighLow(to stack: NSStackView, key: String, name: String) {
    let row = NSStackView()
    row.orientation = .vertical
    row.spacing = 2

    // 主行：名称 + 价格 + 涨跌
    let mainRow = NSStackView()
    mainRow.orientation = .horizontal
    mainRow.distribution = .fill
    mainRow.spacing = 8

    let nameLabel = createLabel(name, size: 11, bold: false, color: NSColor.lightGray)
    nameLabel.setContentHuggingPriority(.required, for: .horizontal)

    let priceLabel = createLabel("----", size: 12, bold: true, color: NSColor.systemYellow)
    priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
    priceLabel.alignment = .right
    priceLabels[key] = priceLabel

    let changeLabel = createLabel("", size: 10, bold: false, color: NSColor.systemRed)
    changeLabel.setContentHuggingPriority(.required, for: .horizontal)
    changeLabels[key] = changeLabel

    mainRow.addArrangedSubview(nameLabel)
    mainRow.addArrangedSubview(priceLabel)
    mainRow.addArrangedSubview(changeLabel)

    // 次行：最高/最低价
    let subRow = NSStackView()
    subRow.orientation = .horizontal
    subRow.spacing = 12

    let spacer = createLabel("    ", size: 10, bold: false, color: .clear)
    let highLabel = createLabel("高 --", size: 9, bold: false, color: NSColor.systemRed.withAlphaComponent(0.8))
    let lowLabel = createLabel("低 --", size: 9, bold: false, color: NSColor.systemGreen.withAlphaComponent(0.8))

    highLabels[key] = highLabel
    lowLabels[key] = lowLabel

    subRow.addArrangedSubview(spacer)
    subRow.addArrangedSubview(highLabel)
    subRow.addArrangedSubview(lowLabel)

    row.addArrangedSubview(mainRow)
    row.addArrangedSubview(subRow)

    row.translatesAutoresizingMaskIntoConstraints = false
    row.widthAnchor.constraint(equalToConstant: 200).isActive = true

    stack.addArrangedSubview(row)
}
```

**Step 3: 添加 highLabels 和 lowLabels 字典**

在 `FloatingContentView` 类中添加新的属性：

```swift
private var highLabels: [String: NSTextField] = [:]
private var lowLabels: [String: NSTextField] = [:]
```

**Step 4: 更新 updatePrices 方法**

```swift
func updatePrices(_ prices: GoldPrices) {
    self.prices = prices

    updatePriceDisplayWithHighLow(key: "minsheng", info: prices.minsheng)
    updatePriceDisplayWithHighLow(key: "zhaoShang", info: prices.zhaoShang)
    updatePriceDisplay(key: "london", info: prices.london)
    updatePriceDisplay(key: "newyork", info: prices.newyork)

    if let lastUpdate = prices.lastUpdate {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        timeLabel.stringValue = "更新: " + formatter.string(from: lastUpdate)
    }
}
```

**Step 5: 添加 updatePriceDisplayWithHighLow 方法**

```swift
private func updatePriceDisplayWithHighLow(key: String, info: PriceInfo) {
    updatePriceDisplay(key: key, info: info)

    // 更新最高/最低价
    if let highLabel = highLabels[key] {
        if info.dayHigh != "--" {
            highLabel.stringValue = "高 \(info.dayHigh)"
        } else {
            highLabel.stringValue = "高 --"
        }
    }
    if let lowLabel = lowLabels[key] {
        if info.dayLow != "--" {
            lowLabel.stringValue = "低 \(info.dayLow)"
        } else {
            lowLabel.stringValue = "低 --"
        }
    }
}
```

**Step 6: 验证编译**

Run: `cd /Users/shijianing/CodingTime/GoldPrice && swiftc -parse Sources/main.swift 2>&1 || echo "Parse check done"`
Expected: 仍有错误（AppDelegate 部分引用旧字段），继续

**Step 7: Commit**

```bash
git add Sources/main.swift
git commit -m "feat: update FloatingContentView with high/low price display"
```

---

## Task 6: 更新 AppDelegate 菜单和状态栏

**Files:**
- Modify: `Sources/main.swift:377-680`

**Step 1: 更新 priceOptions 数组**

```swift
private let priceOptions: [(key: String, name: String)] = [
    ("minsheng", "民生银行"),
    ("zhaoShang", "招商银行"),
    ("london", "伦敦金"),
    ("newyork", "纽约金")
]
```

**Step 2: 更新菜单项属性**

```swift
// Menu items
private var minshengItem: NSMenuItem!
private var zhaoShangItem: NSMenuItem!
private var londonItem: NSMenuItem!
private var newyorkItem: NSMenuItem!
private var lastUpdateItem: NSMenuItem!
```

**Step 3: 更新 setupMenu 方法中的银行菜单项**

```swift
// 国内金价
let domesticHeader = NSMenuItem(title: "── 国内金价 ──", action: nil, keyEquivalent: "")
domesticHeader.isEnabled = false
menu.addItem(domesticHeader)

minshengItem = NSMenuItem(title: "民生银行: --", action: nil, keyEquivalent: "")
minshengItem.isEnabled = false
menu.addItem(minshengItem)

zhaoShangItem = NSMenuItem(title: "招商银行: --", action: nil, keyEquivalent: "")
zhaoShangItem.isEnabled = false
menu.addItem(zhaoShangItem)
```

**Step 4: 更新 updateUI 方法**

```swift
@MainActor
private func updateUI() {
    // Status bar - 只显示价格，不显示涨跌
    if let button = statusItem.button {
        let info = prices.priceInfo(for: statusBarPriceKey)
        button.title = "金: \(info.price)"
    }

    // Menu items - 国内
    minshengItem.title = formatMenuItemWithHighLow(name: "民生银行", info: prices.minsheng, unit: "元/克")
    zhaoShangItem.title = formatMenuItemWithHighLow(name: "招商银行", info: prices.zhaoShang, unit: "元/克")

    // Menu items - 国际
    londonItem.title = formatMenuItem(name: "伦敦金", info: prices.london, unit: "$/oz")
    newyorkItem.title = formatMenuItem(name: "纽约金", info: prices.newyork, unit: "$/oz")

    if let lastUpdate = prices.lastUpdate {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        lastUpdateItem.title = "更新时间: \(formatter.string(from: lastUpdate))"
    }

    // Floating window
    floatingContentView?.updatePrices(prices)
}
```

**Step 5: 添加 formatMenuItemWithHighLow 方法**

```swift
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
```

**Step 6: 验证编译**

Run: `cd /Users/shijianing/CodingTime/GoldPrice && swiftc -parse Sources/main.swift 2>&1 || echo "Parse check done"`
Expected: 无错误

**Step 7: Commit**

```bash
git add Sources/main.swift
git commit -m "feat: update AppDelegate menu with zhaoShang and high/low prices"
```

---

## Task 7: 调整悬浮窗尺寸

**Files:**
- Modify: `Sources/main.swift:523-529`

**Step 1: 更新悬浮窗尺寸**

由于增加了最高/最低价显示，需要增加悬浮窗高度：

```swift
private func setupFloatingWindow() {
    floatingWindow = FloatingWindow()
    floatingContentView = FloatingContentView(frame: NSRect(x: 0, y: 0, width: 224, height: 220))
    floatingWindow?.contentView = floatingContentView
    floatingWindow?.setContentSize(NSSize(width: 224, height: 220))
    floatingWindow?.positionAtTopRight()
}
```

**Step 2: 验证编译**

Run: `cd /Users/shijianing/CodingTime/GoldPrice && swiftc -parse Sources/main.swift 2>&1 || echo "Parse check done"`
Expected: 无错误

**Step 3: Commit**

```bash
git add Sources/main.swift
git commit -m "chore: adjust floating window size for high/low display"
```

---

## Task 8: 构建并测试

**Files:**
- N/A

**Step 1: 构建应用**

Run: `cd /Users/shijianing/CodingTime/GoldPrice && ./build.sh`
Expected: 构建成功，生成 JDGold.app

**Step 2: 运行应用进行手动测试**

Run: `open /Users/shijianing/CodingTime/GoldPrice/JDGold.app`
Expected: 应用启动，菜单栏显示金价，悬浮窗显示最高/最低价

**Step 3: 验证功能**

手动验证：
1. 招商银行价格是否正常获取
2. 最高/最低价是否正确记录和显示
3. 第二天启动时旧数据是否被清理

**Step 4: Commit**

```bash
git add -A
git commit -m "build: v1.5.0 with price history and zhaoShang bank"
```

---

## Task 9: 更新版本号

**Files:**
- Modify: `Info.plist`
- Modify: `Sources/main.swift:627`

**Step 1: 更新 Info.plist 版本号**

更新 `CFBundleShortVersionString` 为 `1.5.0`，`CFBundleVersion` 为 `5`

**Step 2: 更新代码中的版本号**

在 `performUpdateCheck` 方法中将 `currentVersion` 改为 `"1.5.0"`

**Step 3: Commit**

```bash
git add Info.plist Sources/main.swift
git commit -m "chore: bump version to 1.5.0"
```

---

## 最终验证

运行完整构建流程：

```bash
cd /Users/shijianing/CodingTime/GoldPrice
./build.sh
open JDGold.app
```

确认：
- [ ] 民生银行价格正常显示
- [ ] 招商银行价格正常显示
- [ ] 伦敦金、纽约金价格正常显示
- [ ] 最高/最低价正确记录（运行一段时间后刷新验证）
- [ ] 菜单栏显示正确
- [ ] 悬浮窗显示正确
