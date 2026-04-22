# Satori Flutter

Satori 的 Flutter 重构主工程目录。当前版本已完成以下首版能力：

- 焚香暂停态按钮对齐：倒计时暂停后显示“继续 / 放弃”一行，“完成本次专注”第二行。
- 焚香总结流复用：倒计时自然完成、倒计时手动完成、正计时手动完成共用同一份总结页。
- Supabase 邮箱密码认证骨架：设置页可登录、注册、登出、发送重置密码邮件。
- 云端行迹基础链路：登录后会尝试把本地 focus session 与 Supabase 表双向合并。
- 行迹首版信息架构：概览、历史列表、单日时间轴、单次会话详情。

当前明确后置：

- Apple 登录
- Google 登录
- 趋势图
- 热力图

## 运行方式

### 1. 本地模式运行

不配置 Supabase 也可以直接运行，此时账号入口会显示“本地模式”，行迹仅保存在本地缓存。

```powershell
flutter run
```

### 2. 云端模式运行

先在 Supabase 创建项目，并按下文 schema 初始化数据库。然后通过 `dart-define` 注入 URL 和匿名 key：

```powershell
flutter run \
	--dart-define=SUPABASE_URL=https://your-project.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=your-anon-key
```

应用启动时如果未检测到这两个变量，会自动退回本地模式，不会阻塞使用。

## Supabase 初始化

### 1. 创建项目

- 在 Supabase 控制台创建新项目。
- 在 Authentication 中启用 Email provider。
- 首版只依赖邮箱密码，不需要配置 Apple/Google。

### 2. 创建数据表与策略

在 Supabase SQL Editor 中执行 [supabase/focus_sessions.sql](supabase/focus_sessions.sql)。

该脚本会创建：

- `public.user_profiles`
- `public.focus_sessions`
- 对应索引
- 面向当前用户的 RLS 策略

### 3. 云端同步规则

当前同步策略是保守版：

- 未登录时，所有 session 只写本地。
- 登录成功后，会先把本地 session 以当前用户身份上推，再拉取该用户的远端 session 覆盖较旧的本地缓存。
- 冲突判定以 `updated_at` 为准，更新更晚的一方覆盖较旧的一方。
- 统计与历史仍然只看 `is_counted_in_history = true` 的记录。

## 设置页账号入口

设置页中的“账号”区当前支持：

- 登录
- 注册
- 退出登录
- 发送重置密码邮件

如果 Supabase 未配置，点击账号入口会提示如何通过 `dart-define` 开启云端模式。

## 行迹首版范围

当前行迹页面包含：

- 概览卡片
- 历史记录列表
- 单日时间轴
- 单次会话详情

本次没有并入：

- 趋势图
- 热力图

## 已知约束

- Android applicationId 与 iOS bundle identifier 仍是默认示例值，当前不阻塞邮箱密码首版，但在正式上架或引入第三方登录前应尽快替换。
- 当前云端同步依赖 Supabase 中存在 `focus_sessions` 表；若表或策略未创建，应用会保留本地模式数据，但同步调用会失败并输出调试日志。
- 当前同步未引入 realtime 订阅，行迹刷新依赖页面进入、下拉刷新和登录后的同步钩子。

## 回归命令

```powershell
flutter test test/focus_session_test.dart test/incense_view_model_test.dart
```
