# Satori Flutter

Flutter 版是 Satori 的主应用实现，采用 local-first 设计：不配置 Supabase 也能完整体验焚香、听雨、抚琴、品茗和行迹统计；配置 Supabase 后会启用邮箱账号与云端 focus session 同步。

## 功能范围

- 焚香：倒计时、正计时、预设/自定义时长、暂停、放弃、完成、小结、任务标签、完成感受。
- 行迹：概览、历史记录、单日时间轴、会话详情、趋势图、热力图。
- 听雨/抚琴：白噪音与器乐播放，会员权益锁定展示。
- 品茗：会员等级展示和开发者模式，真实 IAP 仍需接入商店流程。
- 账号：Supabase 邮箱密码登录、注册、退出、重置密码、登录后本地/云端记录合并。

## 目录结构

```text
lib/
├── app/                 # App 入口、导航、Riverpod providers
├── core/                # 主题、模型、通用组件、配置
├── features/            # incense / rain / qin / tea / stats / settings
└── services/            # 本地存储、统计聚合、Supabase、音频、触感、权限
supabase/
└── migrations/          # Supabase schema、RLS、RPC 迁移
tool/
└── run-cloud.*          # 本地云同步启动脚本
```

## 运行

本地模式：

```powershell
flutter pub get
flutter run
```

云同步模式：

```powershell
copy tool\supabase.local.example.json tool\supabase.local.json
# 填入 SUPABASE_URL 和 SUPABASE_PUBLISHABLE_KEY
tool\run-cloud.cmd
```

也可以直接传入：

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

默认原生认证回跳地址为 `satori://auth/callback`。如需覆盖，可额外注入 `SUPABASE_AUTH_REDIRECT_URL`。

## Supabase

在 Supabase 控制台启用 Email provider，并在 `Authentication -> URL Configuration` 中加入：

```text
satori://auth/callback
```

数据库结构、RLS 与 RPC 由 [supabase/migrations/202604230001_harden_focus_sessions_security.sql](supabase/migrations/202604230001_harden_focus_sessions_security.sql) 管理。详细说明见 [../docs/supabase.md](../docs/supabase.md)。

## 验证

```powershell
flutter analyze
flutter test
```

当前 CI 也会运行上述两项。若 `flutter analyze` 因 `prefer_const_*` info 失败，请优先清理对应 lint。

## 发布

发布构建建议使用生产配置文件注入 Supabase：

```powershell
flutter build apk --release --dart-define-from-file=tool/supabase.production.json
```

Android release 签名、iOS Team ID、商店凭据不进入公开仓库。详见 [../docs/release.md](../docs/release.md)。
