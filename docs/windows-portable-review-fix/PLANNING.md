# Windows 引流版代码 Review 修复

## Goal
- 目标：修复 code_review.md 中发现的 14 个问题，让 `windows/` 引流版达到可安全发版的质量基线
- 范围：仅限 `windows/` 目录下的脚本、配置文件和打包工具
- 非目标：不涉及 `openclaw/` 源码本身的修改；不涉及 Linux 盒子版；不涉及 UI 定制

## Context
- 涉及模块：`start.bat`, `update.bat`, `0.点我填入大模型API密钥.bat`, `scripts/set-key.js`, `data/openclaw.json`, `build_portable.ps1`, `README.md`
- 关键约束：
  - 所有 .bat 文件必须保证 UTF-8 with BOM + CRLF 编码
  - 便携包必须绝对零系统侵入（不向 `%APPDATA%` 等宿主路径写入任何内容）
  - 密钥注入路径必须与 OpenClaw 源码真实消费路径一致
- 现有实现摘要：已完成基础脚本框架和开箱即用配置劫持，但存在安全和稳定性缺陷

## Architecture Notes
- 主要改动点：findstr 正则修复、npm prefix 劫持、pnpm 跳过机制、API Key stdin 传递、沙盒权限收窄
- API 契约影响：无
- 数据库迁移影响：无
- 安全影响：沙盒模式从 `open` 收窄到受限模式；API Key 不再出现在进程参数列表

## Risks
- 风险：`set-key.js` 中 API Key 的 JSON 路径需要到 OpenClaw 源码确认，否则用户写入密钥后不生效
- 回滚方式：所有改动均为脚本文件层面，git revert 即可
