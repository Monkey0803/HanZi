<img src="docs/logo.svg" width="96" alt="HanZi logo" />

# HanZi · 汉字书写

一个基于 HarmonyOS（ArkTS / ArkUI / HDS）的小学语文生字学习 App。

- 按 12 册课本浏览课文生字、拼音、会写字与组词
- 课内识字短文点读：逐字查字、拼音开关、生字高亮、「找一找」小测与整篇朗读（设备支持时）
- 原生 Canvas 笔顺动画、逐笔展示、描红练习与笔顺判分
- 学习记录、复习卡、错题本、每日目标
- 手机 / 平板响应式，深色模式，离线可用

## 技术要点

- HarmonyOS Stage 模型，HDS（UI Design Kit）外壳
- ArkTS 状态管理 V2（`@ComponentV2` / `@Local` / `@Param` / `@Event` / `@ObservedV2` / `@Trace`）
- 原生 Canvas 重写 hanzi-writer 核心能力：SVG path 解析、median 展开动画、描红判分
- 课程/笔画数据使用 TSV 分片，启动时按需加载

## 快速开始

```bash
# 1. 首次 clone：创建本机配置（不要提交 build-profile.json5）
cp build-profile.template.json5 build-profile.json5

# 2. 在 DevEco Studio 的 Project Structure > Signing Configs 配置自动签名，
#    或先执行 devecocli auth login，再执行 devecocli signature generate。

# 3. 安装依赖（工程根目录）
ohpm install --all

# 4. 构建
devecocli build

# 5. 运行（需要已连接设备或模拟器，并配置签名）
devecocli run
```

本地一键校验可运行 `scripts/verify.sh`。发布包使用 `scripts/build-release.sh`：脚本会先生成并校验
完整课程数据，再构建 release HAP，并确认包内包含完整数据与许可文件。

## 数据

源码仓库只提交 **seed 演示数据**：`entry/src/main/resources/rawfile/data/seed/`，保证 clone 后可离线构建和演示。
应用市场 release HAP 必须通过 `scripts/build-release.sh` 生成，其中包含本地生成的完整课程数据和许可文件；
禁止把只有 2 课的 seed 包作为正式版本上传。

完整课程数据由公开教材生字表在本地生成（默认不提交）：

```bash
cd tools
npm install

# 下载公开教材生字表 → 生成 full 数据 → 校验
npm run data:all

# 只生成识字短文（阅读功能数据）
npm run data:passages

# 仅生成演示数据（从 full 裁剪）
npm run data:seed
```

生成后 App 会优先读取 `entry/src/main/resources/rawfile/data/full/`；没有 full 时自动回退 seed，并在设置页显示「演示数据」。

### 数据来源与许可

- 笔顺轮廓 / median：skishore/makemeahanzi，Arphic Public License
- 部首 / 部件：skishore/makemeahanzi `dictionary.txt`（Unihan / CJKlib）
- 笔顺交互参考：chanind/hanzi-writer，MIT（本项目为原生 ArkTS 重写，不运行时加载 JS）
- 课程数据：athenayan123-web/dictation-robot 的「人教版（部编版）小学语文 12 册」生字/词语表，MIT License

详见 [DATA_LICENSE.md](DATA_LICENSE.md) 与 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 代码许可

MIT，见 [LICENSE](LICENSE)。

## 文档

- [实施计划](docs/IMPLEMENTATION_PLAN.md)
