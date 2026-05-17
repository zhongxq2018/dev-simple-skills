# dev-simple-skills

实用的 Claude Code skills 集合，帮助提升开发效率。

## 包含的 Skills

| Skill | 说明 |
|-------|------|
| **session-handoff** | 跨会话保存和恢复工作状态，支持自动加载上次进度 |
| **work-log** | 项目长期记忆系统，记录关键功能变化、架构决策和方案演进 |

## 安装

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/zhongxq/dev-simple-skills/main/install.sh | bash
```

### 手动安装

```bash
git clone https://github.com/zhongxq/dev-simple-skills.git
cd dev-simple-skills
./install.sh
```

安装后重启 Claude Code 即可使用。

## 使用

### session-handoff

- `/session-handoff init` — 在项目中初始化会话恢复功能
- `/session-handoff` — 保存当前会话状态，方便下次恢复

### work-log

- `/work-log` — 记录本次会话的关键变更和决策到项目长期日志

两个 skill 配合使用：`session-handoff` 管理短期记忆（当前进度），`work-log` 管理长期记忆（历史决策）。

## License

MIT
