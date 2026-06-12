---
name: para-task
description: |
  並行セッション（Worktree）でタスクを実行する。startprojectフローを経てからWorktreeエージェントに委譲する。
  /para-task {issue番号} で起動。
metadata:
  short-description: 並行タスク開始（startproject + Worktree）
---

# /para-task {issue番号}

**並行セッション（Worktree）でタスクを実行する。必ずstartprojectフローを経由する。**

## Prerequisites

CLAUDE.md にプロジェクトのワークフロー規約が定義されていること。
未定義の場合は先に `/orchestra:flow-init` を実行してプロジェクト規約を設定する。

CLAUDE.md から以下を読み取る:
- **Task Management**: タスク管理ツール
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
2. タスク情報収集
3. /startproject フロー実行（Research → Requirements(AC) → Codex Review → User Confirmation）
4. 要件+承認済み計画をタスクファイルに書き戻す
5. ブランチ作成・プッシュ
6. Worktreeエージェントに実装委譲（AC・計画をpromptに含める）
7. 結果報告（AC検証表）→ ユーザー承認後にmerge
```

## 手順

### Step 0: プロジェクト規約の読み取り

CLAUDE.md の「Workflow Conventions」セクションを読む。
存在しない場合は「`/orchestra:flow-init` を先に実行してください」とユーザーに伝えて停止。

### Step 1: タスク情報収集

タスク管理ツールに応じてIssue/タスクを取得（GitHub: `gh issue view` / GitLab: `glab issue view` /
Jira・Linear 等: 接続済み MCP サーバーで取得、なければユーザーに貼り付けを依頼）。
タスクファイルがあれば読む。

タスクファイルの内容はメモ書き程度の場合がある。**既存の内容に関わらず、常にフルリサーチを実施する。**

### Step 2: タスクファイルのステータス更新

タスクファイルがあれば、ステータスを `🔄 進行中` に更新する。

### Step 3: /startproject フロー実行

**タスクファイルの内容に関わらず、以下の全Phaseを実行する。**

- **Phase 1**: Gemini Research（サブエージェント、バックグラウンド）
- **Phase 2**: Requirements Definition（`requirements` スキルで AC・非ゴール・検証方法を文書化し、「このACで完了か」をユーザーに確認）
- **Phase 2.5**: Data Model Analysis（データモデルが関わる場合のみ）
- **Phase 3**: Requirements & Plan Review（Codex: 要件の曖昧さ + 計画のAC網羅性）
- **User Confirmation**: AC と計画をユーザーに提示し、明示的な承認を得る
- **Phase 5 (Persist・省略不可)**: 承認後、要件定義と承認済み計画をタスクファイルに書き戻す
  （Worktreeエージェントと最終レビューはこのファイルを参照する）

### Step 4: ブランチ作成・プッシュ

ユーザー承認後:

```bash
git checkout {MAIN_BRANCH}
git pull
git checkout -b {BRANCH_PATTERN に基づくブランチ名}
git push -u origin {ブランチ名}
git checkout {MAIN_BRANCH}  # メインはメインブランチに戻る
```

### Step 5: Worktreeエージェントに実装委譲

委譲前に、ユーザーに `/goal` の設定を提案する（例: `/goal {タスク番号} の全ACが PASS の検証結果表付きで報告され、ユーザー承認後にマージまたはPR作成が完了する`）。

`/parallel-workflow` スキルの手順に従い、Agent(isolation: "worktree") を起動する。

**ワークフローゲートについて**: Worktreeエージェントの初回起動は
`require-plan-before-worktree.py` フックにブロックされ、チェックリストとフラグファイルの
パスが提示される。チェックリスト（要件定義・承認・永続化）が完了済みであることを確認し、
提示されたフラグを `touch` してから再試行する。**チェックリストが未完了のままフラグを
立てない。**

promptに以下を必ず含める:
- 「まず git checkout {ブランチ名} してから作業開始」
- 要件定義（AC・非ゴール・検証方法）の全文
- 実装計画（Step 3で承認済みの内容）
- テスト要件（ACに対応するテストを書くこと）
- Codexレビュー実施の指示（要件適合形式: AC毎に PASS/FAIL + スコープ外変更チェック）
- コミット・プッシュの指示

### Step 6: 結果報告・マージ

Worktreeエージェント完了後:
1. 実装結果をユーザーに報告（**ACごとの検証結果表**、diffサマリ、テスト結果）
2. ユーザーの承認を得る
3. MERGE_METHOD に従いマージ:

**local-merge の場合:**

```bash
git checkout {MAIN_BRANCH}
git merge {ブランチ名}
git push origin {MAIN_BRANCH}
git branch -d {ブランチ名}
git push origin --delete {ブランチ名}
```

**pull-request の場合**（ブランチは Step 4 で push 済み）:

```bash
gh pr create --title "{タイトル}" --body "{本文}"   # GitLab なら glab mr create
```

- PR本文に**ACごとの検証結果表**を含める
- 自分でマージしない — レビュー承認後のマージは現場のルールに従う

4. タスクファイルがあればステータスを更新（local-merge: `✅ 完了` / pull-request: `👀 レビュー待ち`）

## IMPORTANT

- **このスキルを経由せずに並行タスク実装を開始しない**
- タスクファイルの内容がどれだけ詳細でも、Phase 1-3は省略しない
- ユーザー承認なしにWorktreeエージェントを起動しない
- Worktreeエージェントのpromptには要件定義（AC）と承認済みの実装計画を必ず含める
- 完了報告はACごとの検証結果表で行う
- CLAUDE.md に規約がなければ `/orchestra:flow-init` を促す
