# GoldPrice - macOS 黄金价格监控应用

## 项目概述

一个极简的 macOS 菜单栏应用，实时监控国内外黄金价格。

- **应用名称**：GoldPrice
- **Bundle ID**：com.goldprice.monitor
- **版本**：2.0.0 (Build 2)
- **类型**：macOS 原生菜单栏应用（LSUIElement，无 Dock 图标）
- **语言**：Swift 5.9
- **框架**：AppKit (Cocoa) — 无第三方依赖
- **最低系统要求**：macOS 12.0+

## 常用命令

```bash
# 构建（生成 JDGold.app bundle）
./build.sh

# 运行
open JDGold.app

# 手动编译（调试用）
swiftc -O -o JDGold.app/Contents/MacOS/JDGold $(find Sources -name "*.swift") -framework Cocoa
```

## 目录结构

```
GoldPrice/
├── Sources/                          # Swift 源代码
│   ├── main.swift                    # 应用入口（约10行）
│   ├── App/
│   │   └── AppDelegate.swift         # 主应用逻辑（294行）
│   ├── Models/
│   │   └── PriceModels.swift         # 数据模型（54行）
│   ├── Services/
│   │   ├── GoldPriceService.swift    # API 请求服务（156行）
│   │   └── PriceHistoryManager.swift # 历史数据管理（55行）
│   ├── Views/
│   │   ├── PriceCardView.swift       # 国内金价卡片（154行）
│   │   ├── InternationalCardView.swift # 国际金价卡片（149行）
│   │   └── MiniChartView.swift       # 迷你走势图（84行）
│   └── UI/
│       └── FloatingWindow.swift      # 悬浮窗（101行）
├── Resources/
│   ├── AppIcon.icns                  # 编译后图标
│   └── AppIcon.iconset/              # 多分辨率图标集
├── JDGold.app/                       # 已构建的应用包（不提交）
├── Info.plist                        # 应用配置清单
├── Package.swift                     # Swift Package 配置（macOS 12+）
├── build.sh                          # 构建脚本
├── README.md                         # 用户文档
└── CLAUDE.md                         # 本文件
```

## 架构概览

### 模块划分

| 模块 | 文件 | 职责 |
|------|------|------|
| **App** | `AppDelegate.swift` | 应用生命周期、菜单栏管理、自动刷新调度 |
| **Models** | `PriceModels.swift` | 数据结构定义（PriceInfo, GoldPrices, APIResponse, PriceRecord） |
| **Services** | `GoldPriceService.swift` | API 请求、响应解析、高低价更新 |
| **Services** | `PriceHistoryManager.swift` | 24小时价格历史、持久化、高低价计算 |
| **Views** | `PriceCardView.swift` | 国内金价展示卡片（含迷你图） |
| **Views** | `InternationalCardView.swift` | 国际金价双行展示（伦敦金 + 纽约金） |
| **Views** | `MiniChartView.swift` | 24小时走势折线图 |
| **UI** | `FloatingWindow.swift` | 悬浮窗（NSWindow子类 + FloatingContentView） |

### 数据流

```
AppDelegate.refreshPrices()
  └─ GoldPriceService.fetchAllPrices()        [async/await 并发]
       ├─ fetchMinsheng()  →  京东 API         [国内民生银行积存金]
       └─ fetchInternationalGold()  →  新浪 API  [伦敦金 + 纽约金]
            └─ parseSinaData()                  [处理 GB18030 编码]
  └─ PriceHistoryManager.recordPrice()        [记录历史]
  └─ PriceHistoryManager.updateHighLow()      [更新日内高低]
  └─ AppDelegate.updateUI()                   [刷新状态栏 + 菜单]
  └─ FloatingContentView.update()             [刷新悬浮窗]
```

## 数据来源

### 国内金价（京东金融 API）

> **注意**：v1.5.0 起仅保留民生银行，工商银行和浙商银行已移除。

- **民生银行积存金**：`https://api.jdjygold.com/gw/generic/hj/h5/m/latestPrice`
- 响应格式：JSON，通过 `APIResponse` 解码
  ```json
  { "resultData": { "datas": { "price": "...", "yesterdayPrice": "...", "upAndDownRate": "...", "upAndDownAmt": "..." } } }
  ```

### 国际金价（新浪财经 API）

- **请求 URL**：`https://hq.sinajs.cn/list=hf_XAU,hf_GC`
- **必须设置** Referer 请求头：`https://finance.sina.com.cn`
- **编码处理**：优先 GB18030，回退 UTF-8，再回退 ASCII
- **响应格式**：分号分隔行，每行为引号内逗号分隔字段
  - 字段 0：当前价格
  - 字段 1：昨收价
  - 字段 2：开盘价
  - 字段 4：日内最高价
  - 字段 5：日内最低价
- 涨跌幅和涨跌额由代码计算得出

## 核心数据模型（PriceModels.swift）

```swift
struct PriceInfo {
    var price: String          // 当前价格字符串
    var yesterdayPrice: String // 昨收价
    var changeRate: String     // 涨跌幅，如 "+2.43%"
    var changeAmount: String   // 涨跌额，如 "+26.93"
    var dayHigh: Double        // 日内最高（24h滑动窗口）
    var dayLow: Double         // 日内最低（24h滑动窗口）
    var isUp: Bool             // 计算属性：涨跌方向
}

struct GoldPrices {
    var minsheng: PriceInfo    // 民生银行积存金
    var london: PriceInfo      // 伦敦金（XAU/USD）
    var newyork: PriceInfo     // 纽约金（COMEX GC）
    var lastUpdate: Date?      // 最后更新时间
    func priceInfo(for key: String) -> PriceInfo?  // 按 key 查询
}
```

## 用户偏好设置（UserDefaults）

| Key | 类型 | 默认值 | 说明 |
|-----|------|--------|------|
| `refreshInterval` | Int | 10 | 自动刷新间隔（秒），可选值：3/5/10/30/60 |
| `selectedPriceKey` | String | "minsheng" | 状态栏显示的价格来源（"minsheng"/"london"/"newyork"） |
| `floatingWindowVisible` | Bool | false | 悬浮窗是否显示 |
| `priceHistoryV2` | Data | — | 24小时价格历史数据（JSON编码的 [String:[PriceRecord]]） |

## 菜单栏与快捷键

| 快捷键 | 功能 |
|--------|------|
| ⌘F | 切换悬浮窗显示/隐藏 |
| ⌘R | 立即刷新价格 |
| ⌘U | 检查更新（访问 GitHub Releases API） |
| ⌘Q | 退出应用 |

## UI 设计规范

- **涨跌颜色**：涨红（red）跌绿（green），符合中国股市习惯
- **视觉效果**：`NSVisualEffectView`，材质 `hudWindow`，圆角背景
- **悬浮窗尺寸**：260 × 240 pt，默认定位右上角（距屏幕边缘 20pt）
- **悬浮窗行为**：`NSWindowCollectionBehavior.stationary`，在所有 Space 显示，不激活应用
- **图标系统**：SF Symbols（yensign.circle、dollarsign.circle、globe、arrow.up/down）
- **价格变化动画**：0.4秒背景闪烁动画（`flashBackground()`）
- **迷你图**：35pt 高度，红点标日高，绿点标日低

## 关键方法速查

| 搜索关键词 | 位置 | 功能 |
|-----------|------|------|
| `updateStatusBarTitle` | AppDelegate | 更新状态栏文字 |
| `startAutoRefresh` | AppDelegate | 启动定时刷新 |
| `refreshPrices` | AppDelegate | 触发价格刷新（async） |
| `setupMenu` | AppDelegate | 构建下拉菜单 |
| `formatMenuItemAttributed` | AppDelegate | 带高低价的菜单项格式化 |
| `performUpdateCheck` | AppDelegate | GitHub 版本检查 |
| `fetchMinsheng` | GoldPriceService | 获取国内金价 |
| `fetchInternationalGold` | GoldPriceService | 获取国际金价 |
| `parseSinaData` | GoldPriceService | 解析新浪财经响应 |
| `getHighLow` | PriceHistoryManager | 获取24小时高低价 |
| `cleanupOldData` | PriceHistoryManager | 清理过期历史数据 |
| `flashBackground` | PriceCardView | 价格变化闪烁动画 |
| `positionAtTopRight` | FloatingWindow | 窗口定位右上角 |

## 开发注意事项

1. **并发**：`fetchAllPrices()` 使用 `async/await` 并发请求国内和国际两路 API，均通过 `async let` 并行执行
2. **编码**：新浪 API 响应为 GB18030 编码，代码有三级回退处理
3. **调试日志**：`GoldPriceService` 包含大量 emoji 标记的 `print()` 调试输出（🌐、✅、❌、📊 等）
4. **内存管理**：闭包中使用 `[weak self]` 避免循环引用
5. **线程安全**：UI 更新通过 `DispatchQueue.main.async` 回到主线程
6. **历史数据**：`PriceHistoryManager` 维护24小时滑动窗口，每次 `fetchAllPrices()` 后自动清理旧数据
7. **网络配置**：URLSession 超时设置为 10s（请求）/ 15s（资源），`Info.plist` 设置 `NSAllowsArbitraryLoads: true`
8. **Package.swift**：仅用于 IDE 支持，实际构建通过 `build.sh` 脚本调用 `swiftc` 完成

## 版本历史摘要

| 版本 | 变更 |
|------|------|
| 2.0.0 | 版本号动态读取、刷新间隔持久化、isUp 逻辑简化 |
| 1.5.0 | 添加日内高低价，移除工商银行/浙商银行 |
| 1.4.0 | 精确涨跌计算，UI 优化 |
| 1.3.0 | 可自定义状态栏显示内容 |
| 模块化重构 | 单文件拆分为 App/Models/Services/Views/UI 模块 |
