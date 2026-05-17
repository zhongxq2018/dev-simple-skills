---
name: zxq_session-handoff
description: Initialize session handoff in a project, or save current session state for next session recovery
---

# Session Handoff

Save and restore work state across Claude Code sessions.

## Mode A: Init (`/zxq_session-handoff init`)

Initialize session handoff in the current project. Perform ALL steps in order:

### Step 1: Ask scope

Ask the user: **SessionStart Hook 配置范围？**
- **全局**：写入 `~/.claude/settings.local.json`，所有项目生效
- **当前项目**：写入项目 `.claude/settings.local.json`，仅本项目生效

Wait for answer before proceeding.

### Step 2: Create memory directory

Create `.claude/memory/` directory in the current project root (if not exists).

### Step 3: Create .claude/memory/handoff.md

Write the following template to `.claude/memory/handoff.md`:

```markdown
# Session Handoff

## Current Focus


## Current State


## Key Context


## Next Actions


## Relevant Files


## Risks / Warnings

```

Only create if the file does not already exist. Do NOT overwrite an existing handoff.md.

### Step 4: Update CLAUDE.md

Check if `CLAUDE.md` exists in the project root:

- **If NOT exists**: Create it with the Session Recovery rules (see below).
- **If exists**: Read it first. Check if it already contains "Session Recovery" or "session-handoff". If so, skip. If not, append the Session Recovery rules at the end.

Session Recovery rules to add:

```markdown
## Workflow

### Session Recovery
新会话开始时：
1. 阅读 .claude/memory/handoff.md 恢复当前工作状态
2. 结合 git status 和最近修改
3. 再开始新的修改
```

**Important**: If CLAUDE.md already has a `## Workflow` section, append the Session Recovery subsection under the existing `## Workflow` instead of creating a duplicate section.

### Step 5: Configure SessionStart Hook

Based on user's choice in Step 1:

**If 全局 (global)**:
1. Read `~/.claude/settings.local.json` (create if not exists)
2. Add/merge the SessionStart hook. The hook should run a command that reads `memory/handoff.md` from the current project.

The hook configuration format:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "cat .claude/memory/handoff.md 2>/dev/null || echo 'No handoff file found'",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**If 当前项目 (current project)**:
1. Read project `.claude/settings.local.json` (create if not exists, in project root `.claude/` directory)
2. Add the same SessionStart hook configuration as above.

Carefully merge with existing hooks if the file already has a `hooks` section. Do NOT remove existing hooks.

### Step 6: Output confirmation

List all files created/modified with their paths. Summarize what was done.

---

## Mode B: Handoff (`/zxq_session-handoff`)

When user runs `/zxq_session-handoff` (no `init` argument), save current session state.

### Step 0: Check initialization

Check if `.claude/memory/handoff.md` exists in the current project:

- **If exists**: Proceed to Step 1
- **If NOT exists**: Tell the user the project has not been initialized for session handoff. Ask: **检测到项目尚未初始化 session-handoff，是否先执行初始化？** Wait for answer:
  - If yes: Run Mode A init steps (Step 2-6), then proceed to Step 1
  - If no: Skip handoff and end

### Step 1: Analyze current session

Review the conversation to identify:
- **Current Focus**: What feature/bug/task is being worked on
- **Current State**: What has been completed, what is in progress
- **Key Context**: Important decisions, constraints, gotchas discovered
- **Next Actions**: What should be done next (specific, actionable)
- **Relevant Files**: Files that were read or modified this session
- **Risks/Warnings**: Anything that could go wrong or needs attention

After analysis, if the session has **no substantive work in progress** (no pending tasks, no files modified, no unfinished work), write the empty template (same as the init template in Mode A Step 3) to `.claude/memory/handoff.md`, overwriting the file. Then tell the user: "当前会话无需交接，handoff.md 已重置。" End Mode B — do NOT proceed to Step 2.

### Step 2: Write handoff.md

Write the analysis to `.claude/memory/handoff.md` in the project root. **Directly overwrite** the file (do NOT append).

Requirements:
- Be concise and actionable — oriented toward "resuming work"
- No fluff or filler text
- Use the template structure from Mode A
- Include specific file paths and line numbers where relevant

### Step 3: Confirm

Tell the user the handoff has been saved and they can safely end the session.

---

## Mode C: Clear (`/zxq_session-handoff clear`)

When user runs `/zxq_session-handoff clear`, reset handoff.md to its initial template state.

### Step 1: Check initialization

Check if `.claude/memory/handoff.md` exists:

- **If exists**: Proceed to Step 2
- **If NOT exists**: Tell the user: "handoff.md 不存在，项目尚未初始化 session-handoff。" End.

### Step 2: Reset handoff.md

Write the empty template (same as the init template in Mode A Step 3) to `.claude/memory/handoff.md`, overwriting the file.

### Step 3: Confirm

Tell the user: "handoff.md 已重置为初始状态。"
