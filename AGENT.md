# HDS App — 工程导航

HarmonyOS stage 模型应用，骨架由 `create-harmonyos-hds-app` 生成。**改动界面/功能前先读本文件**。

## Must-read files（一次批量读）

| File | Why |
|------|-----|
| `entry/src/main/ets/pages/Index.ets` | `@Entry` **外壳**：HdsNavigation + HdsTabs、页签、标题栏/页签栏材质、内容穿透与滚动联动、标题栏常驻、路由 `pageMap` |
| `entry/src/main/ets/common/constants/*.ets` | 所有**纯逻辑常量**：页签下标、路由名、偏好库 key、设置语义 id、`CONTENT_UNDER_TITLE_BAR` |
| `entry/src/main/ets/viewmodel/*.ets` | `@ObservedV2` ViewModel：Background / Settings（图片领域另有 Image / ImagePreview） |
| `entry/src/main/ets/views/*.ets` | `@ComponentV2` 纯展示页面：Home / Settings / PrivacyVeil（图片领域覆盖 Image / ImagePreview） |
| `entry/src/main/resources/{base,dark}/element/color.json` | 颜色（深浅色两套），禁止在代码里写十六进制色值 |
| `entry/src/main/resources/base/element/float.json` | 所有尺寸（vp/fp），禁止在代码里写魔法数字 |
| `entry/src/main/resources/base/element/string.json` + `zh_CN/element/string.json` | 文案（中英），禁止在代码里写 UI 文本 |

## ArkTS 硬约束（写 `.ets` 前先过一遍，踩了直接编译失败）

- 类型：禁 `any` / `unknown` / `ESObject` / `as any`；对象字面量必须有类型上下文；`Record<K,V>` 替代索引签名；不用 `ReturnType`/`Pick`/`Omit` 等 TS 工具类型。
- 对象：非 `Record` 上禁 `obj[key]`；禁 `in` / `delete` / `Object.keys` / `Object.entries` / `hasOwnProperty`；禁运行时新增属性。
- 函数：函数内禁再声明函数（用文件级 helper 或 `static`）；禁 `function () {}` 表达式（用箭头）；禁构造器参数属性；必须显式返回类型。
- 空安全/异步：禁非空断言 `!`；`await` 后再读字段；`catch (error)` 不标类型，内部 `error as BusinessError`。
- 组件：`main_pages.json` 每个页面恰好一个 `@Entry`；V1/V2 装饰器不混用；`build()`/`@Builder` 内只写 UI + `if/else` + `ForEach`，不声明局部变量、不改状态、不调普通方法；`@Component` 内禁 getter；成员别叫 `width`/`height`/`size`/`opacity`/`backgroundColor`；`@Local` 不能由父组件初始化（用 `@Param`）。
- 导入：只用 `@kit.*`；`NavPathStack`/`AppStorage`/`Navigation`/`SymbolGlyph`/`SymbolSpan` 等是全局，不要 import。

## 分层（依赖单向：pages → views → viewmodel → service → model，`common` 谁都能用）

```
entry/src/main/ets/
├─ common/constants/   纯逻辑常量（enum / static readonly / 模块级 const，含断点配置）
├─ model/              @ObservedV2 数据模型 + ChoiceSet 选项表
├─ service/            数据源与平台能力：SettingsStore / ThemeController / LocaleController /
│                      MaterialController / AntiPeep / GripSensor / ImageSupport /
│                      ScrollerRegistry / NotificationService
├─ viewmodel/          @ObservedV2 状态与行为（View 只读它）
├─ views/              纯 UI + 事件上报（含 ResponsiveContent 断点容器）
└─ pages/              @Entry 外壳
```

- **View** 不写业务逻辑：读 ViewModel/共享单例状态、把用户操作上报回去。
- 非父子组件通信走共享的 `@ObservedV2` 单例（`appSettings` / `settingsViewModel` / `antiPeep` /
  `gripSensor` / `backgroundViewModel` / `scrollers`），不层层传参。
- 状态管理**必须**用 V2（`@ComponentV2`/`@Local`/`@Param`/`@Event`/`@Monitor`/`@ObservedV2`/`@Trace`），不要和 V1 装饰器混用。
- 页面内容用 `ResponsiveContent() { ... }` 包住，宽屏自动收窄居中；不要写死内容宽度。
  **注意**：`ResponsiveContent` 后面不能再链 `.width()` / `.height()` 等属性（自定义组件 + 尾随 builder 的语法限制）。

## 已预装的通用增强层（本项目在模板之上额外移植）

| 能力 | 文件 |
|------|------|
| 主题色（6 预设 + 系统取色器，运行时 `accent/fill/tint` 三 token） | `model/ThemePalette.ets`、`model/ThemeColorOptions.ets`、`common/utils/ThemeColorMath.ets`、`views/settings/ThemeColorSheet.ets` |
| 统一菜单（规格化 `MenuSpec`，收口 `bindMenu`） | `common/components/MenuSpec.ets`、`AppMenu.ets`、`ChoiceMenu.ets` |
| 统一半模态 + 选项 chip | `common/components/AppSheet.ets`、`SheetDetents.ets`、`ChoiceField.ets` |
| 设置行组件与二级页 | `views/settings/SettingsRows.ets`、`SettingsLookView.ets`、`SettingsMaterialView.ets`、`SettingsSystemView.ets` |
| 网络层（超时 / 重试 / 条件请求 / 并发限流） | `service/HttpClient.ets`、`service/NetworkStatus.ets` |
| Toast / 软键盘（本地 HAR） | 根目录 `toast-kit/`、`keyboard-kit/`；`common/utils/ToastSetup.ets`；`EntryAbility` 初始化 |

- 主题色的三个 token 只从 `themePalette.accent() / fill() / tint()` 取，不要在页面里另算颜色。
- 弹层材质统一走 `MaterialController`：`overlayMaterial()` / `sheetOptions()` / `dialogParams()` /
  `toastOptions()` / `menuOptionsFor()`；菜单用 `menuOptionsFor(options, immersiveOn)`，
  模板自带的 `menuOptions(enabled)` 是另一套返回 `MenuOptions` 的接口，别混用。
- 两个 KIT 以 `file:` 本地依赖接入，并注册在根 `build-profile.json5` 的 `modules` 里；
  改动 KIT 源码后需要 `ohpm install --all`（或 DevEco Sync）。
- 需要**按断点改结构**时用 `service/DeviceService.ets`（`deviceService.wide`，UIContext 的 mediaquery vp 断点）；
  **只由外壳 `Index` 持有订阅**（`start(this.getUIContext())` / `stop()`），子页面只读 `wide`，别在子页面 stop。
  `pages/Index.ets` 就是范例：窄屏 `tabShell()`（底部 HdsTabs）、宽屏 `wideShell()`（HdsSideBar + HdsSideMenu 侧栏，无底部页签）；
  两套外壳共用 `homeContent()` / `settingsContent()` / `imagesContent()` 这三个 `@Builder`。

## 常量的管理规则（强制）

| 常量类型 | 放哪 | 怎么引用 |
|---------|------|---------|
| 颜色（有深浅色） | `resources/{base,dark}/element/color.json` | `$r('app.color.*')` |
| UI 文本（有中英） | `resources/{base,zh_CN}/element/string.json` | `$r('app.string.*')` |
| UI 尺寸 | `resources/base/element/float.json` | `$r('app.float.*')` |
| 纯逻辑（下标/路由/key/语义 id） | `common/constants/*.ets` | `const` / `enum` / `static readonly` |

**禁止**硬编码颜色十六进制、UI 文本、UI 尺寸；ArkTS 不支持 `as const`。

玻璃材质默认**不设 `materialColor`**（无底色 = 最通透），所以没有颜色例外。若产品要品牌色调，
再显式传**半透明字面量**（如 `'#33FFFFFF'`）：它会多一层底色、通透度下降；资源色还会随深浅色变化。

## 常见改动怎么做

- **加一个设置项**：`common/constants` 加语义 id（如需）→ `model/AppSettings.ets` 加 `@Trace` 字段 → `service/SettingsStore.ets` 读写 key → `viewmodel/SettingsViewModel.ets` 加 setter → 在 `views/settings/` 对应二级页加行；若是新的选项/开关类型，先在 `views/settings/SettingsRows.ets` 的 `SettingField` 与 `currentId()` / `isOn()` 里登记。
- **加一个页签**：`common/constants/NavigationConstants.ets` 加 `TabIndex` → `views/` 加页面 → `pages/Index.ets` 的 `HdsTabs` 里加 `TabContent` + `.tabBar(...)`。
- **加一个二级页**：`common/constants/RouterConstants.ets` 加路由名 → 新页面用 `HdsNavDestination` 作根节点 → `pages/Index.ets` 的 `pageMap` 加分支 → 用 `navPathStack.pushPath(new NavPathInfo(名字, ''))` 跳转。
  多模块/独立分发时改用**系统路由表**：`router_map.json`（`name` / `pageSourceFile` / `buildFunction`）+ `module.json5` 的 `"routerMap": "$profile:router_map"`，并**删掉** `.navDestination(pageMap)` —— 两套机制互斥。目标页导出同名 `@Builder`，页面里 `onReady((ctx) => this.stack = ctx.pathStack)` 取栈；`aboutToAppear` 里不要做栈操作。
- **加一个页签内二级页**：**不要**在页签里再建 `NavPathStack` 或套 `Navigation`。页签内容通过 `@Param stack: NavPathStack` 接收外壳栈，`this.stack.pushPathByName(名字, 参数对象)`；目标页根节点统一 `HdsNavDestination`，整屏覆盖（含页签栏）。返回后页签与滚动位置要靠缓存的 index/offset 恢复。
- **要"页签常驻"时**：这是另一种导航模型，必须新开 ADR 决策（每页签独立栈 + 普通 `Navigation`），不要在单栈模型上叠 `hideTabBar`。
- **改应用级沉浸光感**：只改 `entry/src/main/module.json5` 的 metadata `ohos.arkui.UIMaterial.state`
  （`default` / `enable` / `disable`，别的值平台会静默忽略；feature 模块里配了也不生效；
  `targetSDKVersion` 必须 ≥ 26.0.0）。
  `enable` 让系统清单内的组件默认带材质（Dialog / Toast / 菜单 / AlphabetIndexer / ChipGroup /
  Select / Toggle / Slider / SegmentButton / Navigation 等），并会盖掉组件自己的
  背景色 / 模糊 / 阴影 / 边框；**Popup / Tips / Button 不在清单内**，ENABLE 下仍需组件级显式设置；
  底部页签只有在悬浮样式生效时才默认开启。所以只有"想关掉某个默认开启的组件"时才需要写代码
  （Material.empty）。
  设置页的两行小字就是它的运行时读数：`MaterialController.materialState()`（三态）与
  `globalLevel()`（设备算力档，只读）。
- **改沉浸材质 / 玻璃质感**：默认**不加 `materialColor`**、玻璃用 `ULTRA_THIN`（最通透）；要品牌色调再在 `service/MaterialController.ets` 里显式加半透明字面量。构造只在 `MaterialController`（`glassMaterial()` / `glassInteractiveMaterial()` / `menuOptions()`）。
  材质**只能在生效区域**挂载：Navigation/NavDestination 标题栏、底部 TabBar（`BarPosition.End`）、弹窗类组件与接口、Slider/Toggle/Select；
  挂到普通页面内容区不报错也**没有任何效果**。同一组件不要再设 `backgroundColor`（会覆盖材质背景）。
  关闭默认开启的材质必须用 `uiMaterial.Material.empty`；`systemMaterial(undefined)` 只是"恢复默认"，
  在应用级 `enable` 下会把默认材质放回来。
  开了 `colorInvert` 的子树，前景色必须用 `$r('sys.color.font_primary')` 这类特殊系统资源色才会被智能反色。
- **改底部沉浸布局**：窗口保持全屏布局，根背景扩展到系统安全区；首页 `List` 占满页签内容区，
  在窄屏用 `contentEndOffset` 留出悬浮 HdsTabs 与系统导航提示条的末尾滚动距离，宽屏侧栏时为 0。
  设置页和图片页的末尾 `Blank` 放在 `Scroll` 内容内。固定悬浮操作条还需增加末尾偏移，
  不要在滚动视口外加底部占位。
- **改标题栏/内容关系**：`CONTENT_UNDER_TITLE_BAR`（`common/constants/CommonConstants.ets`）一个开关切换「穿透动态模糊」与「内容避让」；标题栏/状态栏的滑动显隐由 `TITLE_BAR_DYNAMIC_HIDE` 控制（当前为 `false`：标题栏常驻；置 `true` 时再用 `TITLE_BAR_HIDE_OFFSET_VP` / `TITLE_BAR_HIDE_RATIO` 调阈值），`Index.dynamicHideParams()` 统一组装。

## 图标：一律用 HM Symbol（不要引图片）

- 独立图标 `SymbolGlyph($r('sys.symbol.*'))`；文本内混排用 `SymbolSpan`，但它**必须放在 `Text` 里**
  （放别处不显示），且不支持通用属性和事件。
- 两个组件都是**内置组件，禁止 import**；只有 `SymbolGlyphModifier` 从 `@kit.ArkUI` 导入。
- 值只能是 `sys.symbol.*`；不要用 `$r('app.media.*')` / `$rawfile()` / 字符串。图标名必须在官方字典里
  （`check-template.mjs` 会拿 SDK 的 sysResource.js 校验，编造的名字运行时不显示）。
- `fontColor` 传数组；`SINGLE`（默认）只吃第一个颜色，多色要 `MULTIPLE_COLOR`。
- 动效：`effectStrategy`（启动即播，不可中途控制）与 `symbolEffect`（布尔控制播放 / 数值触发一次）
  **二选一**，同一个图标不要混用。
- 运行时改样式用 `SymbolGlyphModifier` + `.attributeModifier()`：本 SDK 的构造器只接受可选 src，
  **不要**照抄文档的 `new SymbolGlyphModifier({ fontSize, fontColor })`；先建实例再赋值属性。

## Invariants（不要改）

- `module.json5`：`module.type` = `"entry"`、`mainElement` = `"EntryAbility"`、保留 `entity.system.home` + `ohos.want.action.home`、保留 `metadata` 里的 `ohos.arkui.UIMaterial.state`
- `entry/build-profile.json5`：`apiType` = `"stageMode"`；`compatibleSdkVersion` **固定 23（下限）**，`targetSdkVersion` 用已装 SDK。
- 版本红线：**不要写 <23 的兼容分支**（`canIUse` / 版本判断 / V1 降级）；>23 的 API（`uiMaterial` 26 等）必须 `deviceInfo.apiAvailable('x.y.z')` 守卫 + `try/catch` 降级。
- `EntryAbility.ets` 继承 `UIAbility`；`windowStage.loadContent('pages/Index')` 必须与 `main_pages.json` 首项一致
- 每个 `main_pages.json` 里的页面**恰好一个** `@Entry`

## 构建 / 运行

```bash
devecocli build        # 必须 BUILD SUCCESSFUL
devecocli run          # 装到真机/模拟器并启动
```

**真机安装需要签名**：模板的 `build-profile.json5` 刻意不带 `signingConfigs`。先在 DevEco Studio
里配置自动签名，或 `devecocli auth login` 后 `devecocli signature generate`。
`ohos.permission.DLP_GET_HIDE_STATUS`（防窥保护）是 `system_basic`，证书的 `allowed-acls` 必须带上，否则装不上。

## 平台限制（别硬刚）

- 沉浸光感（`hdsMaterial`）/ 点光源（`hdsEffect`）仅**手机、平板**；点光源不要放进滚动容器。
- **组件级沉浸光感**（通用属性 `systemMaterial`、菜单/弹窗 options 里的 `systemMaterial`、`lightEffect`）需要 `targetSdkVersion >= 26` 且 `uiMaterial.isImmersiveMaterialSupported()` 为真；本工程 `targetSdkVersion` 用已装 SDK，低版本/不支持时 `MaterialController` 统一返回 `undefined` 降级（不报错、不崩），标题栏/页面的 HDS `systemMaterialEffect` 不受影响。
- **材质等级只能查不能设**（`uiMaterial`）：`EXQUISITE` / `GENTLE` / `SMOOTH` 三档由设备算力决定，没有 `ADAPTIVE`、也没有 setter；
  `hdsMaterial` 可以设四档，但必须用 `ADAPTIVE`（低算力设备上强设高等级会卡顿发热），本工程 `params()` 已在 `SMOOTH` 设备上强制收敛。
- **通透玻璃**的性能与视觉边界：`systemMaterial` 只装饰当前组件（不继承），功耗上只保留少量小面积玻璃、不要在系统材质上再叠加一层；玻璃后面不要长期放视频/动图等持续变化的内容。设备算力等级不同、系统"光感强度"不同，效果本来就不同，不要试图强行统一。
- **模拟器**验不了沉浸视效、智感握姿、防窥保护，只会走降级分支（801）；这些要真机验。
