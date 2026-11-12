---
name: HanZi HarmonyOS App
overview: 基于 HarmonyOS HDS + ArkTS 状态管理 V2，构建离线可用、可开源复现的小学语文 12 册生字学习 App；公开仓库与发布物只带 seed 演示数据，完整课程数据由使用者本地生成、不随仓库分发。
todos:
  - 复制 ScaffoldApp 生成 HanZi 基线工程并通过构建
  - 建立 MIT 代码许可、第三方声明、数据许可与 seed-only 开源策略
  - 实现课程抓取、makemeahanzi 合并、seed/full 数据与校验流水线
  - 实现课程模型、TSV 数据仓库、笔顺分片加载
  - 实现 SVG path 解析、Canvas 笔顺渲染、动画与描红判分
  - 实现课本/课文/字详情核心页面与单栈导航
  - 实现练习记录、RDB 进度、复习卡与错题本
  - 实现搜索、多音字/同音字、学习设置与可选 TTS
  - 完成响应式、深色模式、性能与无障碍优化
  - 执行构建、lint、ArkTS 检查、数据校验、单测与真机验收
---

# HarmonyOS 小学语文汉字学习 App 实施计划

## Goal

在 `/Users/huxiaohui/Documents/YostarWork/Github/HM/HanZi` 从零生成一个可安装、可离线运行、可开源复现的 HarmonyOS App，把三份能力的核心体验组合起来：

- **课程体系**：采用公开的「人教版（部编版）小学语文 12 册」教材生字/词语表（MIT 数据集），按册 → 单元 → 课组织。
- **笔顺与字形**：来自 skishore/makemeahanzi 的 `graphics.txt`（笔画轮廓 + median）和 `dictionary.txt`（部首、部件拆解）。
- **学习交互**：参考 chanind/hanzi-writer 的笔顺动画、描红练习、按笔顺判分，用 ArkTS + Canvas 原生重写，不引入 WebView。

最终形态：课本 → 单元 → 课文 → 字详情 → 笔顺动画/描红 → 学习记录/复习卡，全链路离线可用；代码以 MIT 开源。**公开仓库与官方 release 只包含 seed 演示数据；完整课程数据仅在本地生成、个人学习使用，不提交、不分发。**

## Scope / Non-goals

### In scope

- 12 册课本浏览、课文生字、会写字、组词、多音字、同音字、同部首字（完整数据需本地生成 full）。
- 字详情：笔顺动画、逐笔展示、描红练习、判分、错误提示。
- 学习闭环：练习记录、已学会、待复习、错题本、每日目标、连续天数。
- 查字：汉字、带声调/不带声调拼音、词语。
- 设置：隐藏拼音、笔顺速度、每日目标、深浅色/主题色沿用脚手架、数据模式与许可说明。
- 手机 + 平板响应式；离线运行；深色模式。
- 开源仓库：MIT 代码许可、README、数据生成脚本、seed 数据、第三方许可说明、可选 CI。

### Non-goals

- 账号、云同步、班级/教师端。
- 打印听写单/描红纸、PDF 导出。
- 手写识别/OCR（只做笔顺匹配判分，不做整字识别）。
- 繁体字课程、日文/台湾笔顺版本。
- 运行时联网更新课程数据。
- 服务卡片、通知、桌面小组件。
- 公开仓库/官方 release 默认只携带 seed 演示数据（full 可由公开数据集在本地生成）。

## Open Source Strategy

> 本项目会开源；课程数据来自 MIT 许可的公开教材生字表，发布时保留来源与许可声明即可。

### 代码

- 根目录新增 `LICENSE`：MIT（版权年份 2026，版权人可由用户确认后填写）。
- 新增 `THIRD_PARTY_NOTICES.md`：列出 HDS/Scaffold 依赖、hanzi-writer（MIT，算法参考）、makemeahanzi（Arphic/LGPL 数据）、公开教材生字表（MIT）。
- 新增 `README.md`：项目简介、构建命令、数据生成命令、seed/full 数据说明、截图、许可摘要。
- 新增 `.gitignore`：忽略 `tools/node_modules/`、`tools/cache/`、`entry/src/main/resources/rawfile/data/full/`、`*.hap`、`.hvigor/`、`build/`。
- 可选 `.github/workflows/build.yml`：用 seed 数据跑 `devecocli build` + `check lint` + 单测；full 数据生成不进 CI。

### 数据（seed 随仓库，full 本地生成）

- **seed 数据**（提交到仓库、进入官方 release）：`entry/src/main/resources/rawfile/data/seed/`。
  - 从 full 数据裁剪一年级上册前两课，含字表、拼音、组词与对应笔画分片。
  - 保证 clone 后零网络可构建、可演示、可跑单测。
- **full 数据**（默认不提交）：`entry/src/main/resources/rawfile/data/full/`。
  - 由 `tools/fetch-textbook.mjs` + `build-curriculum.mjs` + `build-hanzi-data.mjs` 在本地生成。
  - 课程来源为 MIT 许可的公开教材生字表；生成后可自行构建 HAP，再分发时保留 MIT 归属。
- App 启动时优先读 `data/full/`，读不到回退 `data/seed/`；设置页显示「完整数据（本地）/ 演示数据」。
- `DATA_LICENSE.md` 明确：
  - makemeahanzi `graphics.txt`：Arphic Public License，随附 `ARPHICPL.txt`。
  - makemeahanzi `dictionary.txt`：Unihan/CJKlib 来源，随附 `COPYING.txt` / `LGPL.txt`。
  - hanzi-writer：MIT，随附 `LICENSE-hanzi-writer.txt`；仅参考算法，不直接复制 JS 代码。
  - 课程数据：athenayan123-web/dictation-robot，MIT，随附 `CHINESE_TEXTBOOK_MIT.txt`。

### 发布门禁

- 公开 release 前检查：`LICENSE`、`THIRD_PARTY_NOTICES.md`、`DATA_LICENSE.md`、`data/licenses/` 齐全。
- 默认发布物只含 `data/seed/`；如需携带 full，必须同时保留 MIT 与 makemeahanzi 的许可文件。
- README 中说明「如何本地生成完整数据」与数据来源。
- 检查 git 历史中没有误提交的 full 数据；如误提交，需要清理历史后再公开。

## Current State And Constraints

- 当前工作区 `HanZi` 是空目录；同目录下已有可编译的 `ScaffoldApp` 基线。
- `ScaffoldApp` 提供：HDS 外壳（`HdsTabs` / `HdsNavigation` / `HdsNavDestination` / `HdsSideBar`）、纯状态管理 V2、主题/主题色/沉浸材质、设置页、Toast/Keyboard 本地 HAR。
- API：`compatibleSdkVersion` 6.1.0(23)，`targetSdkVersion` 26.0.0；不要引入低于 23 的替代实现。
- ArkTS 约束：只用 V2（`@ComponentV2` / `@Local` / `@Param` / `@Event` / `@ObservedV2` / `@Trace` / `@Monitor`）；禁止 `@Component`、`@State`、`@Prop`、`@Link`、`@Provide`、`@Consume`、`@Observed`、`@ObjectLink`、`@Watch`、`AppStorage`、`LocalStorage`、`PersistentStorage`；禁止 `HdsListItem`。
- Canvas 没有原生 SVG path 解析，需要自己把 SVG path 转成 Canvas 2D 命令；`CanvasRenderingContext2D` 支持 `moveTo/lineTo/quadraticCurveTo/bezierCurveTo/arc/closePath/fill/clip/setTransform` 等能力。
- 数据许可：`graphics.txt` 为 Arphic Public License，`dictionary.txt` 来自 Unihan/CJKlib（仓库含 COPYING/LGPL），hanzi-writer 为 MIT，课程生字表来自 MIT 数据集。**公开仓库默认只提交 seed 数据与生成脚本。**
- 脚手架 `module.json5` 含 `ohos.permission.DLP_GET_HIDE_STATUS`（system_basic），可能导致自动签名安装失败；本 App 不需要防窥，生成后删除该权限条目即可，其余功能不受影响。
- 目标路径已存在但为空；`create-app.mjs` 对已存在目录会返回 `PROJECT_EXISTS`，确认空目录后使用 `--force`，或先生成到 `HanZiApp` 再改名。

## Design

### 1. 产品结构与导航

采用脚手架的单 `NavPathStack` + HDS 外壳，底部三页签 / 宽屏侧栏：

| 页签 | 内容 |
|---|---|
| 课本 | 12 册课本卡片、继续学习、今日目标、查字入口 |
| 复习 | 今日复习、错题本、学习统计、开始复习 |
| 设置 | 外观/材质沿用脚手架，新增「学习设置」「数据来源与许可」 |

二级页（全部用 `HdsNavDestination`，根节点不要改成普通 `NavDestination`）：

- `BookDetailView`：一册的单元/课文列表。
- `LessonDetailView`：本课生字、会写字、词语、组词。
- `CharDetailView`：笔顺画布、描红、读音、字形、组词。
- `ReviewSessionView`：复习卡/看拼音写字/单元复习。
- `SearchView`：查字与拼音。
- `SettingsStudyView`、`AboutDataView`、`LicensesView`。

路由参数用强类型 class（`BookRouteParam` / `LessonRouteParam` / `CharRouteParam` / `ReviewRouteParam`），通过 `pushPathByName(name, param)` 传入；`Index.pageMap` 只在边界处把 `pageInfos` 断言成具体参数类型，业务层不扩散 `as`。

### 2. 数据流水线（构建期，不进入 App 运行时）

新增 `tools/` Node 工程（`tools/package.json`，依赖 `cheerio`）。full 产物写入 `entry/src/main/resources/rawfile/data/full/`（默认 gitignore）；seed 数据提交到 `data/seed/`。脚本只用于开发/构建，不进入 HAP。

抓取范围（控制请求量）：

1. 下载 `athenayan123-web/dictation-robot` 的 `server/data/chinese_textbook.json`（MIT）：12 册 → 单元 → 课 → 生字/词语。
2. 由课程字表生成 `books/lessons/lesson_chars/characters_base`；拼音、部首、部件由 makemeahanzi `dictionary.txt` 补齐。
3. 多字词语同时写入 `words.tsv` 作为组词；同音字、同部首字由本地索引计算，不额外抓字详情页。

脚本行为：

- `npm run data:fetch` → `node tools/fetch-textbook.mjs`：下载教材生字表与 MIT 许可文本到 `tools/cache/` 与 `tools/licenses/`；支持 `--refresh`。
- `npm run data:curriculum` → `node tools/build-curriculum.mjs`：把 JSON 转成 App 的 TSV，并补齐拼音/部首/部件。
- `npm run data:build` → `build-curriculum.mjs` + `node tools/build-hanzi-data.mjs`：合并 makemeahanzi 的 `graphics.txt`、`dictionary.txt`，只保留课程字，输出笔画分片。
- `npm run data:validate` → `node tools/validate-data.mjs`：校验 12 册、课号唯一、拼音完整、每个课程字都有笔画数据、`strokes.length === medians.length`、路径以 `M` 开头且无制表符/换行。
- `npm run data:all`：依次执行 fetch/curriculum/hanzi/validate；默认输出 `rawfile/data/full/`。
- `npm run data:seed`：从 full 裁剪一年级上册前两课到 `rawfile/data/seed/`，用于 clone 后零网络构建与 CI。

输出格式用 **TSV/分行文本**，避免 ArkTS 大量 JSON 动态属性访问：

```text
data/full/curriculum/books.tsv
id	grade	term	title	lessonCount	charCount	writeCount
1a	1	1	一年级上册	41	300	100

data/full/curriculum/lessons.tsv
lessonId	bookId	unit	order	title
G1A01	1a	1	1	识字1：天地人

data/full/curriculum/lesson_chars.tsv
lessonId	char	pinyin	isWrite
G1A01	天	tiān	1

data/full/curriculum/characters.tsv
char	pinyins(;)	radical	decomposition
天	tiān	大	⿱一犬

data/full/curriculum/words.tsv
char	word	readingPinyin
地	地方	dì

data/full/curriculum/readings.tsv
char	pinyin	lessonId
地	de	G1A22

data/full/strokes/shard-00.tsv ... shard-31.tsv
char	strokeCount	strokePath1	strokePath2	...	median1|median2|...
天	4	M...	M...	M...	M...	x,y;x,y|x,y;x,y|...
```

- 分片规则：`shard = char.charCodeAt(0) % 32`，App 端不需要额外索引文件。
- 每个 median 编码为 `x,y;x,y`，多笔用 `|` 分隔；`strokeCount` 用于校验字段数。
- `meta.tsv` 保存 `dataMode`（full/seed）、`dataVersion`、`sourceDate`、`books`、`lessons`、`uniqueChars`、`generatedAt`，App 设置页展示。
- 许可文件复制到 `data/licenses/ARPHICPL.txt`、`COPYING.txt`、`LGPL.txt`、`LICENSE-hanzi-writer.txt`、`CHINESE_TEXTBOOK_MIT.txt`。
- seed 数据使用同样的目录结构，放在 `data/seed/`；内容为一年级上册前两课及对应笔画分片。

### 3. 数据层

目录遵循脚手架依赖方向：`views → viewmodel → service → model`。

- `model/CurriculumModels.ets`：`Book`、`Unit`、`Lesson`、`LessonChar`、`CharacterEntry`、`Reading`、`WordEntry`。
- `model/StrokeModels.ets`：`Point`、`PathOp`、`PathCommand`、`StrokeData`、`StrokeMatchResult`、`StrokeTheme`。
- `model/ProgressModels.ets`：`CharProgress`、`LessonProgress`、`PracticeStats`、`ReviewRating`。
- `model/RouteParams.ets`：各类路由参数，全部有默认构造。
- `service/DataRootResolver.ets`：优先尝试 `data/full/curriculum/books.tsv`，不存在则回退 `data/seed/curriculum/books.tsv`；缓存当前根路径与 `dataMode`。
- `service/CurriculumRepository.ets`：一次性读取 `curriculum/*.tsv` 到内存（约 1 MB），构建 `Map`；提供 `books()`、`book(id)`、`lesson(id)`、`character(char)`、`wordsFor(char)`、`readingsFor(char)`、`homophones(char)`、`sameRadical(char)`。
- `service/HanziDataRepository.ets`：按 `charCode % 32` 读取 `<dataRoot>/strokes/shard-XX.tsv`；每个分片解析成 `Map<string, StrokeData>`；LRU 缓存最多 4 个分片；解析时顺便把每条 SVG path 解析成 `PathCommand[]`。数据缺失返回 `null`，UI 显示「暂无笔顺」并禁用描红。
- `service/ProgressRepository.ets` + `service/AppDatabase.ets`：RDB 持久化，见第 6 节。
- `service/AppBootstrap.ets`：`@ObservedV2` 单例，`state: 'idle'|'loading'|'ready'|'error'`；启动时依次 `dataRoot.resolve()`、`curriculum.load()`、`database.open()`、`progress.load()`。`Index.aboutToAppear` 调用一次；失败显示错误与「重试」。
- `service/PinyinUtils.ets`：声调去音、`ü`/`v` 归一、拼音拆分；纯函数，单元测试覆盖。
- `service/CharacterRelations.ets`：同音字按读音分组；同部首字按 `radical` 分组；形近字用 `decomposition` 的部件集合求交集（首版可只展示同部首，形近字放第二阶段）。
- `service/SearchService.ets`：汉字精确、拼音（带调/不带调）、词语包含；3000 字规模在内存中完成，输入 150ms 防抖。
- `service/TtsService.ets`：可选；`textToSpeech.createEngine({ language: 'zh-CN', online: 0 })`，失败则 `available=false`，隐藏喇叭按钮；不阻塞核心流程。

读取 rawfile 的方式：

```ts
const bytes: Uint8Array = await context.resourceManager.getRawFileContent('data/full/curriculum/books.tsv');
const text: string = util.TextDecoder.create('utf-8').decodeToString(bytes);
```

### 4. 笔顺引擎（核心）

#### 4.1 SVG path 解析

`service/SvgPathParser.ets`：

- 支持 `M/m L/l H/h V/v C/c S/s Q/q T/t A/a Z/z`，处理隐式重复命令和相对坐标。
- 输出 `PathCommand[]`，只保留 `MOVE / LINE / QUAD / CUBIC / CLOSE` 五种；`A` 弧线转成三次贝塞尔。
- `S/T` 根据上一控制点做反射；`Z` 闭合。
- 解析结果缓存在 `StrokeData.commands`，动画每帧只重放数字命令，不重复解析字符串。
- 单元测试覆盖：多点折线、二次/三次曲线、平滑曲线、圆弧、闭合路径。

#### 4.2 坐标与画布

makemeahanzi 坐标：1024×1024，y 向上，左上角 (0, 900)，右下角 (1024, -124)。

```text
scale = (size - 2 * padding) / 1024
screenX = padding + dataX * scale
screenY = padding + (900 - dataY) * scale
```

渲染时用 `ctx.setTransform(scale, 0, 0, -scale, padding, padding + 900 * scale)`，在数据坐标中构建路径和 clip；网格/文字在屏幕坐标绘制，避免被 y 翻转。

#### 4.3 两层 Canvas

`views/practice/StrokeCanvas.ets` 内部用 `Stack` 叠两个 Canvas：

- **baseContext**：田字格、所有笔画的浅色轮廓、已完成笔画；只在「当前笔画索引变化 / 主题色变化 / 尺寸变化」时重绘。
- **overlayContext**：正在动画的当前笔画、用户描红轨迹、错误闪烁、提示；每帧只清空 overlay 重绘。

这样避免每帧重放全部 20~30 笔路径，低端机也能保持 30fps。

笔画动画算法（参考 hanzi-writer 的 median 展开思路）：

1. 对当前笔画的 `median` 求累计长度。
2. 按进度截取 median 前段，向两侧偏移 `MASK_HALF_WIDTH`（建议 140，数据坐标），两端加半圆帽，构造 clip 多边形。
3. `ctx.save()` → 构建 clip → `clip()` → 填充该笔画的轮廓 path → `ctx.restore()`。
4. 进度从 0 到 1，笔画逐段显现；完成后把该笔画画到 base，清空 overlay。

参数：每笔 350~500ms（受设置里的「笔顺速度」影响），笔间停顿 180ms；用 `setInterval(16)` + 实际耗时计算进度，避免掉帧导致变慢；`aboutToDisappear` 清理定时器。若低端机仍有压力，再评估 `displaySync` 帧回调。

#### 4.4 描红判分

`service/StrokeMatcher.ets` 用纯几何函数，阈值以 1024 数据坐标为单位：

```text
起点距离 <= 220
终点距离 <= 260
用户路径长度 / 标准 median 长度 ∈ [0.4, 1.8]
用户采样点到标准 median 的平均距离 <= 200
方向余弦 >= 0.15（标准笔画长度 < 80 时跳过方向判断）
```

- 用户触摸点先转成数据坐标，按距离抽样 20 个点；少于 2 个点直接判失败。
- 通过：当前笔画填到 base，`strokeIndex++`，清空 overlay。
- 失败：overlay 闪红 300ms 后清空；`mistakes++`；错误 2 次后 overlay 显示下一笔的淡色轮廓提示。
- 完成：`@Event onQuizComplete(totalMistakes)`，父页面写进度。
- 判分阈值做成 `StrokeMatcherOptions`，单测覆盖「同路径通过、反向失败、偏移失败、过短失败、点画通过」。

#### 4.5 笔顺步骤图

`views/practice/StrokeStepsView.ets`：一个横向 `Canvas`，每个格子画「前 i 笔」，当前笔用强调色；点击格子回传 `onSelect(index)`，主画布显示到该笔的静态结果。不要为每一笔创建独立 Canvas 组件。

### 5. 页面与交互

#### 课本页（`BooksTabView`）

- 顶部「今日学习」卡片：已学会/总数、今日目标进度、继续学习按钮。
- 12 册卡片：年级册名、生字数/会写数、进度条/百分比；手机 2 列，平板 4 列。
- 查字入口：点击进入 `SearchView`。
- 数据模式徽标：演示数据/完整数据（本地）。
- 页面底部按脚手架 `contentEndOffset` 避开悬浮页签。

#### 课文页（`BookDetailView` / `LessonDetailView`）

- `BookDetailView`：册名、统计、总体进度；按单元分组，单元头显示「生字复习」；课文行显示课名 + 前 8 个生字 + 进度；点击进课。
- `LessonDetailView`：本课生字网格（拼音 + 田字格字），「隐藏拼音」开关；会写的字单独一栏；本课词语可点读；组词按字展开；底部上一课/下一课。
- 字格用 `Stack` + `Text` + 细线画田字格，不用每格一个 Canvas。

#### 字详情页（`CharDetailView`）

- 顶部固定区：大号 `StrokeCanvas`（手机最大 320vp，平板 360vp）、拼音、喇叭、播放笔顺/描红练习按钮、当前笔画/错误次数。
- 下方滚动区：笔顺步骤图、读音（多音字每个读音 + 词 + 学于哪课 + 同音字）、字形（部首、部件拆解、同部首字）、组词（默认 10 个 + 更多）、「标记已学会」「加入复习」「下一个字」。
- 描红时画布固定，不放在 `Scroll` 里，避免手指画字触发页面滚动。
- 未加载/无笔顺数据时显示骨架或「暂无笔顺数据」，按钮禁用。

#### 复习页（`ReviewTabView` / `ReviewSessionView`）

- 复习页：今日目标、待复习/错题数、正确率、连续天数；「开始复习」；错题本前 5 个字。
- 复习模式：
  - 看字读音：正面大字，翻面显示拼音 + 1~2 个词 + 喇叭。
  - 看拼音写字：正面拼音 + 挖空词（如「（ ）天」），翻面显示字 + 词。
  - 单元复习：传入 unit 的 lessonIds，队列为该单元生字。
- 自评「会了/再来」；「再来」的卡片插到 3 张后；结束显示成绩与错题。
- 复习不强制描红；描红入口仍在字详情。

#### 搜索页（`SearchView`）

- `TextInput` + 结果列表；输入防抖 150ms。
- 结果分组：汉字（拼音/课次）、词语（点击展开逐字，可进字详情）、拼音（匹配的字）。
- 结果超过 30 条用 `LazyForEach` + `IDataSource`。

#### 学习设置（`SettingsStudyView`）

- 隐藏拼音 / 显示笔顺步骤 / 笔顺速度（慢/标准/快）/ 每日目标（5/10/15/20）/ 语音朗读开关。
- 数据模式与版本、数据来源与许可、清除学习记录（二次确认）。
- 复用脚手架的 `ChoiceMenu` / `AppSheet` / 设置行组件；不要用 `HdsListItem`。

### 6. 状态与持久化

- 全局设置扩展 `model/AppSettings.ets`：

```ts
@Trace hidePinyin: boolean = false;
@Trace strokeSpeed: number = 1.0;
@Trace dailyGoal: number = 10;
@Trace showStrokeSteps: boolean = true;
@Trace ttsEnabled: boolean = true;
```

- `SettingsStore` 用 preferences 读写这些 key；`SettingsViewModel` 提供 setter。
- 学习进度用 RDB（`service/AppDatabase.ets`）：

```sql
CREATE TABLE IF NOT EXISTS char_progress (
  character TEXT PRIMARY KEY,
  learned INTEGER NOT NULL DEFAULT 0,
  attempts INTEGER NOT NULL DEFAULT 0,
  passes INTEGER NOT NULL DEFAULT 0,
  mistakes INTEGER NOT NULL DEFAULT 0,
  last_practiced INTEGER NOT NULL DEFAULT 0,
  next_review INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS lesson_progress (
  lesson_id TEXT PRIMARY KEY,
  learned_chars INTEGER NOT NULL DEFAULT 0,
  total_chars INTEGER NOT NULL DEFAULT 0,
  completed INTEGER NOT NULL DEFAULT 0,
  last_studied INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS practice_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  character TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  ts INTEGER NOT NULL,
  mistakes INTEGER NOT NULL,
  duration_ms INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_char_due ON char_progress(next_review);
CREATE INDEX IF NOT EXISTS idx_practice_ts ON practice_log(ts);
```

- `ProgressStore`（`@ObservedV2` 单例）：
  - `@Trace learned: Set<string>`、`@Trace mistakes: Map<string, number>`、`@Trace dailyCount`、`@Trace streak`、`@Trace accuracy`。
  - 每次更新用**新 Set/Map 赋值**，避免原地修改导致 V2 不刷新。
  - `recordQuiz(char, lessonId, mistakes, durationMs)`：写 `char_progress` + `practice_log`；错误 ≤ 2 视为通过；更新 `next_review`；刷新内存。
  - `markLearned(char)`：手动标记。
  - `reviewQueue(mode, limit)`、`mistakeList()`、`statsForBook(bookId)`。
  - `resetAll()`：清空表与内存，重新加载。
- 复习间隔 `service/ReviewScheduler.ets`：`[1, 2, 4, 7, 15, 30]` 天；有错误时次日/10 分钟后重来；纯函数，单测覆盖。
- 生命周期：
  - `Index.aboutToAppear`：`appBootstrap.start(context)`；`Index.onPageShow` 刷新每日计数（跨天）。
  - `CharDetailView.aboutToAppear`：加载笔画分片；`aboutToDisappear`：停止动画、清理定时器。
  - `ReviewSessionView.aboutToDisappear`：结束会话，不丢已记录的进度。
  - `Index.aboutToDisappear`：`ttsService.shutdown()`、`appBootstrap` 不需要释放。

### 7. 资源、权限与视觉

- 颜色：在 `resources/base/element/color.json` 与 `resources/dark/element/color.json` 新增：
  - `hanzi_ink`（正文墨色）、`hanzi_grid`（田字格线）、`hanzi_outline`（笔画轮廓）、`hanzi_active`（当前笔/强调）、`hanzi_error`、`hanzi_success`、`hanzi_card`。
- 文案：`resources/base/element/string.json` 与 `resources/zh_CN/element/string.json` **同时**新增：页签名、页面标题、按钮、空态、错误、设置项、许可说明。base 用英文，zh_CN 用中文；App 名称 `HanZi` / 「汉字书写」。
- 尺寸：`resources/base/element/float.json` 新增 `hanzi_canvas_max`、`hanzi_cell_size`、`hanzi_cell_gap`、`stroke_steps_height`、`book_card_radius` 等。
- Canvas 颜色：`active` 用 `themePalette.accent()`；`ink`/`grid`/`outline` 根据 `themePalette.isDark` 取预定义色，通过 `@Param` 传给 `StrokeCanvas`，主题变化时父组件重建并触发重绘。
- 权限：不新增权限；删除 `module.json5` 的 `ohos.permission.DLP_GET_HIDE_STATUS`（避免 system_basic ACL 导致安装失败），防窥功能保持关闭；INTERNET/GET_NETWORK_INFO 保留但不用于核心功能。
- 语音：`TtsService` 使用离线中文引擎；引擎不可用时隐藏喇叭，不影响学习闭环。
- 图标：沿用脚手架图标；后续可换成「田字格 + 字」的简单图标，非首版阻塞项。

### 8. 性能与无障碍

- 笔画数据分片 + LRU（4 个分片）；字详情首开只解析一个分片。
- 两层 Canvas；base 只在笔画边界重绘，overlay 每帧重绘。
- 搜索防抖 + `LazyForEach`；课本/课文/字格数量小，用 `ForEach` 即可。
- 首屏只加载课程 TSV + RDB 统计；不预加载笔画分片。
- 目标：冷启动 < 2s、字详情笔顺数据 < 100ms、动画 ≥ 30fps、内存 < 200MB（中端机）。
- 无障碍：Canvas 容器设置 `accessibilityText`（如「天，共 4 画，笔顺播放」）；所有按钮有可读文案；点击区域 ≥ 44vp；错误/成功状态不只靠颜色，配合文字。
- 深色/浅色、窄屏/宽屏都检查；底部悬浮页签不遮挡最后一行。

## Key Files

| 文件 | 作用 |
|---|---|
| [LICENSE](LICENSE) | MIT 代码许可 |
| [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) | 第三方代码/数据声明 |
| [DATA_LICENSE.md](DATA_LICENSE.md) | 数据来源、许可与授权状态 |
| [README.md](README.md) | 构建、数据生成、seed-only 开源说明 |
| [.gitignore](.gitignore) | 排除 full 数据、缓存、构建产物 |
| [tools/package.json](tools/package.json) | 数据脚本依赖与 npm scripts |
| [tools/fetch-curriculum.mjs](tools/fetch-curriculum.mjs) | 抓取 12 册、课文、多音字，输出 TSV |
| [tools/build-hanzi-data.mjs](tools/build-hanzi-data.mjs) | 合并 makemeahanzi 笔画/字典，生成分片 |
| [tools/validate-data.mjs](tools/validate-data.mjs) | 数据完整性与许可文件校验 |
| [tools/seed/](tools/seed/) | 可提交的最小 seed 数据源 |
| [entry/src/main/resources/rawfile/data/seed/](entry/src/main/resources/rawfile/data/seed/) | 仓库内置演示数据 |
| [entry/src/main/resources/rawfile/data/full/](entry/src/main/resources/rawfile/data/full/) | 本地生成的完整数据（默认 gitignore） |
| [entry/src/main/resources/rawfile/data/licenses/](entry/src/main/resources/rawfile/data/licenses/) | Arphic/LGPL/MIT 许可文本 |
| [entry/src/main/ets/model/CurriculumModels.ets](entry/src/main/ets/model/CurriculumModels.ets) | 课程领域模型 |
| [entry/src/main/ets/model/StrokeModels.ets](entry/src/main/ets/model/StrokeModels.ets) | 笔画/路径/判分模型 |
| [entry/src/main/ets/model/ProgressModels.ets](entry/src/main/ets/model/ProgressModels.ets) | 进度/复习模型 |
| [entry/src/main/ets/model/AppSettings.ets](entry/src/main/ets/model/AppSettings.ets) | 新增学习设置字段 |
| [entry/src/main/ets/service/AppBootstrap.ets](entry/src/main/ets/service/AppBootstrap.ets) | 启动加载与错误态 |
| [entry/src/main/ets/service/DataRootResolver.ets](entry/src/main/ets/service/DataRootResolver.ets) | full/seed 数据根选择 |
| [entry/src/main/ets/service/CurriculumRepository.ets](entry/src/main/ets/service/CurriculumRepository.ets) | 课程 TSV 仓库 |
| [entry/src/main/ets/service/HanziDataRepository.ets](entry/src/main/ets/service/HanziDataRepository.ets) | 笔画分片加载与 LRU |
| [entry/src/main/ets/service/AppDatabase.ets](entry/src/main/ets/service/AppDatabase.ets) | RDB 打开/建表/迁移 |
| [entry/src/main/ets/service/ProgressRepository.ets](entry/src/main/ets/service/ProgressRepository.ets) | 进度读写/统计/错题 |
| [entry/src/main/ets/service/SvgPathParser.ets](entry/src/main/ets/service/SvgPathParser.ets) | SVG path → Canvas 命令 |
| [entry/src/main/ets/service/StrokeGeometry.ets](entry/src/main/ets/service/StrokeGeometry.ets) | median 长度/截取/clip 多边形 |
| [entry/src/main/ets/service/StrokeMatcher.ets](entry/src/main/ets/service/StrokeMatcher.ets) | 描红判分 |
| [entry/src/main/ets/service/StrokeRenderer.ets](entry/src/main/ets/service/StrokeRenderer.ets) | Canvas 网格/轮廓/笔画/提示绘制 |
| [entry/src/main/ets/service/SearchService.ets](entry/src/main/ets/service/SearchService.ets) | 汉字/拼音/词语搜索 |
| [entry/src/main/ets/service/PinyinUtils.ets](entry/src/main/ets/service/PinyinUtils.ets) | 拼音归一/声调 |
| [entry/src/main/ets/service/ReviewScheduler.ets](entry/src/main/ets/service/ReviewScheduler.ets) | 复习间隔 |
| [entry/src/main/ets/service/TtsService.ets](entry/src/main/ets/service/TtsService.ets) | 可选中文朗读 |
| [entry/src/main/ets/viewmodel/HomeViewModel.ets](entry/src/main/ets/viewmodel/HomeViewModel.ets) | 课本页派生状态 |
| [entry/src/main/ets/viewmodel/CharDetailViewModel.ets](entry/src/main/ets/viewmodel/CharDetailViewModel.ets) | 字详情加载 |
| [entry/src/main/ets/viewmodel/ReviewViewModel.ets](entry/src/main/ets/viewmodel/ReviewViewModel.ets) | 复习队列/评分 |
| [entry/src/main/ets/views/BooksTabView.ets](entry/src/main/ets/views/BooksTabView.ets) | 课本页 |
| [entry/src/main/ets/views/books/BookDetailView.ets](entry/src/main/ets/views/books/BookDetailView.ets) | 册详情 |
| [entry/src/main/ets/views/books/LessonDetailView.ets](entry/src/main/ets/views/books/LessonDetailView.ets) | 课文详情 |
| [entry/src/main/ets/views/books/CharDetailView.ets](entry/src/main/ets/views/books/CharDetailView.ets) | 字详情 |
| [entry/src/main/ets/views/practice/StrokeCanvas.ets](entry/src/main/ets/views/practice/StrokeCanvas.ets) | 双层 Canvas 笔顺/描红 |
| [entry/src/main/ets/views/practice/StrokeStepsView.ets](entry/src/main/ets/views/practice/StrokeStepsView.ets) | 笔顺步骤图 |
| [entry/src/main/ets/views/review/ReviewTabView.ets](entry/src/main/ets/views/review/ReviewTabView.ets) | 复习页 |
| [entry/src/main/ets/views/review/ReviewSessionView.ets](entry/src/main/ets/views/review/ReviewSessionView.ets) | 复习卡会话 |
| [entry/src/main/ets/views/search/SearchView.ets](entry/src/main/ets/views/search/SearchView.ets) | 查字 |
| [entry/src/main/ets/views/settings/SettingsStudyView.ets](entry/src/main/ets/views/settings/SettingsStudyView.ets) | 学习设置 |
| [entry/src/main/ets/views/settings/AboutDataView.ets](entry/src/main/ets/views/settings/AboutDataView.ets) | 数据来源/许可 |
| [entry/src/main/ets/pages/Index.ets](entry/src/main/ets/pages/Index.ets) | 页签、路由、pageMap 接线 |
| [entry/src/main/ets/common/constants/RouterConstants.ets](entry/src/main/ets/common/constants/RouterConstants.ets) | 新增路由名 |
| [entry/src/main/ets/common/constants/NavigationConstants.ets](entry/src/main/ets/common/constants/NavigationConstants.ets) | 页签：BOOKS/REVIEW/SETTINGS |
| [entry/src/main/module.json5](entry/src/main/module.json5) | 删除 DLP 权限（需签名安全） |

## Execution Sequence

### Phase 0：生成基线、锁定可编译状态、建立开源骨架

1. 确认 `/Users/huxiaohui/Documents/YostarWork/Github/HM/HanZi` 为空。
2. 运行脚手架门禁：

```bash
node "/Users/huxiaohui/.agents/skills/create-arkts-app-from-scaffold/scripts/check-scaffold.mjs"
```

3. 生成工程（目标已存在但为空，使用 `--force`；若不想删除，先生成 `HanZiApp` 再改名）：

```bash
node "/Users/huxiaohui/.agents/skills/create-arkts-app-from-scaffold/scripts/create-app.mjs" \
  --project-path "/Users/huxiaohui/Documents/YostarWork/Github/HM" \
  --app-name "HanZi" --bundle-name "com.example.hanzi" --force --verify
```

4. 进入 `HanZi`，初始化 git 并提交基线；添加 `LICENSE`（MIT）、`THIRD_PARTY_NOTICES.md`、`DATA_LICENSE.md`、`README.md`、`.gitignore`。
5. 执行：

```bash
devecocli build
devecocli check lint
devecocli check arkts
```

6. 清理模板领域：`TabIndex` 改为 `BOOKS=0, REVIEW=1, SETTINGS=2`；`Index.ets` 用复习页替换图片页，移除 `IMAGE_DOMAIN`/图片路由分支；删除 `module.json5` 的 `DLP_GET_HIDE_STATUS`。

**验收**：`BUILD SUCCESSFUL`，lint 0 error，ArkTS 无新增错误；开源文件齐全。

### Phase 1：数据流水线与 seed-only 数据

1. 创建 `tools/package.json`、`fetch-curriculum.mjs`、`build-hanzi-data.mjs`、`validate-data.mjs`、`tools/README.md`。
2. 先做 seed 数据（提交）：

```bash
cd tools
npm install
npm run data:seed
```

3. 本地生成完整数据（可选、个人使用、不提交）：

```bash
npm run data:all
```

4. 校验输出：12 册、课文数/生字数与站点一致；每个课程字有笔画；许可文件齐全。
5. 确认 `.gitignore` 已排除 `data/full/`，`git status` 中不出现 full 数据。
6. 若网络不可用，保留 seed 数据跑通 UI 与测试；full 仅作为本地增强数据。

**验收**：`validate-data.mjs` 退出码 0；`data/seed` 可被 App 识别；`data/full` 不出现在 git 变更中；抽查「天/地/人/秋/了」的笔顺路径和 median 非空。

### Phase 2：模型、仓库、启动加载

1. 新建 `CurriculumModels.ets`、`StrokeModels.ets`、`ProgressModels.ets`、`RouteParams.ets`。
2. 实现 `DataRootResolver`、`CurriculumRepository`（TSV 解析）与 `HanziDataRepository`（分片 + LRU + path 解析）。
3. 实现 `AppBootstrap`，在 `Index.aboutToAppear` 启动；加载中/失败 UI。
4. 加一个临时调试页或日志，验证 12 册/seed、课文、字数据可查；验证 full 缺失时回退 seed。

**验收**：App 启动后能读到 12 册或 seed 演示课；`devecocli build` 通过。

### Phase 3：笔顺引擎与单元测试

1. 实现 `SvgPathParser`、`StrokeGeometry`、`StrokeMatcher`、`StrokeRenderer`。
2. 实现 `StrokeCanvas` 双层画布、动画、描红、提示。
3. 在 `entry/src/ohosTest/ets/test/` 加 `SvgPathParser.test.ets`、`StrokeGeometry.test.ets`、`StrokeMatcher.test.ets`、`PinyinUtils.test.ets`、`ReviewScheduler.test.ets`，并在 `List.test.ets` 聚合。
4. 用一个临时页面验证「天」的播放/描红。

**验收**：`devecocli build --modules entry@ohosTest` 通过；测试用例通过；动画肉眼无卡顿。

### Phase 4：核心页面与导航

1. `BooksTabView`、`BookDetailView`、`LessonDetailView`、`CharDetailView`。
2. 在 `RouterConstants` 加路由；`Index.pageMap` 接线；`TabIndex`/`tabShell`/`wideContent`/`railItems` 三处同步。
3. 资源文案/颜色/尺寸补齐（base + zh_CN、base + dark）。
4. 接入 `ProgressStore` 的读路径（已学会标记、课本进度）。

**验收**：首页 → 册 → 课 → 字 → 播放笔顺 → 描红完成，全链路可用。

### Phase 5：进度持久化、复习、搜索、设置

1. `AppDatabase` + `ProgressRepository` + `ProgressStore`；`CharDetailView` 完成描红后写入。
2. `ReviewTabView` + `ReviewSessionView`；实现看字读音/看拼音写字/单元复习。
3. `SearchView` + `SearchService`；`SettingsStudyView` + `AboutDataView` + `LicensesView`。
4. 可选 `TtsService`，接入字/词喇叭。

**验收**：描红完成后复习页待复习数增加；复习评分后下次复习时间变化；搜索汉字/拼音/词语均有结果；设置项重启后保留。

### Phase 6：响应式、深色、性能、无障碍与最终验收

1. 手机/平板/横屏检查；课本卡片 2/4 列；字详情宽屏左右分栏。
2. 深浅色检查 Canvas 墨色/网格/强调色；对比度。
3. 性能：字详情首开、动画帧率、长课文滚动；必要时压缩分片或优化重绘。
4. 无障碍：Canvas `accessibilityText`、按钮文案、触控区域。
5. 开源发布门禁：许可文件、数据模式、README、无 full 数据泄露。
6. 跑完整验证矩阵（见下）。

## Verification

| 检查 | 命令/方法 | 通过标准 |
|---|---|---|
| 基线构建 | `devecocli build` | `BUILD SUCCESSFUL` |
| Lint | `devecocli check lint` | `Errors: 0`（脚手架已有 2 条 warning 可忽略） |
| ArkTS 检查 | `devecocli check arkts` | 无新增错误；`nav-destination-root-node` 为已知误报，不改 `HdsNavDestination` |
| 单测编译 | `devecocli build --modules entry@ohosTest` | `BUILD SUCCESSFUL` |
| 单测运行 | `devecocli test` 或 DevEco 测试运行器 | SVG/几何/判分/拼音/复习调度全部通过 |
| 数据校验 | `npm run data:validate` | 12 册、课号唯一、拼音完整、每个字有笔画、strokes/medians 对齐 |
| seed 构建 | 删除 `data/full` 后 `devecocli build` | 仍可构建；App 显示「演示数据」 |
| full 本地冒烟 | 本地生成 `data/full` 后构建**私有** HAP | 数据模式显示「完整数据（本地）」；不得分发该 HAP |
| 资源一致性 | 脚手架 verification 里的 base/zh_CN 对比 | `missing` / `extra` 均为空 |
| 纯 V2 自查 | 脚手架 verification 的 `rg` 命令 | 无输出（注释误报除外） |
| 开源许可 | 人工检查 `LICENSE` / `THIRD_PARTY_NOTICES.md` / `DATA_LICENSE.md` / `data/licenses` | 四类许可文本齐全 |
| 发布物门禁 | 检查 `git status` 与 rawfile 目录 | 官方 release 只含 `data/seed`，不含 `data/full` |
| 真机/模拟器 | `devecocli device list` / `devecocli run` | 安装启动；首页/册/课/字/复习/设置可达 |
| UI 截图 | `devecocli ui screenshot --device ... --path ...` | 首页、课文、字详情、描红、复习页；深色/浅色各一组 |
| 离线 | 开飞行模式后重启 App | 核心链路全部可用，无网络请求 |
| 性能 | 真机计时/帧率观测 | 冷启动 < 2s；字详情笔顺 < 100ms；动画 ≥ 30fps |

## Risks And Compatibility

| 风险 | 影响 | 缓解 |
|---|---|---|
| full 数据体积较大 | 默认不进仓库 | 公开仓库只带 seed；full 本地生成；如需分发保留 MIT/Arphic 许可与归属 |
| 课程字表缺少「会写字/识字」区分 | 学习侧重点略粗 | 首版所有课程字都可描红；后续可接入更细的教材字表 |
| 抓取页面结构改版 | 数据流水线失效 | 缓存 HTML、选择器集中在 `fetch-curriculum.mjs`、`validate-data.mjs` 拦截；保留 `--limit` 与 seed |
| SVG path 含 `A` 弧线/隐式命令 | 笔画渲染错误 | 完整解析器 + 单测；弧线转贝塞尔；异常路径跳过并记录 |
| Canvas 动画性能不足 | 低端机掉帧 | 双层 Canvas、30fps、分片缓存；必要时降级为逐笔静态展示 |
| HAP 包体过大 | 安装/分发受限 | 官方包只含 seed，体积极小；full 仅本地私有构建；32 分片；必要时 gzip |
| ArkTS 严格类型/禁止 `as` | 解析代码难写 | 数据用 TSV；模型强类型；仅在路由参数/启动上下文边界使用断言并集中封装 |
| 防窥权限 ACL 导致安装失败 | 真机装不上 | 删除 `DLP_GET_HIDE_STATUS`，防窥保持关闭 |
| TTS 引擎不可用/API 差异 | 朗读不可用 | `try/catch` + `available=false`，隐藏喇叭；不影响核心 |
| 主题色/深色下 Canvas 颜色不刷新 | 视觉不一致 | 父组件读 `themePalette`，把颜色作为 `@Param` 传入；`@Monitor` 重绘 |
| 进度数据迁移 | 升级丢数据 | `RdbStore.version` 迁移；首版 version=1；清除记录需二次确认 |
| seed 数据过于单薄 | 演示/CI 覆盖不足 | seed 选 1 个单元（6 个字），覆盖笔顺、复习、搜索的基本路径；完整功能用本地 full 验收 |

## Rollback

- 这是新工程，`ScaffoldApp` 不被修改；回滚直接删除 `HanZi` 目录即可恢复工作区。
- 每个 Phase 结束提交一次 git；失败时 `git reset --hard` 回上一个绿色提交。
- 数据流水线失败：删除 `entry/src/main/resources/rawfile/data/full/` 与 `tools/cache/`，回退 seed，App 仍可进入演示态。
- 若误把 full 数据提交到 git：从工作区删除、确认 `.gitignore` 生效；如已推送到公开仓库，需要改写历史并重新发布，避免数据继续扩散。
- 若 Canvas 方案在目标设备不可行：保留 `CharDetailView` 接口，临时替换为静态笔顺图（用 `Image`/SVG 资源），再评估 ArkWeb 混合方案；不要改动数据层与路由层。
