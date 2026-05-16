# Satori Mini Program

微信小程序版本由 AvAn0sch 协作开发，保留 Satori 的东方美学方向，但功能组织更接近任务管理 + 番茄钟 + 打卡统计的小程序体验。

原始协作仓库：<https://gitee.com/avan0/clock>

当前 GitHub 主仓库中的小程序目录是清理后的源码副本。由于早期历史里曾出现过客户端密钥，不建议把未清洗的历史直接导入公开 GitHub 仓库；如需完整保留历史，应先清洗历史后再用 `git subtree` 导入。

## 功能范围

- 任务：清单、任务创建、筛选、搜索、排序、番茄数量和专注时长设置。
- 番茄计时：专注/休息周期、焚香动画、暂停、结束、跳过休息、白噪音。
- 日历：月历、今日任务完成情况、打卡、国风名言弹窗。
- 统计：专注概览、近 7 天趋势、AI 总结入口。
- 设置：主题、默认白噪音、休息铃声、休息时长、关于页面。

## 运行

```powershell
npm install
npm run typecheck
```

然后使用微信开发者工具打开 `satori_miniprogram`。

公开仓库中的 `project.config.json` 使用 `touristappid`。如果要调试真实登录、上传或发布，请在微信开发者工具中换成自己的 AppID，个人私有配置不要提交。

## 安全说明

小程序端不能直接保存 DeepSeek / OpenAI 等服务端 API key。当前 `utils/ai.ts` 默认不启用远端 AI，总结会走本地兜底文案。正式接入时建议改为：

1. 小程序调用云函数或自有服务端。
2. 服务端持有第三方 API key。
3. 服务端按用户、频率和内容长度做限流与审计。

## 文档

更完整的结构、数据和已知问题见 [../docs/miniprogram.md](../docs/miniprogram.md)。
