# 增量接入：官方文档索引

> 仅收录本轮实际使用的能力；URL 已在 2026-11-12 用 `curl -sS -o /dev/null -w "%{http_code}" -L` 校验，全部返回 200。
> 未核实的链接一律不写入，避免编造。

## 自定义沉浸光感（CUSTOM_IMMERSIVE）

| 用途 | 官方文档 | 校验 |
| --- | --- | --- |
| HDS 组件材质（系统自适应 / 自定义沉浸光感 / 完整示例） | https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/ui-design-hds-component-material | 200 |
| 自定义沉浸光感效果（锚点） | https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/ui-design-hds-component-material#%E4%BD%BF%E7%94%A8%E8%87%AA%E5%AE%9A%E4%B9%89%E6%B2%89%E6%B5%B8%E5%85%89%E6%84%9F%E6%95%88%E6%9E%9C | 200 |
| `getSystemMaterialTypes()` API | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdsmaterial | 200 |
| `TitleBarStyleOptions.systemMaterialEffect` | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdsnavigation | 200 |
| `HdsTabsFloatingStyle.systemMaterialEffect` | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdstabs | 200 |
| HDS 组件使用沉浸光感材质指南 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-design-hds-component-material | 200 |
| 组件适配沉浸光感（双入口不对称默认开启） | https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-immersive-light-sense-component-adaptation?docScope=all | 200 |
| 设置页签栏的悬浮样式 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-design-hds-tabs-bar-floating | 200 |

## 窗口沉浸与自由多窗（WINDOW_IMMERSIVE）

| 用途 | 官方文档 | 校验 |
| --- | --- | --- |
| 窗口沉浸式最佳实践（避让区 / 自由多窗标题栏） | https://developer.huawei.com/consumer/cn/doc/doccenter-multi-device/bpta-multi-device-window-immersive | 200 |
| 窗口沉浸式指南 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/immersive-window-feature | 200 |
| `expandSafeArea` 通用属性 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-expand-safe-area | 200 |
| `Window` 接口（`isInFreeWindowMode` / `getTitleButtonRect` / `setWindowDecorVisible` / `windowTitleButtonRectChange`） | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-window-window | 200 |
| 应用适配自由窗口 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-adaptation-freeform-window | 200 |

## 本地 SDK 交叉核对

以下签名以本机 SDK 声明为准（避免只信文档片段）：

- `~/Library/OpenHarmony/Sdk/26.0.0/ets/api/@ohos.window.d.ts`
  - `isInFreeWindowMode(): boolean`
  - `on(type: 'freeWindowModeChange', callback: Callback<boolean>): void` / `off(...)`
  - `getTitleButtonRect(): TitleButtonRect`（`right` / `top` / `width` / `height`，单位 vp）
  - `on(type: 'windowTitleButtonRectChange', callback: Callback<TitleButtonRect>): void` / `off(...)`
  - `setWindowDecorVisible(isVisible: boolean): void`

## 未收录

- 服务卡片（`CARD`）：本轮未接入。
- 背景图用户选图（`BACKGROUND`）：本轮未接入，沿用既有预置图链路。
- 防窥 ACL（`DLP_GET_HIDE_STATUS`）：未申请、未声明，相关能力默认关闭。
