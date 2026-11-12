# 增量接入报告（A6）

> 工程：`/Users/huxiaohui/Documents/YostarWork/Github/HM/HanZi`
> 依据：harmonyos-app-builder `references/17-incremental-adoption.md`（Brownfield A0–A6）
> 本轮特性：`CUSTOM_IMMERSIVE`、`TEST`（AdoptionPolicy 骨架）、`WINDOW_IMMERSIVE` 的自由多窗补充（`2in1`）

## 1. 模式判定

命中 Brownfield：已有工程路径 + 只补既有工程特性，未生成新骨架、未重排模块、未迁移状态管理代际。

- A0 盘点：`docs/adoption-audit.md`
- 接入前构建基线：`devecocli build` → SUCCESS，0 ERROR
- 回滚备份：`docs/adoption-backup/`

## 2. 变更文件清单

### 新增

| 文件 | 职责 |
| --- | --- |
| `entry/src/main/ets/common/material/CustomImmersivePolicy.ets` | 纯策略：`resolveLevel()` / `customImmersivePlan()` / `customStyleOf()` / `effectiveLevel()`，无系统 API |
| `entry/src/main/ets/common/adoption/AdoptionPolicy.ets` | 存量接入决策 `adoptionPlan(feature, audit)`，无系统 API |
| `entry/src/main/ets/viewmodel/CustomImmersiveViewModel.ets` | `@ObservedV2` 唯一重算入口，持有 `@Trace plan` 与降级原因文案 |
| `entry/src/ohosTest/ets/test/CustomImmersivePolicy.test.ets` | 7 条 Hypium 断言（AUTO / 不支持 / L1 收敛 / 手表 / L3 / 类型不变） |
| `entry/src/ohosTest/ets/test/AdoptionPolicy.test.ets` | 5 条 Hypium 断言（DEGRADED / BLOCKED / V1 隔离 / router 门限 / append-only） |
| `docs/adoption-audit.md` | A0 实测盘点 |
| `docs/adoption-report.md` | 本报告 |
| `docs/adoption-official-docs.md` | 官方 URL 与核验状态 |

### 修改（append-only / 局部替换，无删除）

| 文件 | 变更 |
| --- | --- |
| `entry/src/main/ets/service/MaterialController.ets` | 新增 `globalLevelId()`、`materialTypeNames()`、`levelOfCustom()`、`paramsOfPlan()`；未改既有方法签名 |
| `entry/src/main/ets/service/SafeAreaController.ets` | 新增 `freeWindow` / `titleButtonWidthVp` / `titleButtonHeightVp`；`attach()` 追加 `freeWindowModeChange` / `windowTitleButtonRectChange` 监听，`detach()` 成对注销；自由窗口下 `setWindowDecorVisible(false)` |
| `entry/src/main/ets/viewmodel/SettingsViewModel.ets` | 设置恢复完成、材质开关 / 类型 / 档位变化后调用 `customImmersiveViewModel.recompute()` |
| `entry/src/main/ets/pages/IndexTitleStyle.ets` | `indexMaterialParams()` 改为读 `CustomPlan`；L3 / 关闭时不下发 `systemMaterialEffect` |
| `entry/src/main/ets/pages/Index.ets` | 启动时重算 plan；底部页签材质改为条件下发；自由窗口按三键区宽度补右侧 padding |
| `entry/src/main/ets/views/settings/SettingsMaterialView.ets` | 新增「自定义沉浸光感」分区，展示实际降级原因 |
| `entry/src/main/resources/base/element/string.json` | 追加 8 个 key（`section_custom_immersive` / `custom_immersive_reason_*`） |
| `entry/src/main/resources/zh_CN/element/string.json` | 追加同名 8 个 key |
| `entry/src/main/module.json5` | `deviceTypes` 追加 `"2in1"` |
| `entry/src/ohosTest/ets/test/List.test.ets` | 注册 2 个新测试套 |

## 3. 配置 diff（append-only）

```diff
# entry/src/main/module.json5
 "deviceTypes": [
   "phone",
-  "tablet"
+  "tablet",
+  "2in1"
 ],
 # entry/src/main/module.json5 · abilities[EntryAbility]
+"supportWindowMode": [
+  "fullscreen",
+  "split",
+  "floating"
+],
```

`supportWindowMode` 是 2in1 / 平板进入自由多窗的前提：只声明 `2in1` 而不声明 `floating`，应用在 PC 上只能全屏，自由窗口适配代码不会生效。

未改动：`bundleName`、`compatibleSdkVersion`、`targetSdkVersion`、`signingConfigs`、现有权限、`oh-package.json5`。
自由多窗未新增权限（`setWindowDecorVisible` / `getTitleButtonRect` / `isInFreeWindowMode` 均无需声明权限）。

## 4. 自定义沉浸光感：双入口一致性

- 标题栏：`IndexTitleStyle.indexMaterialParams()` → `titleBar.style.systemMaterialEffect`
- 底部页签：`Index.floatingStyle()` → `barFloatingStyle.systemMaterialEffect`
- 两处读同一份 `customImmersiveViewModel.plan`，唯一重算入口是 `recompute()`。
- 决策顺序：L3 → 不下发；L2 → SMOOTH；`getSystemMaterialTypes()` 不含 `IMMERSIVE` → SMOOTH；`AUTO` → ADAPTIVE；`SMOOTH` → SMOOTH；L1 且 EXQUISITE → GENTLE。
- `materialType` 在自定义路径恒为 `ADAPTIVE`；用户在设置页显式选择 `NONE` / `IMMERSIVE` 时按第 15 号规范的扩展路径尊重用户选择。
- 关断语义：L3 / 总开关关闭时 `emitEffect=false`，两个入口都**整体不下发**该字段，不使用 `undefined` 冒充关闭。
- 悬浮三条件保持不变：`barOverlap(true)` + `vertical(false)` + `barPosition(BarPosition.End)`；未新增 `barBackgroundColor` / `barBackgroundBlurStyle`。

## 5. 多设备：自由窗口标题栏

- `deviceTypes` 增加 `2in1`；折叠屏仍由 `phone` / `tablet` 承载，不新增设备类型。
- `EntryAbility.supportWindowMode` 追加 `fullscreen` / `split` / `floating`，否则 2in1 上只能全屏，自由多窗链路不可达。
- `SafeAreaController.attach()` 读取 `isInFreeWindowMode()`；自由窗口下隐藏系统标题栏并读取 `getTitleButtonRect()`（单位 vp）。
- `windowTitleButtonRectChange` / `freeWindowModeChange` 与 `avoidAreaChange` 一样在 `detach()` 成对 `off`。
- `Index` 在自由窗口下给 `HdsNavigation` 右侧补 `titleButtonWidthVp`，避免页面内容被最大化 / 最小化 / 关闭三键遮挡。
- 非自由窗口恢复系统标题栏并清零 padding，手机 / 平板外观不变。

## 6. 降级路径

| 场景 | 行为 |
| --- | --- |
| `immersiveOn=false` | 计划 L3：双入口都不下发 `systemMaterialEffect`，标题栏退回 `sys.color.comp_background_gray` 兜底 |
| HDS 不支持 / SDK < 23 | 计划 L2：`materialLevel=SMOOTH`，仍下发 `ADAPTIVE` 类型 |
| `getSystemMaterialTypes()` 不含 `IMMERSIVE` 或抛错 | SMOOTH，原因文案「设备不支持沉浸材质」 |
| 算力档 `GENTLE`（L1）且用户选精美 | 收敛为 `GENTLE`，原因文案「精美档已收敛」 |
| 手表 | `effectiveLevel()` 强制 L2 |
| 非自由窗口 / 接口 801 | 不隐藏系统标题栏，三键 padding 为 0 |

## 7. 验证结果

| 项 | 命令 | 结果 |
| --- | --- | --- |
| ArkTS 静态检查 | `devecocli check arkts <12 个改动文件>` | 1 条已知误报 `nav-destination-root-node`（实际根节点为 `HdsNavDestination`），无新增真实错误 |
| 主工程构建 | `devecocli build` | **SUCCESS**，0 ERROR，与 A0 基线一致 |
| 测试工程构建 | `devecocli build --modules entry@ohosTest` | **SUCCESS**，0 ERROR |
| 单测执行 | — | **未执行**：本机 `devecocli` 无 test 子命令、工程无 `hvigorw` 包装器；仅完成编译 |
| 手机模拟器运行 | `devecocli run --skip-build --device 127.0.0.1:5555` | **Smoke PASS**（Pura X View，HarmonyOS 7.0.0(26.0.0)） |

### 7.1 模拟器实测（Pura X View / 127.0.0.1:5555）

| 场景 | 操作 | 观察结果 |
| --- | --- | --- |
| 启动门控 | 冷启动 | 先出 `bootstrapLoadingOverlay`，数据就绪后挂载 `HdsNavigation`，无白屏 |
| 首页 | 冷启动后 | 「今日学习 0/3044 字」「完整数据（本地）」12 册卡片正常 |
| 二级页 | 点第一册 → 课程 → 生字 | BookDetail / LessonDetail（天地人、隐藏拼音、会写的字）/ CharDetail（大·天、第 3/3 笔、播放笔顺、描红练习）均正常返回 |
| 页签切换 | 底部悬浮页签 | 课本 / 复习 / 设置三页切换正常（页签可点区域 y≈2084–2123） |
| 材质页 | 设置 → 材质与动效 | 「应用级材质 enable / 材质等级 EXQUISITE」、沉浸光感开关、材质类型/沉浸光感材质下拉、光感反馈开关均渲染 |
| 自定义沉浸光感分区 | 选「精美」 | 分区文案由「跟随系统自适应档位。」变为「使用设备支持的所选档位。」，说明 `CustomImmersiveViewModel.recompute()` 生效 |
| 主题色 | 外观与语言 → 主题色 → 绿色 | 全局强调色、图标、胶囊底色同步变绿 |
| 系统与隐私 | 设置 → 系统与隐私，开启防窥保护 | 智感握姿 →「未生效：设备不支持智感握姿」；防窥保护 →「未生效：设备不支持防窥保护」；日志仅 `isDlpAntiPeepSwitchOn failed: 801`，无崩溃（按预期降级） |
| 复习页 | 复习页签 | 占位卡片 + 禁用「开始复习」（Phase 5 未接入，符合当前阶段） |
| 运行日志 | `devecocli log --bundle-name com.example.hanzi` | 无 ERROR / Exception / JSCrash；仅 `holdingHandChanged on failed: 801`（模拟器无握姿传感器，预期） |
| 偏好持久化 | 改主题色 / 材质档位后重装并重启 | 选择项（绿色、精美）与自定义沉浸光感文案均保持，`SettingsStore` 读写正常 |

### 7.2 本轮顺带修复（实测发现）

| 问题 | 原因 | 修复 |
| --- | --- | --- |
| 移除 MiniBar 后「光感反馈」开关不再影响任何材质 | 该开关原先只被 `glassInteractiveMaterial()` 使用，MiniBar 删除后成为悬空配置 | `overlayMaterial()` 增加 `lightEnabled` 参数，并透传到 `menuOptionsFor()` / `sheetOptions()` / `dialogParams()` / `toastOptions()`；三处调用点传 `appSettings.lightEffectEnabled` |
| 死代码与过期注释 | `glassInteractiveMaterial()`、`menuOptions()` 已无调用；`DetailPageView` 注释仍提 MiniBar | 删除两个方法，注释改为「底部页签栏」 |
| 主题色只作用于设置页，首页/生字页仍是固定蓝 | 首页、生字页、底部页签、LoadingProgress 用静态 `$r('app.color.hanzi_active')` / `hm_brand` | 统一改用 `themePalette.fill()`（实心按钮）/ `accent()`（文字、图标、进度条）；`ButtonStyleMode.NORMAL` 按钮显式下发 `accent()`，避免沿用系统默认蓝 |

## 8. 未验证项

- 未在 2in1 / PC 真机或模拟器上验证自由窗口三键避让的实际像素效果（2in1 模拟器启动后未进入 `hdc list targets`，用户已决定本轮不测）。
- 未在支持 / 不支持 `IMMERSIVE` 的两类真机上对比标题栏与页签栏材质一致性。
- 单测已编译但未在设备上运行；`CustomImmersivePolicy` / `AdoptionPolicy` 的断言结果待设备侧执行确认。
- 未验证手表形态（当前 `deviceTypes` 不含 wearable；策略层已按 L2 处理）。
- 未做上架材料与 ACL 审批（防窥 `DLP_GET_HIDE_STATUS` 仍未声明）。

## 9. 回滚

1. 删除新增文件与目录：`common/material/`、`common/adoption/`、`viewmodel/CustomImmersiveViewModel.ets`、两个新测试文件、`docs/adoption-{audit,report,official-docs}.md`。
2. 用 `docs/adoption-backup/` 恢复：`build-profile.json5`、`module.json5`、`root-oh-package.json5`、`entry-oh-package.json5`。
3. 撤销 `SettingsViewModel` / `IndexTitleStyle` / `Index` / `SettingsMaterialView` / `MaterialController` / `SafeAreaController` / `List.test.ets` 的本次追加行；资源 key 可保留（不被引用时无副作用）或按 diff 删除。
4. 回滚后重跑 `devecocli build`，应回到 A0 基线（SUCCESS，0 ERROR）。
