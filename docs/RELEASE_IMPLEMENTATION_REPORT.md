# HanZi 上架收尾实施报告

实施日期：2026-11-13
实施依据：[RELEASE_PLAN.md](RELEASE_PLAN.md)

## 结论

本轮已完成发布工程化、核心功能闭环、完整离线数据打包、合规页面与 API 26 手机模拟器验收。最终 release HAP 可构建、安装和启动，应用内确认使用 full 数据（12 册、301 课、2421 个课程汉字、3870 个含笔顺汉字，缺失笔顺 0）。

当前仍不能直接认定为“可提交应用市场”：正式包名、开发者名称、隐私政策联系邮箱与正式签名材料需要开发者提供；手机以外设备、性能、无障碍和全部 Hypium 套件的设备运行仍需补充。

## 已实施

### 发布工程化与合规

- 新增无签名 `build-profile.template.json5`，并补充首次构建、签名和 release 构建文档。
- 权限缩减为 `ohos.permission.DETECT_GESTURE`，移除网络权限并补充用户可读用途说明。
- 新增 `scripts/verify.sh` 和 `scripts/build-release.sh`；release 脚本会生成 full 数据、构建 release HAP并检查课程元数据和许可文件。
- 更新 `README.md`、`DATA_LICENSE.md`、`THIRD_PARTY_NOTICES.md`；新增 `PRIVACY.md`、应用内隐私文本、市场文案和发布检查清单。
- 隐藏未获得 DLP 权限支持的防窥设置，并将其持久化值强制归一为关闭。

### 功能闭环

- 新增可单测的进度聚合器，接通首页、册、单元和课程进度。
- 新增单元“生字复习”入口，复习队列覆盖单元全部生字并优先排列已学会字。
- 新增完整错题本、错题详情与错题复习路由。
- 新增每日目标、笔顺速度、隐藏拼音、语音朗读四项持久化学习设置。
- 新增数据与许可、许可全文、隐私政策页面。
- 新增进度聚合测试并扩充设置选项测试。

### 数据与发布包

- 完整数据生成成功：12 册、301 课、2421 个课程汉字、3870 个笔顺汉字，`missingStrokes=0`。
- 修正数据生成脚本，release 包携带教材 MIT 许可及其他所需许可文本。
- 最终 HAP：`entry/build/default/outputs/default/entry-default-signed.hap`，大小 11,156,520 字节。
- 产物内 `module.json` 为 `debug=false`、`buildMode=release`，请求权限仅剩 `DETECT_GESTURE`。

## 自动验证

| 检查 | 结果 |
|---|---|
| `./scripts/verify.sh` | 通过 |
| entry release HAP 编译 | `BUILD SUCCESSFUL` |
| entry@ohosTest HAP 编译 | `BUILD SUCCESSFUL` |
| full 数据校验 | 通过 |
| `./scripts/build-release.sh` | 通过，产物内容检查通过 |
| `git diff --check` | 通过 |
| base / zh_CN 字符串资源键 | 一致 |

当前环境未提供 `devecocli`，验证脚本使用 Hvigor 完成主模块和测试模块编译，并明确跳过独立的 `devecocli check lint` / `check arkts`。编译无 error；仍有 API 26 材质兼容性和 throwable API 的既有 warning。

## API 26 模拟器验收

设备：Mate 90 Pro，HarmonyOS 7.0.0 / API 26。仅使用 TCP 模拟器 `127.0.0.1:10001`，未连接或操作 USB 实体设备。

- 最终 HAP 覆盖安装和启动成功，进程稳定，未发现崩溃日志。
- 首页显示 12 册和 `0 / 3044 字`；教材详情、第一课、课程进度及拼音显示正常。
- 复习页、统计和错题本空态正常。
- 每日目标 5/10/15/20 可选并成功改为 15；笔顺速度、隐藏拼音和语音朗读设置可交互。
- 数据与许可页显示 full、版本 1.0.0、12 册、301 课、2421 个课程汉字、3870 个笔顺汉字、缺失笔顺 0；教材 MIT 许可全文可打开。
- 隐私政策页可打开并完整显示。
- 未见文字重叠、异常裁切或错误颜色。底部浮动导航可能覆盖列表末端的视觉区域，但内容可继续滚动，不阻塞使用。

证据位于 `screenshots/release-validation/`，关键文件为 `07-final-home.*`、`08-final-settings-toggled.*`、`09-data-license.*`、`10-privacy.*`。

## 尚待完成

### 提交应用市场前必须处理

- 将 `AppScope/app.json5` 的 `com.example.hanzi` / `example` 替换为开发者正式包名和主体名称。
- 在 `PRIVACY.md` 与应用内隐私政策中填写真实联系邮箱，并提供可公开访问的托管地址。
- 使用正式发布证书重新签名并验证安装；当前仓库历史中曾提交 `build-profile.json5`，需评估历史清理并轮换相关签名材料。
- 准备软件著作权、APP 备案、年龄分级、正式截图等开发者主体材料。

### 质量补充项

- 在模拟器或真机实际运行全部 Hypium 套件；本轮只确认测试 HAP 编译成功。
- 补齐平板、2in1、深色模式、屏幕阅读器、性能指标和真机 TTS/握姿能力验证。
- 当前全新进度下错题数为 0，“查看全部”入口会隐藏，因此只验收了错题本空态，未完成有错题数据时的完整 UI 端到端流程。
