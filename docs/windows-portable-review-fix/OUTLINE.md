# Windows 引流版 Review 修复 Outline

## P0 — 阻断性（不修=小白直接用不了 / 安全防线失效）

- [x] 1. 修复 `start.bat` 中 findstr 正则误判 → 改用 `for /f` 白名单字符集减法
- [x] 2. 恢复路径检测的 exit 退出并改用 `DEV_MODE` 环境变量开关
- [x] 3. 修复 `npm install -g pnpm` 全局泄漏 → 设置 `npm_config_prefix=%NODE_DIR%`
- [x] 4. 确认 OpenClaw 源码中 API Key 真实路径为 `models.providers.{name}.apiKey`，修正 `set-key.js`

## P1 — 安全与数据安全

- [x] 5. `openclaw.json` 沙盒从 `open` 收窄至 `workspace`，增加 `allowedPaths`
- [x] 6. `update.bat` 更新前增加 `git stash` 保护用户修改
- [x] 7. `build_portable.ps1` 硬编码路径改为 `Split-Path $MyInvocation.MyCommand.Path`
- [x] 8. `update.bat` 提示文件名改为实际的 `start.bat`

## P2 — 体验优化

- [x] 9. API Key 改用 stdin 管道传递（`echo %KEY% | node set-key.js`）
- [x] 10. 加入 pnpm / node_modules 已存在检测，跳过重复安装
- [x] 11. `build_portable.ps1` 中 pnpm 安装路径修正为 `pnpm.cmd`
- [x] 12. `0.填入API密钥.bat` 增加 7 选 1 厂商选择菜单（含 DeepSeek/OpenAI/通义/Yi/Kimi/Ollama/自定义）
- [x] 13. 编码修复集成到 `build_portable.ps1` 第 4 步 + `fix_encoding.ps1` 改为自动扫描全部 .bat
- [x] 14. 补齐 `data/workspace/` 目录
