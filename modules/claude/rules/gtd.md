# GTD System Rules

## Directory Structure

- `GTD/Tasks/` - All individual task files
- `Templates/task.md` - Task creation template

## Task Status

Each task has one of three states:

| Status | Description |
|--------|-------------|
| `not_yet` | Task not started |
| `in_progress` | Currently working on |
| `done` | Task completed |

## Task Kind

| Kind | Description |
|------|-------------|
| `次に取るべき行動` | Next Action - Immediate actionable tasks |
| `いつかやる` | Someday/Maybe - Tasks for future consideration |
| `買うもの` | Shopping - Items to purchase |
| `ごみ箱` | Trash - Tasks to be discarded |

## Task Creation

Use the task template to ensure consistent structure:

- **ID**: Timestamp format `YYYYMMDDHHmm`
- **Required fields**: creation date, title, aliases, deadline, scheduled date, project, kind, status

## Claude's Responsibilities

1. **Task Decomposition**: Verify tasks are broken down into necessary and sufficient minimal units
2. **Task Suggestions**: Analyze current and historical task patterns to suggest new tasks
3. **Weekly Review Support**: Assist with weekly review processes when requested
4. **Status Validation**: Ensure task status transitions are logical and complete

## Weekly Review Process

### Purpose
- Reconnect with short-term, medium-term, and long-term goals
- Ensure proper task allocation for goal achievement
- Maintain system integrity and effectiveness

### Claude's Support
- Analyze task completion patterns
- Identify bottlenecks or recurring issues
- Suggest task prioritization
- Recommend goal alignment adjustments
- Facilitate systematic review of all active projects
