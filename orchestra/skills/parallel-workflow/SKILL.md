---
name: parallel-workflow
description: |
  並行セッション・Worktree実装の手順。複数タスクを同時作業する際に参照。
metadata:
  short-description: 並行セッション・Worktree手順
---

# 並行セッション・Worktree ワークフロー

## Prerequisites

CLAUDE.md の「Workflow Conventions」から以下を読み取ること:
- **Branch Naming**: ブランチ命名規則
- **Main Branch**: メインブランチ名

## サブエージェント実装: Worktree + Feature Branch

サブエージェントに実装を委譲する場合の**必須フロー**:

```bash
# 1. メインがfeature branchを作成（CLAUDE.mdの命名規則に従う）
git checkout -b {ブランチ名}
git push -u origin {ブランチ名}
git checkout {MAIN_BRANCH}

# 2. Agent(isolation: "worktree") を起動
#    promptに以下を必ず含める:
#    「まず git checkout {ブランチ名} してから作業開始」

# 3. サブエージェント内でCodexレビューまで実施

# 4. メインがユーザーに結果報告（スクショ等）

# 5. ユーザーOK後、メインがmerge
git checkout {MAIN_BRANCH}
git merge {ブランチ名}
git push origin {MAIN_BRANCH}
git branch -d {ブランチ名}
git push origin --delete {ブランチ名}
```

**絶対にやらないこと**:
- worktreeからメインブランチにファイルを`cp`してメインブランチに直接コミット
- `worktree-agent-xxx` 自動ブランチ名のまま運用

## 複数セッション同時作業

Worktree を使って並列作業する:

```
Session A: .claude/worktrees/agent-xxx/ → {ブランチA}
Session B: .claude/worktrees/agent-yyy/ → {ブランチB}
Session C: main repo ({MAIN_BRANCH})
```

- 各セッションが独自の worktree で作業 — 干渉なし
- メインリポジトリはメインブランチのまま

**注意**: ワークツリーを使う場合、セッション終了前に必ずクリーンアップすること。
ワークツリー削除後にセッションが残ると、作業ディレクトリが存在せずBashが全滅する。

## Worktree での動作確認

Worktree には仮想環境がフル構築されていないことがある。その場合:

```bash
# メインの仮想環境を直接使い、worktree のソースを参照する
cd /path/to/worktree
/path/to/main-repo/.venv/bin/python -c "# テストスクリプト"
```

**注意**: worktree の `.env` は自動コピーされない。シンボリックリンクで対応:

```bash
ln -s /path/to/main-repo/.env /path/to/worktree/.env
```

## セッション跨ぎのタスク

When a task spans multiple sessions:

1. **Commit and push** before ending a session
2. **Update task file** with current status and next steps (if task files are used)
3. Next session picks up from the branch (worktree or checkout)
