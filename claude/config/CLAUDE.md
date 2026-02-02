# Guidelines

This document defines the project's rules, objectives, and progress management methods. Please proceed with the project according to the following content.

## Top-Level Rules

- To maximize efficiency, **if you need to execute multiple independent processes, invoke those tools concurrently, not sequentially**.
- **You must think exclusively in English**. However, you are required to **respond in Japanese**.
- To understand how to use a library, **always use the Contex7 MCP** to retrieve the latest information.

## Programming Rules

- Avoid hard-coding values unless absolutely necessary.
- When coding in Go, please do not use `any` or `interface{}` for argument types except for generic utility functions.**
- When writing comments for code, please write them in Japanese.**

## Skill Creation Rules

- スキルを作成する際は、**グローバルスキル**か**プロジェクト固有スキル**かを判断すること
  - グローバル（`~/.claude/skills/`）: 複数プロジェクトで使える汎用的なもの
  - プロジェクト（`.claude/skills/`）: 特定プロジェクト固有のもの
- 判断に迷ったらユーザーに確認すること

# MCP Documentation
@MCP_Context7.md
@MCP_Playwright.md
