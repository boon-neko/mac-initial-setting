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
Phase 2: Requirements Definition (Claude + User) ← 受け入れ条件(AC)を成果物化
    ↓
Phase 2.5: Data Model Design Analysis (Claude) ← データモデルが関わる場合のみ
    ↓
Phase 3: Requirements & Plan Review (Codex via Subagent)
    ↓
Phase 4: Task Creation (Claude)
    ↓
Phase 5: Persist Requirements & Plan ← タスクファイル + CLAUDE.md
    ↓
[Implementation...]
    ↓
Phase 6: Spec Compliance & Quality Review (Codex)
```

**全工程を貫く原則: 要件は会話ではなく成果物。** Phase 2 で受け入れ条件（AC）を文書化し、
計画・タスク・テスト・レビュー・完了報告の全てがACを参照する。

---

## Reviewer Resolution

レビュー（Phase 3 / Phase 6）の実行手段は、CLAUDE.md の Workflow Conventions の `Reviewer` で決まる:

| Reviewer | 実行方法 |
|----------|----------|
| `codex`（デフォルト） | サブエージェント経由で `codex exec --sandbox read-only --full-auto "..."` を実行 |
| `claude-subagent` | サブエージェント（general-purpose）に**レビュープロンプトを直接実行**させる。Codex CLI が使えない現場向け。実装の経緯を知らない新しいコンテキストである点が重要 |
| `human` | レビュー資料（要件・diff・チェック観点）を整形してユーザーに提示し、判定を待つ |

未定義の場合は `codex`、Codex CLI 未導入なら `claude-subagent` にフォールバック。

以降のレビュー例は codex 形式で書くが、**レビュープロンプトの中身（要件適合・品質チェック）は全 Reviewer 共通**。
`claude-subagent` の場合は `codex exec` を介さず、同じプロンプトをサブエージェント自身への指示にする。
`human` の場合は同じ観点リストを資料としてユーザーに渡す。

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

## Phase 2: Requirements Definition (Claude)

**`requirements` スキル（plugin では `/orchestra:requirements`）を実行し、要件定義書を作成する。**

requirements スキルが行うこと（フォーマットとルールの正はスキル本体）:

1. brainstorming式の質問で要件を明確化（目的・スコープ・技術要件・成功基準）
2. **要件定義書**（受け入れ条件 AC・非ゴール・検証方法）を固定フォーマットで作成
3. 「**このACが全て満たされたら完了、という認識で合っていますか？**」をユーザーに確認し、承認を得る

**Draft implementation plan based on Gemini research + acceptance criteria.**
計画の各ステップに対応するAC番号を付記する（どのACにも対応しないステップはスコープクリープの兆候）。

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

## Phase 3: Requirements & Plan Review (Reviewer, Background)

**Task tool でサブエージェントを起動し、「要件の曖昧さ」と「計画のAC網羅性」を両方レビュー。**
（実行手段は「Reviewer Resolution」参照。以下は codex の例）

計画の妥当性だけでなく、**要件そのものの曖昧さを先に潰す**。
「要件通りでない実装」の大半は実装ミスではなく、要件の解釈分岐が原因。

```
Task tool parameters:
- subagent_type: "general-purpose"
- run_in_background: true
- prompt: |
    Review requirements and plan for: {feature}

    1. Call Codex CLI:
       codex exec --sandbox read-only --full-auto "
       Review this requirements document and implementation plan.

       ## Requirements (Acceptance Criteria)
       {requirements from Phase 2}

       ## Draft Plan
       {plan}

       Part 1 — Requirements review:
       1. Ambiguous or untestable acceptance criteria
          (could two engineers interpret them differently?)
       2. Contradictions, missing edge cases, implicit assumptions
       3. Anything in the plan that suggests an unstated requirement

       Part 2 — Plan review:
       4. AC coverage: does every AC have a corresponding plan step?
          List uncovered ACs.
       5. Scope check: any plan step not tied to any AC?
       6. Approach assessment, risks, implementation order
       " 2>/dev/null

    2. Return CONCISE summary:
       - Requirements issues (must resolve before implementation)
       - AC coverage gaps / scope creep
       - Top 3-5 plan recommendations
```

**要件側の指摘（曖昧・解釈分岐・暗黙の前提）が出た場合は Phase 2 に戻り、
ユーザーに確認してACを修正してから先に進む。**

---

## Phase 4: Task Creation (Claude)

**サブエージェントの要約を統合し、タスクリストを作成。**

Use TodoWrite to create tasks:

```python
{
    "content": "Implement {specific feature} (AC-1, AC-2)",
    "activeForm": "Implementing {specific feature}",
    "status": "pending"
}
```

- 各タスクに対応するAC番号を付記する
- どのACにも紐づかないタスクは作らない（必要なら先にACを追加してユーザー確認）

---

## Phase 5: Persist Requirements & Plan (IMPORTANT)

**承認された要件定義と計画を、セッションが消えても残る場所に書き込む。**
Phase 6 のレビューと完了判定は、ここで書いたファイルを「正」として参照する。

1. **タスクファイルへの書き戻し（最優先）**:
   CLAUDE.md の Workflow Conventions にタスクファイルの場所が定義されていれば、
   タスクファイルに「要件定義（AC・非ゴール・検証方法）」と「承認済み計画」を書き込む
2. タスクファイルの仕組みがないプロジェクトでは `docs/plans/{YYYY-MM-DD}-{feature}.md` に保存する
3. プロジェクト固有のコンテキストを CLAUDE.md に追記する

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

**This ensures context persists across sessions — and gives Phase 6 a ground truth to review against.**

---

## Phase 6: Spec Compliance & Quality Review (Post-Implementation)

**実装完了後、(a) 要件適合 と (b) コード品質 の2観点でレビューする。**
diffだけ渡して「良いコードか」を聞くのは不十分。**必ず Phase 5 で永続化した要件（AC）を一緒に渡す。**

### Reviewer Review (via Subagent)

（実行手段は「Reviewer Resolution」参照。以下は codex の例）

```
Task tool parameters:
- subagent_type: "general-purpose"
- prompt: |
    Review implementation for: {feature}

    1. Read requirements: {Phase 5 で書いたタスクファイル / plans ファイルのパス}
    2. Run: git diff {main branch}...HEAD
    3. Call Codex CLI:
       codex exec --sandbox read-only --full-auto "
       Review this implementation against its requirements.

       ## Requirements (Acceptance Criteria)
       {requirements}

       ## Diff
       {diff output}

       Part 1 — Spec compliance (most important):
       For EACH acceptance criterion:
       - Implemented? Point to the specific change.
       - Tested? Point to the specific test
         (or note it requires manual verification).
       - Verdict: PASS / FAIL / UNVERIFIABLE
       Then: list any changes NOT tied to any AC (scope creep),
       and confirm the non-goals were respected.

       Part 2 — Code quality:
       - Bugs, missing edge cases, security concerns
       - Consistency with existing patterns

       Return: APPROVE or REQUEST_CHANGES, including the per-AC table.
       " 2>/dev/null

    4. Return verdict + per-AC table + key findings
```

- **APPROVE** → 検証方法の表に従い、手動確認分の動作確認を実施 → 完了報告
- **REQUEST_CHANGES** → 修正して再レビュー

### Option: Multi-Session Review

大きな変更では、新しい Claude Code セッションに `git diff main...HEAD` とタスクファイルを
レビューさせると、実装セッションのバイアスがない視点が得られる。

### 完了報告フォーマット

完了報告は**ACごとの検証結果表**で行う。「実装しました」ではなく「各ACをこう検証した」を示す。

```markdown
## 完了報告: {feature}

| AC | 内容 | 検証 | 結果 |
|----|------|------|------|
| AC-1 | {要約} | test_xxx | ✅ |
| AC-2 | {要約} | 手動: {コマンド} | ✅ {観測結果} |

- 非ゴール逸脱・スコープ外変更: なし
- lint / test: pass
```

---

## User Confirmation

Present final plan to user (in Japanese):

```markdown
## プロジェクト計画: {feature}

### 受け入れ条件（この実装の完了基準）
{AC-1 〜 AC-N の一覧}

### 非ゴール（やらないこと）
{一覧}

### 調査結果 (Gemini)
{Key findings - 3-5 bullet points}

### 設計方針 (Codex レビュー済み)
{Approach with refinements}

### タスクリスト ({N}個・各タスクに対応AC付き)
{Task list}

### 検証方法
{AC → unit test / E2E / 手動確認 の表}

### リスクと注意点
{From Codex analysis}

---
このACと計画で進めてよろしいですか？
```

承認は plan mode の承認（ExitPlanMode）または明示的な「OK」「進めて」で得る。
**曖昧な相槌を承認と見なさない。**

---

## Output Files

| File | Purpose |
|------|---------|
| `.claude/docs/research/{feature}.md` | Gemini research output |
| タスクファイル or `docs/plans/{date}-{feature}.md` | 要件定義（AC）+ 承認済み計画。**Phase 6 レビューの基準** |
| `CLAUDE.md` | Updated with project context |
| Task list (internal) | Progress tracking |

---

## Tips

- **All Codex/Gemini work through subagents** to preserve main context
- **ACに紐づかない作業はしない**: 計画ステップ・タスク・diff の全てがいずれかのACに対応する。対応しないものが出たら要件定義に戻る
- **Update CLAUDE.md** to persist context across sessions
- **Use multi-session review** for better quality assurance
- **Ctrl+T**: Toggle task list visibility
- **ステータス・カテゴリ設計は必ず軸の混在を疑う**: ユーザーが提案してきた設計をそのまま受け入れない。「これは進捗の軸か？評価の軸か？」を自問し、混在していれば Phase 2.5 で代替案を提示する
