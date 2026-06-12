---
name: flow-init
description: |
  Analyze project structure, detect tech stack, and establish workflow conventions
  (task management, branch naming, merge method, reviewer) in CLAUDE.md.
  Use when bootstrapping a new project or when Workflow Conventions are missing from CLAUDE.md.
  Note: distinct from the built-in /init (CLAUDE.md generator) — this one sets Workflow Conventions.
---

# Initialize Project Configuration

Analyze this project and establish workflow conventions in CLAUDE.md.

## Steps

### 1. Project Analysis

Find these files to identify the tech stack:

- `package.json` → Node.js/TypeScript project
- `pyproject.toml` / `setup.py` / `requirements.txt` → Python project
- `Cargo.toml` → Rust project
- `go.mod` → Go project
- `Makefile` / `Dockerfile` → Build/deploy config
- `.github/workflows/` / `.gitlab-ci.yml` → CI/CD config

Also detect:

- npm scripts / poe tasks / make targets → Common commands
- Major libraries/frameworks
- Existing CLAUDE.md content (do not overwrite, merge)

### 2. Ask User - Project Overview

Use AskUserQuestion tool to ask:

1. **Project overview**: What does this project do? (1-2 sentences)
2. **Code language**: English or Japanese for comments/variable names?
3. **Additional rules**: Any other coding conventions to follow?

### 3. Ask User - Workflow Conventions

Use AskUserQuestion tool to ask:

1. **Task management tool**: GitHub Issues / GitLab Issues / Jira / Notion / Linear / other?
2. **Task file location**: Do you keep task files locally? If so, where? (e.g., `docs/tasks/`, `tasks/`, or none)
3. **Task file naming**: How are task files named? (e.g., `{number}-{name}.md`, free-form, N/A)
4. **Branch naming convention**: e.g., `feature/{number}-{name}`, `feat/{name}`, `issue/{number}`, other?
5. **Main branch name**: `main` or `master` or other?
6. **Research/docs output directory**: Where to save research reports? (e.g., `docs/research/`, `.claude/docs/research/`, or none)
7. **Reviewer**: 計画・実装レビューの実行手段は？
   - `codex` (Recommended): Codex CLI でレビュー（要 `codex` インストール）
   - `claude-subagent`: 別コンテキストの Claude サブエージェントでレビュー（Codex CLI が使えない現場向け）
   - `human`: レビュー資料を整形して人間がレビュー
   - 環境を確認し、Codex CLI が無い場合は `claude-subagent` を推奨先頭にする
8. **Merge method**: 完了した変更のマージ方式は？
   - `local-merge`: feature ブランチをローカルでメインブランチにマージ（ソロ開発向け）
   - `pull-request`: push して PR/MR を作成し、レビュー承認後にマージ（チーム開発・branch protection あり）
   - リポジトリに branch protection や既存PRの形跡があれば `pull-request` を推奨先頭にする

### 4. Write CLAUDE.md

Generate or update CLAUDE.md with the following sections. If CLAUDE.md already exists, **merge** without overwriting existing content.

```markdown
# Project Overview

{User's answer}

## Language Settings

- **Thinking/Reasoning**: English
- **Code**: {Based on analysis - English or Japanese}
- **User Communication**: Japanese

## Tech Stack

- **Language**: {Detected language}
- **Package Manager**: {Detected tools}
- **Dev Tools**: {Detected tools}
- **Main Libraries**: {Detected libraries}

## Common Commands

```bash
{Detected commands}
```

## Workflow Conventions

- **Task Management**: {Tool name}
- **Task File Location**: {Path or "none"}
- **Task File Naming**: {Pattern or "N/A"}
- **Branch Naming**: {Pattern}
- **Main Branch**: {Branch name}
- **Research Output**: {Path or "none"}
- **Reviewer**: {codex | claude-subagent | human}
- **Merge Method**: {local-merge | pull-request}
- **Wrapper Model**: haiku（委譲サブエージェントの既定。判定を運ぶ係は sonnet 以上。エイリアスのみ）
```

※ Wrapper Model はデフォルト値をそのまま書いてよい（質問不要）。変えたい現場だけ編集する。

### 5. Check Unnecessary Rules

Check rules in `.claude/rules/` and suggest removing unnecessary ones:

- Non-Python project → `dev-environment.md` (uv/ruff/ty) may not be needed
- No-test project → `testing.md` may not be needed

### 6. Report Completion

Report to user (in Japanese):

- Detected tech stack
- Established workflow conventions
- Updated sections in CLAUDE.md
- Recommended rules to remove (if any)
- Remind: Other skills (`/orchestra:sin-task`, `/orchestra:para-task`) will read these conventions from CLAUDE.md
