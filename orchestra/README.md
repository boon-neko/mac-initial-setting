# Claude Code Orchestra

マルチエージェント協調環境のテンプレート。Claude Code、Codex CLI、Gemini CLI を連携させて効率的な開発を実現します。

## 概要

Orchestra は以下の3つの AI を役割分担させるフレームワークです：

| Agent | 役割 | 得意分野 |
|-------|------|---------|
| **Claude Code** | オーケストレーター | ファイル編集、コマンド実行、Git 操作 |
| **Codex CLI** | 深い推論 | 設計決定、デバッグ、トレードオフ分析 |
| **Gemini CLI** | リサーチ | ドキュメント調査、コードベース分析、マルチモーダル |

```
┌─────────────────────────────────────────────────────────────┐
│                      Claude Code                             │
│                    (Orchestrator)                           │
│                                                             │
│  ┌──────────────────┐        ┌──────────────────┐          │
│  │   Codex CLI      │        │   Gemini CLI     │          │
│  │  (Deep Reason)   │        │   (Research)     │          │
│  │                  │        │                  │          │
│  │  • 設計決定      │        │  • ドキュメント調査│          │
│  │  • デバッグ分析   │        │  • コードベース分析│          │
│  │  • トレードオフ   │        │  • PDF/動画/音声  │          │
│  └──────────────────┘        └──────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

## 前提条件

### CLI ツールのインストール

```bash
# Codex CLI
npm install -g @openai/codex
codex login

# Gemini CLI
npm install -g @google/gemini-cli
gemini login
```

### 必須ツール

- `jq` - JSON マージ用（Homebrew: `brew install jq`）

## プロジェクトへの導入

### 方法A: Claude Code Plugin（推奨）

orchestra は Claude Code plugin になっており、コピーせずに導入できる（**乖離が起きない**）:

```bash
# marketplace を登録（ローカルパス or GitHub repo）
claude plugin marketplace add /path/to/mac-initial-setting
# または: claude plugin marketplace add your-username/mac-initial-setting

# インストール（--scope user: 全プロジェクト / --scope project: このプロジェクトのみ）
claude plugin install orchestra@mac-initial-setting
```

- skills は `/orchestra:sin-task` のように **plugin 名の名前空間付き**で呼び出す
- hooks は plugin が自動で有効化する（settings.json へのマージ不要）
- 改善はこのリポジトリに push → 各現場で `claude plugin update orchestra` で反映
- `.codex/` `.gemini/` 設定と `lint-config.json` は plugin に含まれないため、
  必要なら `setup-orchestra.sh` で別途配布する（hooks/skills のコピーはスキップしてよい）
- 導入後、プロジェクトの規約設定として `/init` を実行する

### 方法B: コピー方式（plugin を使わない場合）

```bash
# mac-initial-setting リポジトリをクローン
git clone https://github.com/your-username/mac-initial-setting.git

# 対象プロジェクトのルートで実行
/path/to/mac-initial-setting/orchestra/setup-orchestra.sh .
```

スクリプトは以下を行います：

1. `.claude/hooks/` に 9 つのフックスクリプトをコピー
2. `.claude/rules/` にデリゲーションルールをコピー
3. `.claude/docs/research/` と `.claude/logs/` を作成
4. `.claude/lint-config.json` をコピー
5. `.codex/` にCodex設定をコピー
6. `.gemini/` にGemini設定をコピー
7. `.claude/settings.json` に hooks をマージ

## ディレクトリ構造

セットアップ後のプロジェクト構造：

```
your-project/
├── .claude/
│   ├── settings.json          # hooks設定
│   ├── lint-config.json       # linter設定
│   ├── hooks/
│   │   ├── agent-router.py
│   │   ├── check-codex-before-write.py
│   │   ├── suggest-gemini-research.py
│   │   ├── check-codex-after-plan.py
│   │   ├── require-plan-before-worktree.py
│   │   ├── post-implementation-review.py
│   │   ├── post-test-analysis.py
│   │   ├── lint-on-save.py
│   │   └── log-cli-tools.py
│   ├── rules/
│   │   ├── codex-delegation.md
│   │   └── gemini-delegation.md
│   ├── docs/
│   │   └── research/          # Geminiリサーチ結果
│   └── logs/
│       └── cli-tools.jsonl    # CLI呼び出しログ
├── .codex/
│   ├── config.toml
│   ├── AGENTS.md
│   └── skills/context-loader/
└── .gemini/
    ├── settings.json
    ├── GEMINI.md
    └── skills/context-loader/
```

## Hooks

| Hook | Trigger | 動作 |
|------|---------|------|
| agent-router.py | UserPromptSubmit | ユーザー入力を分析してCodex/Geminiを提案（セッション毎・エージェント毎に1回） |
| check-codex-before-write.py | PreToolUse (Edit/Write) | 設計的な変更前にCodex相談を提案（セッション毎に最大3回） |
| suggest-gemini-research.py | PreToolUse (WebSearch/Fetch) | リサーチ系タスクでGeminiを提案 |
| check-codex-after-plan.py | PostToolUse (Task/Agent) | 計画完了後にCodexレビューを提案（セッション毎に1回） |
| require-plan-before-worktree.py | PreToolUse (Task/Agent) | **唯一のブロッキングフック**: 要件定義(AC)+ユーザー承認なしのWorktree実装委譲を exit 2 でブロック |
| post-implementation-review.py | PostToolUse (Edit/Write) | 大規模実装後にレビューを提案（セッションID毎にステート分離） |
| post-test-analysis.py | PostToolUse (Bash) | テスト失敗時にCodexデバッグを提案 |
| lint-on-save.py | PostToolUse (Edit/Write) | ファイル保存時にlinterを実行 |
| log-cli-tools.py | PostToolUse (Bash) | Codex/Gemini呼び出しをログ記録 |

## Skills 一覧

plugin 導入時は `/orchestra:` プレフィックスで呼び出す（コピー方式なら `/` のみ）。
「自動」は該当する作業を検知すると Claude が自動で読み込むもの。

### 開発フロー

| Skill | 説明 | 呼び方 |
|-------|------|--------|
| `requirements` | 要件定義書（AC・非ゴール・検証方法）を作成し「このACで完了か」の承認まで取る。フォーマットの正 | 手動 / startproject Phase 2 から |
| `startproject` | 新機能開始の全フロー: Research → 要件定義 → 要件+計画レビュー → タスク化 → 永続化。実装後の要件適合レビュー（AC毎 PASS/FAIL）と完了報告形式もここで定義 | 手動 / sin-task・para-task から |
| `sin-task` | タスク番号を指定した単体セッション実行の入口。S/M/L 規模トリアージ → startproject フロー → 実装 → レビュー → マージ | `/orchestra:sin-task 052` |
| `para-task` | Worktree 並行実装版。承認済みのAC・計画を Worktree エージェントに委譲し、AC検証表で報告 | `/orchestra:para-task 052` |
| `plan` | 実装計画書の単体作成（AC対応・検証計画付き） | 手動 |
| `parallel-workflow` | Worktree + feature ブランチ運用の手順書（マージ方法・クリーンアップ） | para-task が参照 / 自動 |
| `subagent-driven-development` | 計画をサブエージェントに分担実行させ、タスク間でコードレビューを挟む | 自動 |

### AI 委譲

| Skill | 説明 | 呼び方 |
|-------|------|--------|
| `codex-system` | Codex CLI への相談ルールとテンプレ（設計判断・デバッグ・トレードオフ・コードレビュー） | 自動 |
| `gemini-system` | Gemini CLI への委譲ルール（リサーチ・大規模コードベース分析・PDF/動画/音声） | 自動 |
| `research` | 技術調査: WebSearch + Gemini 壁打ち → レポートを research ディレクトリに保存 | `/orchestra:research <トピック>` |
| `research-lib` | ライブラリを調査して `.claude/docs/libraries/` に永続ドキュメント化（以後のセッションが参照） | 手動 |

### 言語別ガイドライン（linter で強制できない設計判断のみ）

| Skill | 説明 | 呼び方 |
|-------|------|--------|
| `lang-go` | インターフェース設計・エラーラップ・並行処理・テーブル駆動テスト・禁止事項 | Go を書くと自動 |
| `lang-python` | uv/ruff ワークフロー・型ヒント必須・pydantic 境界バリデーション・pytest 流儀 | Python を書くと自動 |
| `lang-typescript` | strict 前提・unknown+narrowing・discriminated union・floating promise 禁止 | TS を書くと自動 |

### Agents

| Agent | 説明 |
|-------|------|
| `general-purpose` | Codex/Gemini を直接呼べる汎用サブエージェント。メインのコンテキストを守るため、重い相談・調査はこれ経由で行い要約だけ返す |

## lint-config.json のカスタマイズ

プロジェクトに合わせて `.claude/lint-config.json` を編集：

```json
{
  "linters": {
    ".py": {
      "format": ["uv", "run", "ruff", "format", "{file}"],
      "check": ["uv", "run", "ruff", "check", "--fix", "{file}"],
      "type_check": ["uv", "run", "ty", "check", "{file}"]
    },
    ".ts": {
      "format": ["npx", "prettier", "--write", "{file}"],
      "check": ["npx", "eslint", "--fix", "{file}"]
    }
  }
}
```

## 使い方のヒント

### Codex を使うタイミング

- 「どう設計すべき？」→ Codex
- 「なぜ動かない？」→ Codex
- 「AとBどちらがいい？」→ Codex

### Gemini を使うタイミング

- 「調べて」→ Gemini
- 「ドキュメント確認して」→ Gemini
- 「このPDFを見て」→ Gemini

### サブエージェント経由を推奨

大きな出力が予想される場合は、直接呼び出しではなくサブエージェント経由で：

```
Task tool:
- subagent_type: "general-purpose"
- prompt: "Codex/Gemini に相談して結果をまとめて"
```

## トラブルシューティング

### jq がない場合

```bash
brew install jq
```

### hooks が動かない場合

`.claude/settings.json` の hooks セクションを確認してください。

### linter が見つからない場合

プロジェクトに必要なツールをインストールしてください：
- Python: `uv pip install ruff`
- TypeScript: `npm install -D prettier eslint`

## ライセンス

MIT
