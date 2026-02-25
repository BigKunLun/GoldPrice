# JDGold - macOS 黄金价格监控应用

## 项目概述

一个极简的 macOS 菜单栏应用，实时监控国内外黄金价格。

- **类型**：macOS 原生菜单栏应用
- **语言**：Swift 5.9
- **框架**：AppKit (Cocoa)
- **特点**：单文件架构，无第三方依赖，约 570 行代码
- **最低系统要求**：macOS 12.0+

## 常用命令

```bash
# 构建
./build.sh

# 运行
open JDGold.app

# 手动编译（调试用）
swiftc -O -o JDGold.app/Contents/MacOS/JDGold Sources/main.swift -framework Cocoa
```

## 架构概览

### 单文件架构 (`Sources/main.swift`)

所有代码都在一个文件中，按 MARK 注释分隔：

```
┌─────────────────────────────────────────────────────────┐
│ Data Models                                             │
│ - PriceInfo: 单个金价数据（价格、涨跌幅、涨跌额）          │
│ - GoldPrices: 所有金价集合                               │
│ - APIResponse: API 响应解析                              │
├─────────────────────────────────────────────────────────┤
│ GoldPriceService (Singleton)                            │
│ - fetchAllPrices(): 并发获取所有价格                      │
│ - fetchMinsheng/fetchICBC/fetchZheshang: 国内金价        │
│ - fetchInternationalGold: 国际金价（伦敦金、纽约金）       │
├─────────────────────────────────────────────────────────┤
│ UI Components                                           │
│ - FloatingWindow: 悬浮窗口（可拖拽、始终置顶）             │
│ - FloatingContentView: 悬浮窗内容视图                     │
├─────────────────────────────────────────────────────────┤
│ AppDelegate                                             │
│ - 菜单栏图标管理                                         │
│ - 下拉菜单构建                                           │
│ - 定时刷新逻辑                                           │
│ - 用户偏好存储 (UserDefaults)                            │
└─────────────────────────────────────────────────────────┘
```

### 主要组件

| 组件 | 职责 |
|------|------|
| `PriceInfo` | 数据模型：价格、昨收价、涨跌幅、涨跌额 |
| `GoldPrices` | 聚合所有金价数据 |
| `GoldPriceService` | 单例服务，负责 API 请求和数据处理 |
| `FloatingWindow` | 悬浮窗口 NSWindow 子类 |
| `FloatingContentView` | 悬浮窗内容视图 NSView 子类 |
| `AppDelegate` | 主应用逻辑，菜单栏管理 |

## 数据来源

### 国内金价（京东金融 API）

- 民生银行积存金：`api.jdjygold.com/gw/generic/hj/h5/m/latestPrice`
- 工商银行积存金：`api.jdjygold.com/gw/generic/icbc/h5/m/latestPrice`
- 浙商银行积存金：`api.jdjygold.com/gw/generic/czbank/h5/m/latestPrice`

### 国际金价（新浪财经 API）

- 伦敦金 (XAU)：`hq.sinajs.cn/list=hjxfy`
- 纽约金 (COMEX)：`hq.sinajs.cn/list=hf_GC`

## 关键文件

| 文件 | 说明 |
|------|------|
| `Sources/main.swift` | 全部源代码（~570 行）|
| `Info.plist` | 应用配置（Bundle ID、版本号等）|
| `Package.swift` | Swift Package Manager 配置 |
| `build.sh` | 构建脚本（编译 + 打包）|
| `Resources/AppIcon.icns` | 应用图标 |

## 开发注意事项

1. **并发处理**：使用 `async/await` 并发请求多个 API
2. **数据存储**：使用 `UserDefaults` 存储用户偏好（刷新间隔、状态栏显示设置）
3. **涨跌颜色**：涨红跌绿（符合中国股市习惯）
4. **快捷键**：⌘F 悬浮窗、⌘R 刷新、⌘Q 退出
5. **内存管理**：注意 `[weak self]` 避免循环引用

## 用户偏好设置 (UserDefaults)

```swift
// 刷新间隔（秒）
UserDefaults.standard.integer(forKey: "refreshInterval")  // 默认 10

// 状态栏显示模式
UserDefaults.standard.string(forKey: "statusBarDisplay")  // "priceAndChange" | "priceOnly" | "changeOnly"

// 悬浮窗位置
UserDefaults.standard.string(forKey: "floatingWindowPosition")  // "topRight" | "topLeft" | ...

// 悬浮窗是否显示
UserDefaults.standard.bool(forKey: "floatingWindowVisible")
```

## 快速定位代码

- 菜单栏图标更新：搜索 `updateStatusBarTitle`
- 定时刷新逻辑：搜索 `startAutoRefresh`
- 悬浮窗拖拽：搜索 `mouseDown` / `mouseDragged`
- API 请求：搜索 `fetchMinsheng` / `fetchInternationalGold`
