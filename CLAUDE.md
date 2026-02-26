# JDGold - macOS 黄金价格监控应用

## 项目概述

一个极简的 macOS 菜单栏应用，实时监控国内外黄金价格。

- **类型**：macOS 原生菜单栏应用
- **语言**：Swift 5.9
- **框架**：AppKit (Cocoa)
- **特点**：模块化架构，无第三方依赖
- **最低系统要求**：macOS 12.0+

## 常用命令

```bash
# 构建
./build.sh

# 运行
open JDGold.app

# 手动编译（调试用）
swiftc -O -o JDGold.app/Contents/MacOS/JDGold $(find Sources -name "*.swift") -framework Cocoa
```

## 架构概览

### 模块化架构 (`Sources/`)

项目按照职责划分为以下模块：

- **Models**: 数据模型定义 (PriceInfo, GoldPrices, APIResponse, PriceRecord)
- **Services**: 核心业务逻辑 (GoldPriceService, PriceHistoryManager)
- **Views**: 视图组件 (PriceCardView, InternationalCardView, MiniChartView)
- **UI**: 窗口与布局 (FloatingWindow, FloatingContentView)
- **App**: 应用生命周期 (AppDelegate)
- **main.swift**: 仅作为应用入口

### 核心组件职责

| 组件 | 模块 | 职责 |
|------|------|------|
| `PriceInfo` | Models | 数据模型：价格、昨收价、涨跌幅、涨跌额 |
| `PriceRecord` | Models | 历史记录模型：时间戳、价格 |
| `GoldPriceService` | Services | 单例服务，负责 API 请求和数据处理 |
| `PriceHistoryManager` | Services | 历史数据管理，含 24h 滑动窗口逻辑 |
| `PriceCardView` | Views | 国内金价卡片，包含 `MiniChartView` |
| `InternationalCardView` | Views | 国际金价卡片 |
| `FloatingWindow` | UI | 悬浮窗口 NSWindow 子类 |
| `AppDelegate` | App | 主应用逻辑，菜单栏管理 |

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
| `Sources/App/AppDelegate.swift` | 主应用逻辑 |
| `Sources/Services/GoldPriceService.swift` | 核心服务 |
| `Sources/Views/` | 视图组件目录 |
| `Sources/Models/` | 数据模型目录 |
| `Sources/main.swift` | 入口文件 |
| `Info.plist` | 应用配置 |
| `build.sh` | 构建脚本 |

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
