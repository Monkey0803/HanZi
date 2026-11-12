# A0 存量工程盘点（Brownfield）

> 生成时间：2026-11-12 · 工程根：`/Users/huxiaohui/Documents/YostarWork/Github/HM/HanZi`
> 依据：harmonyos-app-builder `references/17-incremental-adoption.md` 3.10.3。
> 本文件只记录实测值，不含待办承诺。

## 版本与构建

| 项 | 实测值 | 来源 |
| --- | --- | --- |
| `targetSdkVersion` | `26.0.0` | `build-profile.json5` |
| `compatibleSdkVersion` | `6.1.0(23)` | `build-profile.json5` |
| `compileSdkVersion` | 未显式声明（随 DevEco 默认） | `build-profile.json5` |
| `arkTSVersion` | 未显式声明（默认 ArkTS） | `build-profile.json5` |
| `runtimeOS` | `HarmonyOS` | `build-profile.json5` |
| `modelVersion` | `6.1.0` | `oh-package.json5` |
| 签名 | `signingConfigs: []`（本地调试签名） | `build-profile.json5` |

## 模块 / 包名 / 设备

| 项 | 实测值 |
| --- | --- |
| `bundleName` | `com.example.hanzi` |
| 模块 | `entry`（entry HAP）、`toast-kit`（HAR）、`keyboard-kit`（HAR） |
| `deviceTypes` | `phone`, `tablet` |
| 已有权限 | `INTERNET`、`GET_NETWORK_INFO`、`DETECT_GESTURE` |
| 未声明 | `DLP_GET_HIDE_STATUS`（防窥能力受 ACL 限制，当前默认关闭） |
| extensionAbilities | 无（无卡片 / 无输入法扩展） |
| 应用级材质 | `module.json5` metadata `ohos.arkui.UIMaterial.state = enable` |

## 状态管理

| 项 | 实测值 |
| --- | --- |
| 代际 | 纯 V2：31 个文件使用 `@ComponentV2` / `@ObservedV2` |
| V1 装饰器 | 0 处（`@State` / `@Prop` / `@Link` / `@Provide` / `@Consume` / `@Watch` / `@ObjectLink` / `@Observed` 均无） |
| 存储 | 无 `AppStorage` / `LocalStorage` / `PersistentStorage`；设置走 `preferences` |

## 导航骨架

| 项 | 实测值 |
| --- | --- |
| 类型 | `HDS`（`HdsNavigation` + `HdsTabs` + 单 `NavPathStack`） |
| 入口 | `pages/Index.ets`（`pages/Index` 已登记 `main_pages.json`） |
| 二级页 | `HdsNavDestination` + `pageMap`，路由常量在 `common/constants/RouterConstants.ets` |
| 旧 `router` | 未使用 |

## 分层与共享层

| 项 | 实测值 |
| --- | --- |
| 共享层 | `common/` 已存在：`components` / `constants` / `utils` |
| 业务分层 | `model` / `service` / `viewmodel` / `views` / `pages` |
| 新增落点 | `common/`（策略与纯函数）＋ `service/`（系统能力适配） |

## 资源

| 项 | 实测值 |
| --- | --- |
| locale 目录 | `base`（英文）、`zh_CN`、`dark` |
| `base` string key | 122 |
| `zh_CN` string key | 122 |
| key 差集 | 空（base 与 zh_CN 完全一致） |
| 独立 `en_US` | 无（`base` 即英文，系统语言为英文时命中 base） |
| 深色适配 | `dark/element/color.json` |

## 测试

| 项 | 实测值 |
| --- | --- |
| 框架 | `@ohos/hypium 1.0.25`、`@ohos/hamock 1.0.0`（root devDependencies） |
| 已有用例 | `Constants` / `ImageSupport` / `List` / `MaterialMap` / `SettingsOptions` / `StrokeEngine` |
| 运行方式 | `devecocli build --modules entry@ohosTest` + `hvigorw test` |

## 既有鸿蒙特性覆盖

| FeatureKey | 现状 | 主要文件 |
| --- | --- | --- |
| `MATERIAL` | 已接入：HDS 四档参数 + `uiMaterial` 组件材质 + 弹层/Toast/半模态注入 | `service/MaterialController.ets` |
| `THEME` | 已接入：深浅色 + 自定义主题色 + 色板 | `service/ThemeController.ets`、`utils/ThemeColorMath.ets`、`views/settings/ThemeColorSheet.ets` |
| `BACKGROUND` | 部分：预置图 `app.media.app_background` + `desiredSize` 降采样；**无用户选图链路** | `viewmodel/BackgroundViewModel.ets`、`service/ImageSupport.ets` |
| `WINDOW_IMMERSIVE` | 已接入：`setWindowLayoutFullScreen(true)` + 五类避让中的 `TYPE_SYSTEM` / `TYPE_NAVIGATION_INDICATOR` + `avoidAreaChange` | `entryability/EntryAbility.ets`、`service/SafeAreaController.ets` |
| `NAVIGATION` | 已接入：单栈 `HdsNavigation` + 悬浮 `HdsTabs` | `pages/Index.ets` |
| `REACH` | 已接入：`holdingHandChanged` 订阅 + 左手镜像（详情页操作区） | `service/GripSensor.ets`、`views/DetailPageView.ets` |
| `ANTI_PEEP` | 已接入但默认关闭：`canIUse` + 系统开关 + 订阅 + 遮罩（`PrivacyVeil`） | `service/AntiPeep.ets`、`views/PrivacyVeil.ets` |
| `MATERIAL_CHOICE` | 已接入：材质类型 / 四档 / 光感反馈设置项 | `views/settings/SettingsMaterialSection.ets`、`model/SettingsOptions.ets` |
| `CUSTOM_IMMERSIVE` | 部分：`getSystemMaterialTypes()` 能力探测 + 等级收敛；**无双入口共用状态/动态切换** | `service/MaterialController.ets` |
| `CARD` | 未接入（无 FormExtensionAbility / form_config） | — |
| `I18N` | 已接入：base(en) + zh_CN，key 集合一致 | `resources/base`、`resources/zh_CN` |
| `TEST` | 已接入：Hypium + 6 个测试文件 | `entry/src/ohosTest/ets/test/` |
| `RELEASE` | 未做：无上架材料 / ACL 审批记录 | — |

## 构建基线（接入前）

- 命令：`devecocli build`
- 结果：**SUCCESS**（0 ERROR）
- 备注：本次会话此前已完成数据管线替换与 Phase 2–4 页面实现，最近一次构建通过；以该构建作为 A0 基线。

## 回滚材料

工程不是 git 仓库，已按 17 的 3.10.9 备份配置：

- `docs/adoption-backup/build-profile.json5`
- `docs/adoption-backup/module.json5`
- `docs/adoption-backup/root-oh-package.json5`
- `docs/adoption-backup/entry-oh-package.json5`

回滚方式：删除本次新增文件/目录；配置与资源按备份文件恢复追加行。
