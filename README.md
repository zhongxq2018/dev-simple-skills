# dev-simple-skills

实用的 Claude Code skills 集合，帮助提升开发效率。

## 包含的 Skills

| Skill | 说明 |
|-------|------|
| **zxq_session-handoff** | 跨会话保存和恢复工作状态，支持自动加载上次进度 |
| **zxq_work-log** | 项目长期记忆系统，记录关键功能变化、架构决策和方案演进 |

## 安装

Skills 安装到全局目录 `~/.claude/skills/`，所有项目都可用。

### macOS / Linux

```bash
# 一键安装全部
curl -fsSL https://raw.githubusercontent.com/zhongxq2018/dev-simple-skills/main/install.sh | bash -s -- --all

# 克隆后交互选择
git clone https://github.com/zhongxq2018/dev-simple-skills.git
cd dev-simple-skills
./install.sh              # 交互选择要安装的技能
./install.sh --all        # 全部安装
```

### Windows (PowerShell)

```powershell
# 一键安装全部
.\install.ps1 -All

# 交互选择
.\install.ps1              # 交互选择要安装的技能
.\install.ps1 -All         # 全部安装
```

运行后会列出所有可用 skills，输入数字选择要安装的（支持多选，`0` 表示全部安装）。

安装后重启 Claude Code 即可使用。

## 卸载

### macOS / Linux

```bash
./uninstall.sh              # 交互选择要卸载的技能
./uninstall.sh --all        # 卸载全部
```

### Windows (PowerShell)

```powershell
.\uninstall.ps1              # 交互选择要卸载的技能
.\uninstall.ps1 -All         # 卸载全部
```

## 使用

### zxq_session-handoff

保存和恢复跨会话的工作状态。

**初始化（首次使用）：**

```
/zxq_session-handoff init
```

会在项目中创建 `.claude/memory/handoff.md` 模板，并配置 SessionStart Hook。支持全局生效或仅当前项目生效。

**保存状态（结束会话前）：**

```
/zxq_session-handoff
```

将当前工作状态（进行中的任务、关键上下文、下一步操作等）写入 `handoff.md`。

**自动恢复：**

配置 Hook 后，每次开启新会话时，Claude Code 会自动读取 `handoff.md` 的内容并恢复上次的工作上下文。无需手动操作。

### zxq_work-log

记录项目关键变更和架构决策，构建项目长期记忆。

```
/zxq_work-log
```

每次会话结束前运行，将本次的关键变更（功能、决策、方案调整等）写入 `.claude/memory/log/YYYY-MM.md`。历史记录不可修改，保证项目决策的完整演进过程。

---

两个 skill 配合使用：**zxq_session-handoff** 管理短期记忆（当前进度），**zxq_work-log** 管理长期记忆（历史决策）。

## License

MIT
