import Cocoa
import Foundation

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
        // Status bar - 显示价格和涨跌幅
        if let button = statusItem.button {
            let info = prices.priceInfo(for: statusBarPriceKey)
            var title = "金: \(info.price)"
            if !info.changeRate.isEmpty {
                title += " \(info.changeRate)"
            }
            button.title = title
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
