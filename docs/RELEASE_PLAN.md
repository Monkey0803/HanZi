# HanZi 应用市场上架收尾计划

> 本文档为完成度评估与上架收尾计划，只描述现状、缺口、实施路线与验收标准，不代表本轮已实施代码改动。

## Goal

把当前“可构建、可安装、可演示”的 HanZi 推进到“可提交 HarmonyOS 应用市场”的状态：

- 功能闭环完整：课本进度可见、单元复习可进入、错题本可完整浏览、学习设置可调。
- 发布工程化完整：clone 可复现构建、签名与密钥不泄露、权限最小化、release HAP 可签名安装。
- 合规材料完整：隐私政策、第三方声明、数据许可、应用市场素材、儿童/未成年人说明。
- 验收完整：构建、lint、ArkTS、单测、数据校验、真机/多设备、性能、无障碍全部有记录。

## Scope / Non-goals

### In scope

- 进度可视化：课本页、册详情、课详情、单元头的已学会统计。
- 复习闭环：单元复习入口、错题本完整页、错题复习。
- 学习设置：每日目标、笔顺速度、全局隐藏拼音、TTS 开关。
- 数据与许可：应用内数据模式/版本/来源/许可页、隐私政策页。
- 发布工程化：签名配置分离、应用标识、权限、release 构建、CI/本地验证脚本。
- 上架数据策略：release HAP 携带完整课程数据与许可文件；源码仓库仍只提交 seed。
- 市场材料：图标、截图、描述、分类、年龄分级、隐私政策、软件著作权/APP 备案清单。
- 验收：构建、lint、ArkTS、单测、数据校验、真机/模拟器、性能、无障碍。

### Non-goals

- 账号、云同步、班级/教师端。
- 在线课程更新、服务卡片、桌面小组件。
- 手写 OCR、整字识别。
- 繁体/日文/台湾笔顺版本。
- 本轮不重构导航模型、不迁移状态管理代际、不改 HDS 外壳结构。

## Current State And Constraints

### 已完成

- Phase 0–4 基本完成：基线工程、数据流水线、模型/仓库/启动、笔顺引擎、核心页面与导航。
- Phase 5 约 75%：复习卡、自评、错题预览、每日统计、RDB 进度已通；课本进度、单元复习入口、错题本完整页、学习设置、数据/许可页缺失。
- Phase 6 约 50%：响应式、深色、主题色、材质已接；性能/无障碍/真机验收未系统完成。
- 数据：`data/full` 本地已生成（12 册 / 301 课 / 2421 字 / 3870 笔顺字，`missingStrokes=0`）；`data/seed` 1 册 2 课可离线演示。
- 测试：14 个 Hypium 套件已编译；文档明确“未在设备上运行”。

### 关键约束

- 纯 ArkTS 状态管理 V2：`@ComponentV2` / `@Local` / `@Param` / `@Event` / `@ObservedV2` / `@Trace`；不引入 V1 装饰器。
- `compatibleSdkVersion` 固定 23，`targetSdkVersion` 26；不要写低于 23 的兼容分支。
- 颜色/文案/尺寸必须走 `resources/{base,dark,zh_CN}`；纯逻辑常量走 `common/constants`。
- 页面二级页根节点统一 `HdsNavDestination`；单 `NavPathStack`。
- 不新增网络依赖；当前 `HttpClient` / `NetworkStatus` 未被业务引用，`INTERNET` / `GET_NETWORK_INFO` 可移除。
- `DETECT_GESTURE` 被 `GripSensor` 使用；`DLP_GET_HIDE_STATUS` 未声明，防窥默认关闭。
- `build-profile.json5` 当前含本地签名证书路径与口令，且被 `.gitignore` 忽略；`docs/adoption-backup/build-profile.json5` 是 `signingConfigs: []` 的干净模板。
- `AppScope/app.json5` 仍是 `bundleName: com.example.hanzi`、`vendor: example`；`oh-package.json5` 描述仍是模板文案。
- 应用市场要求：隐私政策、权限用途说明、release 签名、应用截图/描述/分类/年龄分级；国内上架通常还需要软件著作权与 APP 备案（由开发者主体提供）。

## Design

### 1. 发布工程化（P0）

#### 1.1 签名与构建配置分离

- 新增 `build-profile.template.json5`：以 [docs/adoption-backup/build-profile.json5](adoption-backup/build-profile.json5) 为蓝本，保留 `signingConfigs: []`、`signingConfig: 'default'`、SDK 版本、`modules`（entry / toast_kit / keyboard_kit）。
- 根 `build-profile.json5` 继续由本地开发者持有，不提交；`.gitignore` 保留该行。
- README 增加“首次构建”说明：复制模板 → 在 DevEco Studio 配置自动签名，或 `devecocli auth login` + `devecocli signature generate`。
- 检查 git 历史：若 `build-profile.json5` 曾被提交，需从历史移除并更换签名材料；不要只依赖 `.gitignore`。

#### 1.2 应用标识与版本

- `AppScope/app.json5`：
  - `bundleName` 改为开发者自有包名（例如 `com.<vendor>.hanzi`，由用户确认）。
  - `vendor` 改为开发者/公司名。
  - `versionCode` 与 `versionName` 按上架版本设置（首版建议 `1000000` / `1.0.0`）。
- `oh-package.json5` 的 `description` 从模板文案改为 HanZi 描述。
- 检查 `AppScope/resources/base/element/string.json` 与 `zh_CN` 的 `app_name`，确保商店名称与桌面名称一致。

#### 1.3 权限最小化

- 删除 `module.json5` 的 `ohos.permission.INTERNET` 与 `ohos.permission.GET_NETWORK_INFO`；确认 `HttpClient` / `NetworkStatus` 无业务引用后一并删除。
- 保留 `ohos.permission.DETECT_GESTURE`，并把 `reason_detect_gesture` 改成用户可读说明：“用于识别握持手，优化单手操作布局；不采集、不上传”。
- 防窥 `DLP_GET_HIDE_STATUS` 不声明；上架版本在设置页隐藏防窥开关，或保留但明确标注“设备/证书不支持时不生效”。推荐隐藏，避免审核与用户预期问题。
- 上架前用 `devecocli check`/构建产物确认 `requestPermissions` 只剩必要项。

#### 1.4 Release 构建

- `entry/build-profile.json5` 的 release 混淆首版可保持关闭；若开启，先补 `obfuscation-rules.txt` 并回归全部页面。
- 新增 `scripts/verify.sh`（或 `tools/verify.mjs`）：依次执行 `ohpm install --all`、`devecocli build`、`devecocli check lint`、`devecocli check arkts`、`devecocli build --modules entry@ohosTest`、`npm run data:validate`。
- CI 可选：GitHub Actions 使用自托管 runner 或 DevEco CI 镜像；不要在普通 hosted runner 上假设 `devecocli` 可用。

### 2. 功能补齐（P1）

#### 2.1 课本/课/单元进度

- 新增纯函数 `service/ProgressAggregator.ets`：
  - `byLesson(items: CharProgress[], lessons: Lesson[]): Map<string, number>`
  - `byBook(items: CharProgress[], lessons: Lesson[]): Map<string, number>`
  - 只统计 `learned === true` 且 `lessonId` 非空的记录；便于单测，不依赖 RDB。
- `ProgressStore.ets`：
  - 增加 `@Trace learnedByLesson: Map<string, number>`、`@Trace learnedByBook: Map<string, number>`、`@Trace mistakeCounts: Map<string, number>`。
  - `refresh()` 中用 `ProgressAggregator` 重算并整体赋值新 Map（不要原地修改）。
  - 增加 `learnedOfLesson(lessonId)`、`learnedOfBook(bookId)`、`mistakeOf(char)` 读取方法。
- `BooksTabView.ets`：
  - 删除第 171/175/258 行的硬编码 `0`。
  - 今日卡片用 `progressStore.learnedCount` / `totalChars()`；册卡片用 `progressStore.learnedOfBook(book.id)` / `book.charCount`。
  - 进度条与文案随 `@Trace` Map 重算自动刷新。
- `BookDetailView.ets`：
  - `unitHeader` 增加“已学会 x / y”与小进度条。
  - `lessonRow` 增加“已学会 x / y”与细进度条；不要在 `LessonRowMeta` 缓存进度，改为 build 期调用 `progressStore.learnedOfLesson(lesson.id)`。
- `LessonDetailView.ets`：
  - 顶部增加本课进度；`charCell` 对已学会字加小对勾/色点。
- 单测：新增 `ProgressAggregator.test.ets`，覆盖空数据、重复字、无 lessonId、跨册聚合。

#### 2.2 单元复习入口

- `BookDetailView.ets` 的 `unitHeader` 增加“生字复习”按钮：
  - `pushPathByName(RouterConstants.PAGE_REVIEW_SESSION, new ReviewRouteParam(ReviewMode.UNIT, this.bookId, unit.index, ReviewConstants.DEFAULT_LIMIT, ReviewCardMode.CHAR))`。
- `ReviewViewModel.ets` 的 `unitCandidates` 改为“该单元全部生字，已学会的排前面”，不再只取已学会字；这样新单元也能直接复习。
- `Index.pageMap` 的复习会话标题按 mode 区分：全局/单元/错题分别用不同字符串资源。
- 验收：册详情 → 单元头“生字复习” → 复习卡 → 自评 → 返回，队列与统计正确。

#### 2.3 错题本完整页

- 新增 `RouterConstants.PAGE_MISTAKES = 'mistakes'`。
- 新增 `views/review/MistakeBookView.ets`：
  - 读 `progressStore.mistakeChars` 与 `progressStore.mistakeOf(char)`。
  - 列表项：`HanziGridCell` + 拼音（`curriculumRepository.character`）+ 课名（`progressStore.lessonOf`）+ 错误次数。
  - 点击进 `CharDetailView`；底部“开始错题复习”进 `ReviewSessionView`（`ReviewMode.MISTAKE`）。
  - 空态文案与返回。
- `ReviewTabView.ets` 的 `mistakeSection` 增加“查看全部”入口。
- `Index.pageMap` 增加 `PAGE_MISTAKES` 分支；新增字符串资源。

#### 2.4 学习设置

- `AppSettings.ets` 增加：
  - `@Trace dailyGoal: number = 10;`
  - `@Trace strokeSpeed: string = StrokeSpeedId.STANDARD;`
  - `@Trace hidePinyin: boolean = false;`
  - `@Trace ttsEnabled: boolean = true;`
- `PreferencesConstants.ets` 增加 key；`SettingsStore.ets` 读写并做范围归一。
- `SettingsViewModel.ets` 增加 `setDailyGoal` / `setStrokeSpeed` / `setHidePinyin` / `setTtsEnabled`。
- `SettingsOptions.ets` 增加：
  - `DAILY_GOAL_OPTIONS`：5 / 10 / 15 / 20。
  - `STROKE_SPEED_OPTIONS`：慢 / 标准 / 快。
- `SettingsRows.ets` 的 `SettingField` 增加 `HIDE_PINYIN` / `STROKE_SPEED` / `DAILY_GOAL` / `TTS`，并在 `currentId()` / `isOn()` 登记。
- `SettingsStudySection.ets` 增加四行：隐藏拼音、笔顺速度、每日目标、语音朗读。
- 接线：
  - `ReviewTabView.ets` 的 `ReviewConstants.DAILY_GOAL` 改为 `appSettings.dailyGoal`。
  - `CharDetailView.ets` 与 `PracticeView.ets` 给 `StrokeCanvas` 传 `strokeDuration`，由 `StrokeSpeed.durationOf(appSettings.strokeSpeed)` 计算。
  - `LessonDetailView.ets` 的 `hidePinyin` 改为直接读 `appSettings.hidePinyin`，Toggle 调 `settingsViewModel.setHidePinyin`。
  - `TtsService.init/speak` 与 `CharDetailView.showSpeak()` / `LessonDetailView` 的 `canSpeak` 增加 `appSettings.ttsEnabled` 判断。
- 单测：`SettingsOptions.test.ets` 增加新选项表断言；`Constants.test.ets` 如涉及默认值同步更新。

#### 2.5 数据与许可页、隐私政策页

- 新增路由：`PAGE_ABOUT_DATA`、`PAGE_PRIVACY`、`PAGE_LICENSE`。
- `SettingsTabView.ets` 增加 `@Param navPathStack`；`Index.ets` 的 `settingsContent()` 传入 `this.navPathStack`。
- `SettingsAboutSection.ets` 增加“数据与许可”“隐私政策”两个 `NavSettingRow`，通过 `@Event` 上报。
- 新增 `views/settings/AboutDataView.ets`：
  - 展示 `appBootstrap.dataMode`、`curriculumRepository.meta(...)` 的 `dataVersion` / `books` / `lessons` / `uniqueChars` / `generatedAt` / `strokeChars` / `missingStrokes` / `catalogChars`。
  - 展示数据来源与许可摘要；许可全文入口跳 `LicenseTextView`。
- 新增 `views/settings/PrivacyPolicyView.ets`：读取 `rawfile/privacy_policy.txt`，用 `Scroll` + `Text` 展示。
- 新增 `views/settings/LicenseTextView.ets`：按 `LicenseRouteParam(fileName)` 读取 `rawfile/data/<mode>/licenses/<fileName>` 并展示。
- 新增 `model/RouteParams.ets` 的 `LicenseRouteParam`。
- 新增 `entry/src/main/resources/rawfile/privacy_policy.txt`；根目录新增 `PRIVACY.md` 供商店托管。
- 新增字符串资源（base + zh_CN）：`settings_about_data`、`settings_privacy`、`about_data_*`、`privacy_*`、`license_*`。

#### 2.6 模板死代码清理（可选，建议单独提交）

- 删除未引用页面：`HomeTabView.ets`、`ImageTabView.ets`、`ImagePreviewView.ets`、`DetailPageView.ets`。
- 删除未引用服务/模型：`ImageSupport.ets`、`BackgroundViewModel.ets`、`HttpClient.ets`、`NetworkStatus.ets`（确认无引用后）。
- 删除 `DomainConstants.ets` 的 `IMAGE_DOMAIN`、`NavigationConstants.ets` 的 `IMAGES`、`RouterConstants` 的 `PAGE_DETAIL` / `PAGE_PREVIEW`，并清理 `Index.ets` 对应 import / builder / 分支 / `boundScrollers`。
- 删除 `ImageSupport.test.ets` 与 `List.test.ets` 的注册。
- 每删一组跑一次 `devecocli build`，避免一次性大改。

### 3. 上架数据策略（P0，产品决策）

当前 README 写的是“官方 release 只含 seed”，但 seed 只有 1 册 2 课，无法作为面向学生的上架应用。建议：

- **源码仓库**：继续只提交 `data/seed/`，`data/full/` 保持 gitignore。
- **Release HAP**：构建前运行 `cd tools && npm run data:all` 生成 `data/full/`，把完整课程数据与 `data/licenses/` 一起打进 HAP。
- 更新 README / DATA_LICENSE / THIRD_PARTY_NOTICES：明确“源码仓库只含 seed；应用市场 release 包包含本地生成的 full 数据，并随包保留 Arphic / LGPL / MIT 许可文本”。
- 新增 `scripts/build-release.sh`：
  1. `cd tools && npm ci && npm run data:all`
  2. `cd .. && devecocli build`（release 模式，具体参数先 `devecocli build --help` 确认）
  3. 校验 HAP 内包含 `data/full/curriculum/meta.tsv` 与 `data/full/licenses/*`。
- 若法务不接受 full 数据随包分发，则退化为“上架包内置更大规模的自有/授权字表”，但仍需保证不是 2 课演示版。

### 4. 市场合规与材料（P0）

- 隐私政策（`PRIVACY.md` + 应用内页）至少写明：
  - 不收集账号、位置、通讯录、设备标识等个人信息；无广告、无统计分析 SDK。
  - 本地存储：设置（preferences）、学习进度（RDB）、课程/笔顺数据（rawfile）。
  - 权限：`DETECT_GESTURE` 用于握持手识别；TTS 使用系统离线能力；无网络权限。
  - 第三方：HarmonyOS HDS / UIDesignKit、CoreSpeechKit、MultimodalAwarenessKit、本地 toast-kit / keyboard-kit；不包含收集个人信息的第三方 SDK。
  - 儿童/未成年人：面向小学生；不收集个人信息；建议监护人陪同使用。
  - 联系方式：开发者邮箱（由用户填写）。
- `module.json5` 权限 `reason` / `usedScene` 与隐私政策一致。
- 应用市场素材：
  - 应用名称、图标（layered image）、简介、详细描述、分类（教育）、年龄分级。
  - 手机/平板、浅色/深色截图各一组；建议覆盖首页、册详情、课详情、字详情、描红、复习、设置。
  - 隐私政策托管地址（由开发者在 AppGallery Connect 填写）。
  - 软件著作权证书、APP 备案信息（国内上架，由开发者主体提供）。
- 数据合规：release 包内保留 `data/licenses/`；`THIRD_PARTY_NOTICES.md` 与 `DATA_LICENSE.md` 更新到“release 包含 full 数据”的口径。

### 5. 质量与验收（P0）

- 构建：`devecocli build` 必须 `BUILD SUCCESSFUL`。
- 静态检查：`devecocli check lint` 0 error；`devecocli check arkts` 无新增真实错误（`nav-destination-root-node` 为已知误报）。
- 单测：`devecocli build --modules entry@ohosTest` 通过，并在模拟器/真机运行全部 Hypium 套件。
- 数据校验：`npm run data:validate` 退出码 0；full 数据 12 册、课号唯一、每字有笔画、strokes/medians 对齐。
- 设备矩阵：手机、平板、2in1；浅色/深色；seed/full；离线。
- 真机能力：沉浸光感、智感握姿、防窥（若保留）、TTS 按降级分支验收；模拟器只验降级。
- 性能：冷启动 < 2s、字详情笔顺 < 100ms、动画 ≥ 30fps、内存 < 200MB（中端机）。
- 无障碍：Canvas `accessibilityText`、按钮文案、触控区域 ≥ 44vp、错误/成功不只靠颜色、屏幕阅读器走查。
- 发布包：release HAP 签名校验通过；干净设备安装启动；确认数据模式为 full；确认无网络请求。

## Key Files

| 文件 | 作用 |
|---|---|
| `build-profile.template.json5` | 新增：无签名的可提交构建模板 |
| `build-profile.json5` | 本地签名配置（不提交） |
| `.gitignore` | 保持忽略本地签名与 full 数据 |
| `AppScope/app.json5` | bundleName / vendor / version |
| `oh-package.json5` | 应用描述 |
| `entry/src/main/module.json5` | 权限最小化与用途说明 |
| `entry/src/main/ets/service/ProgressStore.ets` | 进度聚合与派生状态 |
| `entry/src/main/ets/service/ProgressAggregator.ets` | 新增：纯函数进度聚合 |
| `entry/src/main/ets/service/ProgressRepository.ets` | 进度 SQL（如需新增查询） |
| `entry/src/main/ets/views/books/BooksTabView.ets` | 首页进度接线 |
| `entry/src/main/ets/views/books/BookDetailView.ets` | 册/单元/课进度与单元复习入口 |
| `entry/src/main/ets/views/books/LessonDetailView.ets` | 课进度、隐藏拼音、TTS 开关 |
| `entry/src/main/ets/views/review/ReviewTabView.ets` | 每日目标、错题本入口 |
| `entry/src/main/ets/views/review/MistakeBookView.ets` | 新增：错题本完整页 |
| `entry/src/main/ets/viewmodel/ReviewViewModel.ets` | 单元复习队列 |
| `entry/src/main/ets/model/AppSettings.ets` | 新增学习设置字段 |
| `entry/src/main/ets/model/SettingsOptions.ets` | 每日目标/笔顺速度选项 |
| `entry/src/main/ets/common/constants/PreferencesConstants.ets` | 新设置 key |
| `entry/src/main/ets/service/SettingsStore.ets` | 新设置读写 |
| `entry/src/main/ets/viewmodel/SettingsViewModel.ets` | 新设置 setter |
| `entry/src/main/ets/views/settings/SettingsRows.ets` | 新设置行字段登记 |
| `entry/src/main/ets/views/settings/SettingsStudySection.ets` | 新设置行 |
| `entry/src/main/ets/views/settings/SettingsAboutSection.ets` | 数据/许可/隐私入口 |
| `entry/src/main/ets/views/settings/AboutDataView.ets` | 新增：数据与许可页 |
| `entry/src/main/ets/views/settings/PrivacyPolicyView.ets` | 新增：隐私政策页 |
| `entry/src/main/ets/views/settings/LicenseTextView.ets` | 新增：许可全文页 |
| `entry/src/main/ets/pages/Index.ets` | 新路由接线、死代码清理 |
| `entry/src/main/ets/common/constants/RouterConstants.ets` | 新路由名 |
| `entry/src/main/resources/rawfile/privacy_policy.txt` | 新增：应用内隐私政策文本 |
| `PRIVACY.md` | 新增：商店托管隐私政策 |
| `README.md` | 构建、签名、release 数据策略 |
| `DATA_LICENSE.md` | release 包含 full 数据的许可口径 |
| `THIRD_PARTY_NOTICES.md` | 第三方声明更新 |
| `scripts/verify.sh` | 新增：本地一键验证 |
| `scripts/build-release.sh` | 新增：生成 full 数据 + release 构建 |

## Execution Sequence

### Phase A：发布工程化（先做，避免后续返工）

1. 新增 `build-profile.template.json5`，确认 `signingConfigs: []`；README 补“首次构建/签名”说明。
2. 检查 git 历史中的签名材料；若已提交，按团队流程清理并更换证书。
3. 更新 `AppScope/app.json5` 的 `bundleName` / `vendor` / 版本；更新 `oh-package.json5` 描述。
4. 删除未使用权限；更新 `DETECT_GESTURE` 的 `reason`；确认构建通过。
5. 新增 `scripts/verify.sh`，跑通当前基线。

**验收**：`devecocli build` 成功；`requestPermissions` 只剩必要项；模板 + 本地签名可复现构建。

### Phase B：进度与复习闭环

6. 新增 `ProgressAggregator` + 单测。
7. 扩展 `ProgressStore` 的 `learnedByLesson` / `learnedByBook` / `mistakeCounts`。
8. 接线 `BooksTabView` / `BookDetailView` / `LessonDetailView` 进度展示。
9. `BookDetailView` 增加单元复习入口；调整 `ReviewViewModel.unitCandidates`。
10. 新增 `MistakeBookView` + 路由 + 复习页入口。

**验收**：首页/册/课/单元进度随描红与标记实时变化；单元复习、错题本、错题复习全链路可用。

### Phase C：学习设置与数据/许可页

11. 扩展 `AppSettings` / `PreferencesConstants` / `SettingsStore` / `SettingsViewModel`。
12. 新增 `DAILY_GOAL_OPTIONS` / `STROKE_SPEED_OPTIONS`，登记 `SettingField`。
13. 补 `SettingsStudySection` 四行；接线每日目标、笔顺速度、隐藏拼音、TTS。
14. 新增 `AboutDataView` / `PrivacyPolicyView` / `LicenseTextView` 与路由。
15. 新增 `PRIVACY.md` 与 `rawfile/privacy_policy.txt`；补字符串资源。

**验收**：设置重启后保留；每日目标/笔顺速度/隐藏拼音/TTS 生效；数据/许可/隐私页可达。

### Phase D：上架数据与材料

16. 新增 `scripts/build-release.sh`：生成 full 数据 → release 构建 → 校验 HAP 内容。
17. 更新 README / DATA_LICENSE / THIRD_PARTY_NOTICES 的 release 数据口径。
18. 准备应用市场素材：截图、描述、分类、年龄分级、隐私政策托管、软著/备案。
19. 可选：清理模板死代码（单独提交，逐组构建验证）。

**验收**：release HAP 内含 full 数据与许可文件；材料清单齐全。

### Phase E：验收与发布

20. 跑 `scripts/verify.sh`：构建、lint、ArkTS、单测编译、数据校验。
21. 在模拟器/真机运行全部单测；记录结果。
22. 手机/平板/2in1、浅色/深色、seed/full、离线全矩阵走查；截图。
23. 性能与无障碍检查；记录指标。
24. 生成 release 签名与 HAP；干净设备安装验证。
25. 上传 AppGallery Connect，填写材料，提交审核；发布后监控崩溃/评论。

## Verification

| 检查 | 命令/方法 | 通过标准 |
|---|---|---|
| 主工程构建 | `devecocli build` | `BUILD SUCCESSFUL`，0 error |
| Lint | `devecocli check lint` | `Errors: 0`（既有 warning 记录在案） |
| ArkTS 检查 | `devecocli check arkts` | 无新增真实错误；已知误报单独记录 |
| 单测编译 | `devecocli build --modules entry@ohosTest` | `BUILD SUCCESSFUL` |
| 单测运行 | DevEco 测试运行器 / `devecocli` 测试命令 | 全部 Hypium 套件通过 |
| 数据校验 | `cd tools && npm run data:validate` | 退出码 0；12 册、课号唯一、每字有笔画 |
| 进度聚合单测 | `ProgressAggregator.test.ets` | 空数据/重复/跨册用例通过 |
| 设置持久化 | 改每日目标/速度/开关后重启 | 设置保持；行为生效 |
| 进度可视化 | 描红/标记后返回首页/册/课 | 进度数字与进度条更新 |
| 单元复习 | 册详情 → 单元头 → 复习 | 队列为该单元生字，自评后统计更新 |
| 错题本 | 复习页 → 查看全部 → 错题复习 | 列表完整、可进字详情、可开始错题复习 |
| 数据/许可/隐私页 | 设置 → 关于 | 数据模式/版本/许可/隐私文本可读 |
| Release 数据 | 解包 release HAP | 含 `data/full/curriculum/meta.tsv` 与 `data/full/licenses/*` |
| 权限 | 检查 `module.json5` 与安装包 | 仅保留必要权限；无 INTERNET/GET_NETWORK_INFO |
| 离线 | 飞行模式重启 | 核心链路全部可用，无网络请求 |
| 多设备 | 手机/平板/2in1 | 布局、安全区、页签/侧栏正常 |
| 深色 | 设置 → 深色 | 全站颜色正确，Canvas 墨色/网格可见 |
| 真机能力 | 真机走查 | 沉浸光感/握姿/TTS 按降级分支表现一致 |
| 性能 | 真机计时/帧率 | 冷启动 < 2s；字详情 < 100ms；动画 ≥ 30fps |
| 无障碍 | 屏幕阅读器/对比度/触控 | 按钮可读、Canvas 有描述、触控 ≥ 44vp |
| 发布签名 | 签名校验 + 干净设备安装 | 安装启动成功，版本号正确 |

## Risks And Compatibility

| 风险 | 影响 | 缓解 |
|---|---|---|
| seed-only 上架 | 应用只有 2 课，审核/用户价值不足 | release 包携带 full 数据；源码仓库仍只提交 seed |
| full 数据许可 | Arphic/LGPL/MIT 归属缺失会被投诉 | 随包保留 `data/licenses/*`；更新 DATA_LICENSE / THIRD_PARTY_NOTICES；上架前做法务确认 |
| 签名材料泄露 | 证书被盗用 | 模板与本地配置分离；清理 git 历史；更换证书 |
| 权限审核 | INTERNET/GET_NETWORK_INFO 无用途被拒 | 删除未使用权限；DETECT_GESTURE 写清用途 |
| 隐私政策缺失 | 市场审核不通过 | 新增 `PRIVACY.md` + 应用内页 + 商店托管地址 |
| 儿童/未成年人合规 | 审核问询 | 明确不收集个人信息、无广告、监护人陪同说明 |
| 防窥 ACL | `DLP_GET_HIDE_STATUS` 导致安装失败 | 上架版本不声明；设置页隐藏或标注不支持 |
| 2in1 审核 | 自由窗口适配不完整 | 单独走查 2in1；必要时首版只声明 phone/tablet |
| TTS/传感器能力差异 | 部分设备不可用 | 保持 `available=false` 降级；不阻塞核心流程 |
| 性能低端机 | 动画掉帧 | 双层 Canvas、分片 LRU、30fps；必要时降级为逐笔静态 |
| RDB 迁移 | 升级丢进度 | 本轮不改表结构；只加 preferences key，默认值兼容 |
| 死代码清理误删 | 构建失败 | 分组删除、每组构建；保留 `docs/adoption-backup/` 参考 |

## Rollback

- 每个 Phase 结束提交一次 git；失败时 `git reset --hard` 回上一个绿色提交。
- 发布工程化回滚：恢复原 `build-profile.json5`、`module.json5`、`AppScope/app.json5`、`oh-package.json5`；删除 `build-profile.template.json5` 与 `scripts/` 新增文件。
- 功能回滚：进度/复习/设置/数据页按 Phase 分提交，可单独 revert；`ProgressStore` 新增字段不影响旧数据。
- 数据回滚：删除 `entry/src/main/resources/rawfile/data/full/` 即回退 seed；App 仍可启动并显示“演示数据”。
- 发布回滚：保留上一版 release HAP 与签名材料；审核失败时修复后递增 `versionCode` 重新提交，不删除证书。
- 若签名材料曾进入 git 历史：立即吊销并更换证书，按团队安全流程清理历史后再公开仓库。
