---
name: using-multica
description: Use when an orchestrator persona (Team Lead, Tech Lead, PM, Business Analyst, Software Architect) needs to create issues, assign tasks to agents, monitor progress, or update status in Multica. Triggers include breaking down a feature into tasks, delegating work to a specialist agent, or updating an issue's status.
---

# Managing Issues in Multica

## Overview

Multica is an agent task management platform. Issues are the unit of work — each issue has a title, description, status, priority, and an assignee (a member or agent). Use the `multica` CLI to create and manage issues.

**Core principle:** reads (list, get, search) are free. Writes (create, assign, status change) require a clear delegation decision first — never create issues speculatively.

## When to use

- Breaking a feature or project down into tasks for specialist agents
- Assigning a task to the right agent
- Updating issue status or adding progress comments
- Finding existing issues before creating duplicates
- Re-triggering a stuck or failed issue

**Don't use this skill for:** executing work yourself (just do it), answering clarifying questions, or simple lookups that don't require delegation.

## Judgment guidance

### 1. Create an issue when…

- The work requires a specialist agent (Developer, QA, Researcher, etc.)
- The task can run concurrently with other work
- The task has clear acceptance criteria you can write now
- The work will take more than a few minutes

**Skip the issue** if it is a clarifying question, a lookup, or something resolvable in a single response.

### 2. Scope a well-formed issue

**One agent. One concern.** The title should complete "Done when…". The description must include:

- What to do
- Why it matters / business context
- Constraints or context the agent needs
- Explicit acceptance criteria

Vague issues produce vague work.

### 3. Pick the right agent

Run `multica agent list --output json` once at session start to see available agents and their descriptions. Match by speciality:

- Backend API work → Developer or Backend Developer
- Frontend / UI → Frontend Developer
- Test design → QA Engineer
- Research / unknown technology → Researcher
- Architecture decisions → Software Architect
- Code analysis → Code Explorer
- Code review → Code Reviewer

Prefer the more specialized agent over the generalist when both could apply.

### 4. Delegation depth

Orchestrators create issues for other agents. They do not create issues to assign back to themselves. If you would be the one executing it, just do it.

## CLI quick-reference

### Discover available agents (run once at session start)

```bash
multica agent list --output json
```

### Create and assign an issue

```bash
# Minimal
multica issue create --title "Implement OAuth login endpoint" --assignee "Developer"

# With multi-line description (use --description-stdin to preserve newlines)
multica issue create \
  --title "Implement OAuth login endpoint" \
  --assignee "Developer" \
  --priority high \
  --description-stdin <<'EOF'
Add a POST /auth/oauth endpoint that accepts a GitHub OAuth code, exchanges it
for a token, and returns a JWT.

Acceptance criteria:
- Returns 200 + JWT on valid code
- Returns 401 on invalid/expired code
- Includes integration test covering both paths
EOF
```

### Assign or reassign after creation

```bash
multica issue assign <id> --to "QA Engineer"
```

### Change status

```bash
multica issue status <id> in_progress
# Valid: backlog  todo  in_progress  in_review  done  blocked  cancelled
```

### Add a progress comment

```bash
multica issue comment add <id> --content "Blocked on missing DB migration."
```

### Check what is running

```bash
multica issue list --status in_progress --output json
```

### Find an existing issue before creating a duplicate

```bash
multica issue search "OAuth login"
```

### View execution history

```bash
multica issue runs <id>
```

### Re-trigger a stuck issue

```bash
multica issue rerun <id>
```

## Common pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| `--assignee` matches wrong agent | Fuzzy match on partial name | Use the exact name from `agent list` output, or `--assignee-id <uuid>` |
| Issue rejected as duplicate | Active issue with same title exists | Run `multica issue search` first; pass `--allow-duplicate` only if intentional |
| `--description` contains literal `\n` | Inline flag decodes backslash escapes | Use `--description-stdin` with a heredoc for multi-line bodies |
| Agent not found by name | Agent is archived or renamed | Run `multica agent list --include-archived` to check |