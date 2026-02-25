# UI 视觉优化规范 (UI Polish v2)

## 为什么 (Why)
用户反馈对当前的悬浮窗样式仍然不满意，截图显示存在对齐不一致、信息层级不够清晰、以及整体视觉风格（如 Emoji 图标）不够现代的问题。需要进一步打磨细节，对齐视觉元素，并引入更符合 macOS 系统的设计语言（SF Symbols、Grid 布局）。

## 变更内容 (What Changes)

### 1. 布局重构 (Layout Refactoring)
-   **统一网格对齐 (Unified Grid Alignment)**：
    -   国际金价部分放弃简单的 `NSStackView` 堆叠，改用 `NSGridView` (或模拟 Grid 的 StackView)，确保“名称”、“价格”、“涨跌幅”三列严格对齐。
    -   价格列统一右对齐（Right Aligned），符合金融数据展示习惯。
-   **国内金价卡片 (Domestic Card)**：
    -   保持“Hero”风格，但优化内部间距。
    -   将“最高/最低价” (High/Low) 从单纯的文本改为带有标签的格式（如 `H: 1148.02` `L: 1139.24`），并使用更小的等宽字体，增加可读性。

### 2. 视觉升级 (Visual Upgrade)
-   **图标系统 (Iconography)**：
    -   **移除 Emoji**：替换所有 Emoji (`🪙`, `🌍`) 为 macOS 原生的 **SF Symbols**。
        -   民生银行 -> `yensign.circle.fill` 或 `building.columns.fill`
        -   国际金价 -> `globe` 或 `globe.asia.australia.fill`
        -   涨跌箭头 -> `arrow.up.forward` / `arrow.down.forward` (小号)
-   **字体与排版 (Typography)**：
    -   **数字字体**：继续使用 `monospacedDigitSystemFont`，但调整字重。
    -   **国际金价价格**：适当放大，使其不至于在“国内金价”的大数字面前显得过于单薄。
    -   **涨跌幅**：使用圆角矩形背景（Pill Shape）或彩色文字，增强视觉反馈（红涨绿跌）。

### 3. 间距与边距 (Spacing & Margins)
-   减少“国内金价”与“国际金价”之间的垂直间距，使整体更紧凑。
-   增加水平边距（Padding），防止内容贴边。

## 影响范围 (Impact)
-   **UI 组件**：`PriceCardView`, `InternationalCardView`, `FloatingContentView`
-   **资源**：需要确保运行环境支持 SF Symbols（macOS 11+）。

## 新增需求 (ADDED Requirements)
### Requirement: SF Symbols Integration
系统应使用 SF Symbols 替代文本 Emoji 图标。
-   **Scenario**: 渲染时
-   **WHEN**: `setupUI` 被调用
-   **THEN**: 使用 `NSImage(systemSymbolName: ...)` 加载图标，并设置正确的 tint color。

### Requirement: Grid Layout for International Prices
国际金价列表应使用网格布局。
-   **Scenario**: 渲染列表
-   **WHEN**: `InternationalCardView` 初始化
-   **THEN**: 创建 3 列布局：[Icon+Name (Left), Price (Right), Change (Right)]。

## 修改需求 (MODIFIED Requirements)
### Requirement: Domestic Card Layout
-   **Change**: 将 Price 的显示位置调整为更平衡的布局（考虑居中或右对齐，或者保持左对齐但增加 Label 的清晰度）。
-   **Reason**: 提升视觉平衡感。
