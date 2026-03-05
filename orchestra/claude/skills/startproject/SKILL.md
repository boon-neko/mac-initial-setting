---
name: startproject
description: |
  Start a new project/feature implementation with multi-agent collaboration.
  Includes multi-session review workflow for quality assurance.
metadata:
  short-description: Project kickoff with multi-agent collaboration
---

# Start Project

**マルチエージェント協調でプロジェクトを開始する。**

## Overview

このスキルは3つのエージェント（Claude, Codex, Gemini）を協調させ、プロジェクト開始から実装後レビューまでをカバーする。

## Workflow

```
Phase 1: Research (Gemini via Subagent)
    ↓
Phase 2: Requirements & Planning (Claude)
    ↓
Phase 2.5: Data Model Design Analysis (Claude) ← データモデルが関わる場合のみ
    ↓
Phase 3: Design Review (Codex via Subagent)
    ↓
Phase 4: Task Creation (Claude)
    ↓
Phase 5: CLAUDE.md Update (Claude)
    ↓
[Implementation...]
    ↓
Phase 6: Multi-Session Review (New Session + Codex)
```

---

## Phase 1: Gemini Research (Background)

**Task tool でサブエージェントを起動し、Gemini でリポジトリ分析。**

```
Task tool parameters:
- subagent_type: "general-purpose"
- run_in_background: true
- prompt: |
    Research for: {feature}

    1. Call Gemini CLI:
       gemini -p "Analyze this repository for: {feature}

       Provide:
       1. Repository structure and architecture
       2. Relevant existing code and patterns
       3. Library recommendations
       4. Technical considerations
       " --include-directories . 2>/dev/null

    2. Save full output to: .claude/docs/research/{feature}.md

    3. Return CONCISE summary (5-7 bullet points)
```

---

## Phase 2: Requirements Gathering (Claude)

**ユーザーに質問して要件を明確化。**

Ask in Japanese:

1. **目的**: 何を達成したいですか？
2. **スコープ**: 含めるもの・除外するものは？
3. **技術的要件**: 特定のライブラリ、制約は？
4. **成功基準**: 完了の判断基準は？

**Draft implementation plan based on Gemini research + user answers.**

---

## Phase 2.5: Data Model Design Analysis (Claude)

**データモデルが関わる機能では、Codexレビュー前に必ずモデル設計を検証する。**

### いつ実行するか

以下のいずれかに該当する場合に実行：

- ステータス・カテゴリの列挙型を設計するとき
- エンティティ間のリレーションを定義するとき
- 1つのフィールドで複数の概念を表現しようとするとき
- ユーザーが「〜状態」「〜種別」「〜フラグ」の設計を提案してきたとき

### チェック項目

**1. 軸の混在チェック（最重要）**

提案された設計が「異なる軸」を1つのフィールドに混ぜていないか確認する。

```
例：「注文ステータス」の設計で
  - 「受付済」「処理中」「発送済」「完了」 → 進捗状態（軸A）
  - 「通常」「優先」「緊急」              → 優先度（軸B）

これらを1つのフィールドに混ぜると概念が崩壊する。
```

**2. 正規化チェック**

- 1つの事実が複数の場所に存在しないか
- 更新時に複数レコードを変更する必要がないか
- NULL が多発する設計になっていないか

**3. スケール確認**

- 将来的に軸が増える可能性はないか
- 「2軸分離」が必要か「フラット統合」で済むか

### ユーザーへの提示方法

設計の問題を発見したら、**代替案を並べて比較提示**する：

```markdown
## データモデル設計の確認

提案された設計に軸の混在が見られます。以下の2案を比較してください。

### 案A: フラット統合（提案通り）
\`\`\`sql
status ENUM('pending', 'processing', 'shipped', 'completed', 'normal', 'priority', 'urgent')
\`\`\`
- メリット: シンプル、フィールドが1つ
- デメリット: 「処理中」と「優先」が同時に成立できない

### 案B: 2軸分離（推奨）
\`\`\`sql
order_status ENUM('pending', 'processing', 'shipped', 'completed')  -- 進捗
priority     ENUM('normal', 'priority', 'urgent')                    -- 優先度
\`\`\`
- メリット: 「処理中で優先」「完了で通常」など自然に表現できる
- デメリット: フィールドが2つになる

どちらの設計で進めますか？
```

**ユーザー確認後、次のPhaseへ進む。**

---

## Phase 3: Codex Design Review (Background)

**Task tool でサブエージェントを起動し、Codex で計画レビュー。**

```
Task tool parameters:
- subagent_type: "general-purpose"
- run_in_background: true
- prompt: |
    Review plan for: {feature}

    Draft plan: {plan from Phase 2}

    1. Call Codex CLI:
       codex exec --sandbox read-only --full-auto "
       Review this implementation plan:
       {plan}

       Analyze:
       1. Approach assessment
       2. Risk analysis
       3. Implementation order
       4. Improvements
       " 2>/dev/null

    2. Return CONCISE summary:
       - Top 3-5 recommendations
       - Key risks
       - Suggested order
```

---

## Phase 4: Task Creation (Claude)

**サブエージェントの要約を統合し、タスクリストを作成。**

Use TodoWrite to create tasks:

```python
{
    "content": "Implement {specific feature}",
    "activeForm": "Implementing {specific feature}",
    "status": "pending"
}
```

---

## Phase 5: CLAUDE.md Update (IMPORTANT)

**プロジェクト固有の情報を CLAUDE.md に追記する。**

Add to CLAUDE.md:

```markdown
---

## Current Project: {feature}

### Context
- Goal: {1-2 sentences}
- Key files: {list}
- Dependencies: {list}

### Decisions
- {Decision 1}: {rationale}
- {Decision 2}: {rationale}

### Notes
- {Important constraints or considerations}
```

**This ensures context persists across sessions.**

---

## Phase 6: Multi-Session Review (Post-Implementation)

**実装完了後、別セッションでレビューを実施。**

### Option A: New Claude Session

1. Start new Claude Code session
2. Run: `git diff main...HEAD` to see all changes
3. Ask Claude to review the implementation

### Option B: Codex Review (via Subagent)

```
Task tool parameters:
- subagent_type: "general-purpose"
- prompt: |
    Review implementation for: {feature}

    1. Run: git diff main...HEAD
    2. Call Codex CLI:
       codex exec --sandbox read-only --full-auto "
       Review this implementation:
       {diff output}

       Check:
       1. Code quality and patterns
       2. Potential bugs
       3. Missing edge cases
       4. Security concerns
       " 2>/dev/null

    3. Return findings and recommendations
```

### Why Multi-Session Review?

- **Fresh perspective**: New session has no bias from implementation
- **Different context**: Can focus purely on review, not implementation details
- **Codex strength**: Deep analysis without context pollution

---

## User Confirmation

Present final plan to user (in Japanese):

```markdown
## プロジェクト計画: {feature}

### 調査結果 (Gemini)
{Key findings - 3-5 bullet points}

### 設計方針 (Codex レビュー済み)
{Approach with refinements}

### タスクリスト ({N}個)
{Task list}

### リスクと注意点
{From Codex analysis}

### 次のステップ
1. この計画で進めてよろしいですか？
2. 実装完了後、別セッションでレビューを行います

---
この計画で進めてよろしいですか？
```

---

## Output Files

| File | Purpose |
|------|---------|
| `.claude/docs/research/{feature}.md` | Gemini research output |
| `CLAUDE.md` | Updated with project context |
| Task list (internal) | Progress tracking |

---

## Tips

- **All Codex/Gemini work through subagents** to preserve main context
- **Update CLAUDE.md** to persist context across sessions
- **Use multi-session review** for better quality assurance
- **Ctrl+T**: Toggle task list visibility
- **ステータス・カテゴリ設計は必ず軸の混在を疑う**: ユーザーが提案してきた設計をそのまま受け入れない。「これは進捗の軸か？評価の軸か？」を自問し、混在していれば Phase 2.5 で代替案を提示する
