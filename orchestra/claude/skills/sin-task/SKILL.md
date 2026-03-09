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
未定義の場合は先に `/init` を実行してプロジェクト規約を設定する。

CLAUDE.md から以下を読み取る:
- **Task Management**: タスク管理ツール (GitHub Issues / GitLab / Jira / etc.)
- **Task File Location**: タスクファイルの場所 (あれば)
- **Branch Naming**: ブランチ命名規則
- **Main Branch**: メインブランチ名

## 引数

- `$ARGUMENTS`: Issue番号（例: `052`）

## フロー

```
1. CLAUDE.mdからプロジェクト規約を読み取る
2. タスク情報収集
3. /startproject フロー実行（Research → Planning → Codex Review → User Confirmation）
4. ブランチ作成
5. 現セッションで実装開始
6. レビュー → マージ
```

## 手順

### Step 0: プロジェクト規約の読み取り

CLAUDE.md の「Workflow Conventions」セクションを読む。
存在しない場合は「`/init` を先に実行してください」とユーザーに伝えて停止。

以下の変数を取得:
- `TASK_TOOL`: タスク管理ツール
- `TASK_DIR`: タスクファイルの場所（なければ空）
- `BRANCH_PATTERN`: ブランチ命名規則
- `MAIN_BRANCH`: メインブランチ名

### Step 1: タスク情報収集

タスク管理ツールに応じたコマンドでIssue/タスクを確認:
- GitHub Issues: `gh issue view $ARGUMENTS`
- GitLab: `glab issue view $ARGUMENTS`
- その他: ユーザーにタスク内容を確認

タスクファイルがあれば読む（TASK_DIRが定義されている場合）。

タスクファイルの内容はメモ書き程度の場合がある。**既存の内容に関わらず、常にフルリサーチを実施する。**

### Step 2: タスクファイルのステータス更新

タスクファイルがあれば、ステータスを `🔄 進行中` に更新する。

### Step 3: /startproject フロー実行

**タスクファイルの内容に関わらず、以下の全Phaseを実行する。**

- **Phase 1**: Gemini Research（サブエージェント、バックグラウンド）
- **Phase 2**: Requirements & Planning（ユーザーに質問して要件明確化）
- **Phase 2.5**: Data Model Analysis（データモデルが関わる場合のみ）
- **Phase 3**: Codex Design Review（サブエージェント、バックグラウンド）
- **User Confirmation**: 計画をユーザーに提示し、明示的な承認を得る

**Phase 4（Task Creation）と Phase 5（CLAUDE.md Update）はタスクファイルが既に存在するためスキップ可。**

### Step 4: ブランチ作成

ユーザー承認後、BRANCH_PATTERNに従ってブランチを作成:

```bash
git checkout {MAIN_BRANCH}
git pull
git checkout -b {BRANCH_PATTERN に基づくブランチ名}
```

### Step 5: 実装開始

CLAUDE.md の開発ルールに従って実装を進める:
- Understand → Design → Test → Code → Verify
- Commit as you go
- 完了後に Codex Review → Local Verification → Merge

### Step 6: マージ

```bash
git checkout {MAIN_BRANCH}
git merge {ブランチ名}
git push origin {MAIN_BRANCH}
git branch -d {ブランチ名}
```

タスクファイルがあればステータスを `✅ 完了` に更新。

## IMPORTANT

- **このスキルを経由せずにタスク実装を開始しない**
- タスクファイルの内容がどれだけ詳細でも、Phase 1-3は省略しない
- ユーザー承認なしに実装に入らない
- CLAUDE.md に規約がなければ `/init` を促す
