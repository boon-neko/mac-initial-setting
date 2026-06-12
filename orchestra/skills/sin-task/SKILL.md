---
name: sin-task
description: |
  単体セッションでタスクを開始する。startprojectフローを経てから実装に入る。
  /sin-task {issue番号} で起動。
metadata:
  short-description: 単体タスク開始（startproject経由）
---

# /sin-task {issue番号}

**単体セッションでタスクを実行する。必ずstartprojectフローを経由する。**

## Prerequisites

CLAUDE.md にプロジェクトのワークフロー規約が定義されていること。
未定義の場合は先に `/orchestra:flow-init` を実行してプロジェクト規約を設定する。

CLAUDE.md から以下を読み取る:
- **Task Management**: タスク管理ツール (GitHub Issues / GitLab / Jira / etc.)
- **Task File Location**: タスクファイルの場所 (あれば)
- **Branch Naming**: ブランチ命名規則
- **Main Branch**: メインブランチ名
- **Merge Method**: マージ方式（local-merge / pull-request。未定義なら local-merge）
- **Reviewer**: レビュー実行手段（codex / claude-subagent / human。未定義なら codex）

## 引数

- `$ARGUMENTS`: Issue番号（例: `052`）

## フロー

```
1. CLAUDE.mdからプロジェクト規約を読み取る
2. タスク情報収集 + 規模トリアージ（S/M/L）
3. /startproject フロー実行（Research → Requirements(AC) → Codex Review → User Confirmation）
4. 要件+承認済み計画をタスクファイルに書き戻す
5. ブランチ作成
6. 現セッションで実装開始
7. 要件適合レビュー → 動作確認 → マージ
```

## 手順

### Step 0: プロジェクト規約の読み取り

CLAUDE.md の「Workflow Conventions」セクションを読む。
存在しない場合は「`/orchestra:flow-init` を先に実行してください」とユーザーに伝えて停止。

以下の変数を取得:
- `TASK_TOOL`: タスク管理ツール
- `TASK_DIR`: タスクファイルの場所（なければ空）
- `BRANCH_PATTERN`: ブランチ命名規則
- `MAIN_BRANCH`: メインブランチ名
- `MERGE_METHOD`: マージ方式（未定義なら local-merge）

### Step 1: タスク情報収集

タスク管理ツールに応じてIssue/タスクを取得:
- GitHub Issues: `gh issue view $ARGUMENTS`
- GitLab: `glab issue view $ARGUMENTS`
- Jira / Linear / Notion 等: 接続済みの MCP サーバーがあればそれで取得（ToolSearch で `jira` `linear` 等を検索）
- 取得手段がない場合: ユーザーにタスク内容の貼り付けを依頼

タスクファイルがあれば読む（TASK_DIRが定義されている場合）。

タスクファイルの内容はメモ書き程度の場合がある。タスクファイルが詳細でも、要件定義（AC）の工程は省略しない。

### Step 1.5: 規模トリアージ

タスク情報から規模を判定し、**判定結果と適用フローをユーザーに宣言してから**進める:

| 規模 | 目安 | フロー |
|------|------|--------|
| **S** | typo・設定値・1ファイルの軽微修正（挙動変更なし、または検証が自明） | Phase 1（Gemini Research）と Phase 2.5 を省略可 |
| **M** | 挙動変更あり、影響範囲が限定的 | フルフロー（Research は軽量でも可） |
| **L** | 新機能・複数ファイル・データモデル変更 | フルフロー必須 |

**規模に関わらず省略禁止**: ACの文書化（Sは1〜3個で良い）、ユーザー承認、実装後の要件適合レビュー。
迷ったら大きい方に倒す。

### Step 2: タスクファイルのステータス更新

タスクファイルがあれば、ステータスを `🔄 進行中` に更新する。

### Step 3: /startproject フロー実行

**Step 1.5 のトリアージ結果に従い、以下のPhaseを実行する。**

- **Phase 1**: Gemini Research（サブエージェント、バックグラウンド）※S判定なら省略可
- **Phase 2**: Requirements Definition（`requirements` スキルで AC・非ゴール・検証方法を文書化し、「このACで完了か」をユーザーに確認）
- **Phase 2.5**: Data Model Analysis（データモデルが関わる場合のみ）
- **Phase 3**: Requirements & Plan Review（Codex: 要件の曖昧さ + 計画のAC網羅性）
- **User Confirmation**: AC と計画をユーザーに提示し、明示的な承認を得る

**Phase 4（Task Creation）はタスクファイルが既に存在するためスキップ可。
Phase 5（Persist）は省略不可** — ユーザー承認後、要件定義（AC・非ゴール・検証方法）と
承認済み計画をタスクファイルに書き戻す。実装後のレビューはこのファイルを正として行う。

### Step 4: ブランチ作成

ユーザー承認後、BRANCH_PATTERNに従ってブランチを作成:

```bash
git checkout {MAIN_BRANCH}
git pull
git checkout -b {BRANCH_PATTERN に基づくブランチ名}
```

### Step 5: 実装開始

実装に入る前に、ユーザーに `/goal` の設定を提案する（ネイティブの完走保証。条件を満たすまでセッションが終了しなくなる）:

```
/goal {タスク番号} の全ACが PASS の検証結果表付きで完了報告される
```

CLAUDE.md の開発ルールに従って実装を進める:
- Understand → Design → Test → Code → Verify
- テストはACから書く（AC → テストケースの対応を保つ）
- Commit as you go
- 完了後に Codex Review（startproject Phase 6 の要件適合形式: AC毎に PASS/FAIL + スコープ外変更チェック）
  → 動作確認（検証方法の表の「手動確認」分を実施）→ Merge

### Step 6: マージ（MERGE_METHOD で分岐）

**local-merge（ソロ開発）の場合:**

```bash
git checkout {MAIN_BRANCH}
git merge {ブランチ名}
git push origin {MAIN_BRANCH}
git branch -d {ブランチ名}
```

タスクファイルがあればステータスを `✅ 完了` に更新。

**pull-request（チーム開発）の場合:**

```bash
git push -u origin {ブランチ名}
gh pr create --title "{タイトル}" --body "{本文}"   # GitLab なら glab mr create
```

- **PR本文にACごとの検証結果表を含める**（レビュアーへの説明資料になる）
- **自分でマージしない** — レビュー承認後のマージは現場のルールに従う
- タスクファイルがあればステータスを `👀 レビュー待ち` に更新

どちらの場合も、完了報告は**ACごとの検証結果表**（startproject Phase 6 のフォーマット）で行う。
レビューで指摘が複数出たタスクでは、`/retro` での振り返りを提案する。

## IMPORTANT

- **このスキルを経由せずにタスク実装を開始しない**
- 工程の省略判断は Step 1.5 のトリアージでのみ行う（その場の判断で工程を飛ばさない）
- 規模に関わらず、ACの文書化・ユーザー承認・要件適合レビューは省略しない
- ユーザー承認なしに実装に入らない（承認は plan mode の承認または明示的な「OK」。曖昧な相槌を承認と見なさない）
- CLAUDE.md に規約がなければ `/orchestra:flow-init` を促す
