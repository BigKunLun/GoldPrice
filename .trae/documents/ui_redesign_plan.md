# UI 重构计划：悬浮窗样式优化

## 目标
针对用户反馈的悬浮窗样式“糟糕”的问题，结合 macOS 原生设计规范（Human Interface Guidelines），对悬浮窗进行全面的 UI/UX 升级。目标是使其看起来像一个原生的 macOS 组件（如控制中心的小组件），提升视觉层级、清晰度和美观度。

## 问题分析
1.  **布局拥挤**：当前单行布局信息密度过大，缺乏呼吸感。
2.  **视觉层级弱**：价格作为核心信息，没有在视觉上得到足够的强调（字体大小/粗细对比不足）。
3.  **样式老旧**：简单的分割线和 Emoji 图标缺乏现代感；数字字体与中文字体混排效果一般。
4.  **对齐问题**：不同行的元素没有很好地对齐，导致视觉杂乱。

## 设计方案

### 1. 总体容器 (FloatingContentView)
-   **背景**：保持 `NSVisualEffectView`（毛玻璃效果），材质使用 `.hudWindow` 或 `.popover`，圆角保持 `12px` 或增加至 `16px`。
-   **内边距 (Padding)**：增加整体内边距，从 `10px` 增加至 `16px`，让内容不贴边。
-   **分割线**：移除生硬的 `NSBox` 分割线，改用间距（Spacing）或微弱的背景色块区分区块。

### 2. 国内金价卡片 (PriceCardView)
从“单行流式布局”改为“结构化布局”：
-   **头部行**：左侧显示名称“民生银行”（Secondary Color, 12pt），右侧显示涨跌幅（Colored, 13pt, 粗体）。
-   **核心行**：左侧显示**大号价格**（Bold Monospaced, 24-26pt），视觉焦点。
-   **底部行**：显示最高/最低价范围（Tertiary Color, 10pt），辅助信息。
-   **布局逻辑**：使用 `NSGridType` 或垂直 `NSStackView` 嵌套水平 `NSStackView`。

### 3. 国际金价卡片 (InternationalCardView)
-   **标题**：缩小“国际金价”标题的视觉比重，或将其作为 Section Header（小号大写字母）。
-   **列表项**：
    -   统一对齐方式：名称左对齐，价格右对齐，涨跌幅右对齐（或紧跟价格）。
    -   增加行高，提升可读性。
    -   字体：名称（Regular 13pt），价格（Bold Monospaced 15pt），涨跌（Medium 12pt）。

### 4. 视觉细节
-   **颜色**：严格使用 macOS 系统语义色（`labelColor`, `secondaryLabelColor`, `systemRed`, `systemGreen`）。
-   **字体**：数字统一使用 `monospacedDigitSystemFont` 以防止跳动。
-   **图标**：如果可能，尝试使用 SF Symbols（需检查系统兼容性），或者优化 Emoji 的排版（增加与文字的间距）。

## 实施步骤

### 阶段一：重构 Domestic Card (PriceCardView)
1.  修改 `PriceCardView` 的 `setupUI` 方法。
2.  创建垂直 StackView 作为主容器。
3.  第一行：Name Label + Spacer + Change Label。
4.  第二行：Big Price Label。
5.  第三行：High/Low Label (或者放在价格旁边)。
6.  调整字体大小和颜色。

### 阶段二：重构 International Card (InternationalCardView)
1.  修改 `InternationalCardView` 的 `setupUI` 方法。
2.  优化标题样式，增加与内容的间距。
3.  重构价格行，使用 Grid 或对齐的 StackView 确保“名称”、“价格”、“涨跌”三列垂直对齐。

### 阶段三：整体调整
1.  调整 `FloatingWindow` 的初始大小（高度可能需要增加）。
2.  调整 `FloatingContentView` 的 Padding。
3.  移除 `NSBox` 分割线。
4.  微调毛玻璃背景效果。

## 预期效果
悬浮窗将变得更加现代、清晰。用户一眼就能看到核心金价，次要信息（如最高最低价）不会抢占视觉焦点，整体风格融入 macOS 系统。
