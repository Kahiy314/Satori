# Satori

Satori 是一个带有东方美学气质的专注应用项目。仓库目前包含两个实现：

- `satori_flutter`：Flutter 主应用，面向 Android / iOS / Web / Desktop 的跨平台版本。
- `satori_miniprogram`：微信小程序版本，由 AvAn0sch 协作开发，产品风格与 Satori 保持一致，但 UI 与 Flutter 版不追求完全对齐。

## 项目功能介绍

Satori 以“焚香”为核心专注仪式，把计时、白噪音、器乐、复盘和统计收拢在一个安静的使用流程里。用户可以离线使用基础功能，也可以在配置 Supabase 后开启账号登录与云端行迹同步。

<!--
截图占位：
建议在 Android Virtual Device 中截取 Flutter 版主要界面后放到 docs/images/，
再在这里替换为真实截图或 GIF。
-->

主要能力包括：

- 焚香专注：倒计时、正计时、预设时长、自定义时长、暂停、放弃、手动完成与结束小结。
- 复盘记录：任务标签、小结备注、完成感受、短时专注过滤和本地历史记录。
- 听雨与抚琴：白噪音、器乐播放、音量控制和会员权益锁定展示。
- 行迹统计：总时长、专注天数、完成率、连续天数、趋势图、热力图、历史列表、单日时间轴和会话详情。
- 账号与云同步：通过 Supabase 邮箱密码登录、注册、重置密码和 focus session 双向合并。
- 微信小程序：任务管理、番茄计时、日历打卡、统计面板、国风名言弹窗和设置页。

## 技术栈

- Flutter：Dart、Riverpod、Material 3、shared_preferences、Supabase Flutter、just_audio / audioplayers、in_app_purchase。
- 微信小程序：TypeScript、WXML、WXSS、微信开发者工具、本地存储。
- 后端服务：Supabase Auth、Postgres、RLS、RPC。云同步是可选能力，未配置时 Flutter 版会自动退回本地模式。
- 文档与交付：MIT 代码许可证、GitHub Actions Flutter CI、独立资产许可说明。

## Quick Start

运行 Flutter 本地模式：

```powershell
cd satori_flutter
flutter pub get
flutter run
```

运行 Flutter 云同步模式：

```powershell
cd satori_flutter
copy tool\supabase.local.example.json tool\supabase.local.json
# 填入 SUPABASE_URL 和 SUPABASE_PUBLISHABLE_KEY
tool\run-cloud.cmd
```

构建发布包时建议使用 `dart-define-from-file` 注入生产配置：

```powershell
flutter build apk --release --dart-define-from-file=tool/supabase.production.json
```

运行微信小程序：

```powershell
cd satori_miniprogram
npm install
npm run typecheck
```

然后在微信开发者工具中打开 `satori_miniprogram`。公开仓库里的 `project.config.json` 使用 `touristappid`，本地调试或发布时请在微信开发者工具里换成你自己的 AppID。

更多说明见：

- [Flutter 开发说明](docs/development.md)
- [架构说明](docs/architecture.md)
- [Supabase 配置](docs/supabase.md)
- [微信小程序说明](docs/miniprogram.md)
- [发布说明](docs/release.md)

## 常见问题

**不配置 Supabase 能不能跑？**  
可以。Flutter 版默认支持本地模式，账号入口会显示“云同步未配置 / 本地模式”，专注记录会保存在本地。

**真机测试过吗？**  
已在 Huawei Android 真机上通过 debug APK 做过基础冒烟测试。未注入 Supabase 配置的 APK 会进入本地模式，焚香、白噪音、基础行迹记录等离线能力可用；账号创建、登录和云同步需要重新构建带 Supabase 配置的 APK。

**能不能用 `adb install` 时再接上 Supabase？**  
不能。`adb install` 只安装已经构建好的 APK，Supabase 配置需要在 `flutter build` 或 `flutter run` 阶段通过 `--dart-define-from-file` 注入。详见 [发布说明](docs/release.md)。

**Supabase publishable key 可以提交吗？**  
示例文件可以提交，真实本地配置不要提交。publishable key 不是 service role secret，但安全边界必须依赖 RLS 和 RPC。

**为什么小程序端 AI 总结没有真实 API key？**  
小程序前端不能安全持有 DeepSeek / OpenAI 等服务端密钥。正式接入时应通过云函数或自己的服务端代理调用。

**为什么 release signing 没有内置？**  
Android release 签名、iOS Team ID、App Store / Google Play 配置都属于本地发布材料，不应进入公开仓库。配置方式见 [发布说明](docs/release.md)。

**这个仓库现在适合直接商用上架吗？**  
代码层面可以继续打磨，但音频和部分图片资源需要先完成授权核验或替换，见下方 Asset License。

## Asset License

本仓库代码使用 [MIT License](LICENSE)。除非在 [Asset License](docs/assets.md) 中明确列入可再分发清单，`assets/`、`miniprogram/assets/`、`docs/images/` 下的图片、SVG、音频、截图和生成图不自动适用 MIT License。

当前资产来源包含 AI 生成/二次编辑素材、网络可商用音频和从视频转出的音频，其中一部分尚未完成源头授权核验。公开发布、商店上架或商业使用前，请替换未核验音频，或补齐可追溯的许可证与来源记录。
