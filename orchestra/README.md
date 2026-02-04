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

```bash
# mac-initial-setting リポジトリをクローン
git clone https://github.com/your-username/mac-initial-setting.git

# 対象プロジェクトのルートで実行
/path/to/mac-initial-setting/orchestra/setup-orchestra.sh .
```

### セットアップ内容

スクリプトは以下を行います：

1. `.claude/hooks/` に 8 つのフックスクリプトをコピー
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
| agent-router.py | UserPromptSubmit | ユーザー入力を分析してCodex/Geminiを提案 |
| check-codex-before-write.py | PreToolUse (Edit/Write) | 設計的な変更前にCodex相談を提案 |
| suggest-gemini-research.py | PreToolUse (WebSearch/Fetch) | リサーチ系タスクでGeminiを提案 |
| check-codex-after-plan.py | PostToolUse (Task) | 計画完了後にCodexレビューを提案 |
| post-implementation-review.py | PostToolUse (Edit/Write) | 大規模実装後にレビューを提案 |
| post-test-analysis.py | PostToolUse (Bash) | テスト失敗時にCodexデバッグを提案 |
| lint-on-save.py | PostToolUse (Edit/Write) | ファイル保存時にlinterを実行 |
| log-cli-tools.py | PostToolUse (Bash) | Codex/Gemini呼び出しをログ記録 |

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
