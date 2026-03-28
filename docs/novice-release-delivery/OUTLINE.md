# Novice Release Delivery Outline

## 1. 项目级对齐与执行骨架
- [x] 1.1 固化小白发行目标、范围、非目标与阶段顺序
  - 验证引用：`TEST-001`
  - 验证动作：人工核对 `PLANNING.md` 与 `docs/novice-release-checklist.md` 对齐
- [x] 1.2 建立执行态文档与验证矩阵
  - 验证引用：`TEST-001`
  - 验证动作：人工核对 `OUTLINE.md`、`STATE.md`、`ACCEPTANCE.md`、`TRACKERS/TEST-MATRIX.md` 已创建

## 2. Windows fat 正式包闭环
- [x] 2.1 修复 `build/build-windows.ps1` 参数解析与 fail-fast 校验
  - 验证引用：`TEST-002`
  - 验证动作：PowerShell 解析器识别参数块；人工核对缺失源码/共享资产/浏览器资产提示
- [x] 2.2 收敛正式包资产约束与构建输出提示
  - 验证引用：`TEST-003`, `TEST-004`
  - 验证动作：人工核对构建日志文案；待真实 fat 构建 smoke 回补 -> 依赖 2.1

## 3. Windows 用户入口与兼容兜底
- [x] 3.1 把用户主入口改为“先启动，后在页面里配置 API”
  - 验证引用：`TEST-003`
  - 验证动作：人工核对 `README.md`、`start.bat` 文案与兼容说明 -> 依赖 2.1
- [x] 3.2 将 `0.配置AI密钥.bat` 收敛为兼容工具而非推荐首步
  - 验证引用：`TEST-003`
  - 验证动作：人工核对脚本标题、提示语、完成语义 -> 依赖 3.1

## 4. macOS 小白分发路径
- [x] 4.1 定义 macOS 正式包目标形态与当前过渡方案
  - 验证引用：`TEST-006`
  - 验证动作：人工核对 README / 规划文档对当前差距的表述
- [x] 4.2 设计从 shell-first 向 app-first 迁移的实施任务
  - 验证引用：`TEST-006`
  - 验证动作：任务拆解完成并写入 `OUTLINE.md` -> 依赖 4.1
  - 细节：`DOMAINS/macos-distribution.md`

## 5. 验证与发版门槛
- [x] 5.1 建立 Windows fat 正式包 smoke 要求
  - 验证引用：`TEST-004`, `TEST-005`
  - 验证动作：`TRACKERS/TEST-MATRIX.md` 覆盖构建、首启、无 API、页面配置等验证单元
- [ ] 5.2 回补真实机器验证并总结发版阻断项
  - 验证引用：`TEST-004`, `TEST-005`, `TEST-006`
  - 验证动作：真实环境验证记录写入 `ACCEPTANCE.md` / checkpoint -> 依赖 5.1
