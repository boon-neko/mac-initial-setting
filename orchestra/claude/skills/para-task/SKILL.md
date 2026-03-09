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
未定義の場合は先に `/init` を実行してプロジェクト規約を設定する。

CLAUDE.md から以下を読み取る:
- **Task Management**: タスク管理ツール
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
4. ブランチ作成・プッシュ
5. Worktreeエージェントに実装委譲
6. 結果報告 → ユーザー承認後にmerge
```

## 手順

### Step 0: プロジェクト規約の読み取り

CLAUDE.md の「Workflow Conventions」セクションを読む。
存在しない場合は「`/init` を先に実行してください」とユーザーに伝えて停止。

### Step 1: タスク情報収集

タスク管理ツールに応じたコマンドでIssue/タスクを確認。
タスクファイルがあれば読む。

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

`/parallel-workflow` スキルの手順に従い、Agent(isolation: "worktree") を起動する。

promptに以下を必ず含める:
- 「まず git checkout {ブランチ名} してから作業開始」
- 実装計画（Step 3で承認済みの内容）
- テスト要件
- Codexレビュー実施の指示
- コミット・プッシュの指示

### Step 6: 結果報告・マージ

Worktreeエージェント完了後:
1. 実装結果をユーザーに報告（diffサマリ、テスト結果）
2. ユーザーの承認を得る
3. メインブランチにマージ:

```bash
git checkout {MAIN_BRANCH}
git merge {ブランチ名}
git push origin {MAIN_BRANCH}
git branch -d {ブランチ名}
git push origin --delete {ブランチ名}
```

4. タスクファイルがあればステータスを `✅ 完了` に更新

## IMPORTANT

- **このスキルを経由せずに並行タスク実装を開始しない**
- タスクファイルの内容がどれだけ詳細でも、Phase 1-3は省略しない
- ユーザー承認なしにWorktreeエージェントを起動しない
- Worktreeエージェントのpromptには承認済みの実装計画を必ず含める
- CLAUDE.md に規約がなければ `/init` を促す
