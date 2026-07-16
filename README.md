# mac-initial-setting

新しい Mac（現場導入時）のセットアップ一式。**上から順に実行すれば開発環境が揃う**ことを目的としたリポジトリ。

## リポジトリ構成

| パス | 内容 |
|------|------|
| `setup.sh` | セットアップメニュー（各スクリプトの入口） |
| `setup-claude.sh` | Claude Code グローバル設定を `~/.claude/` にコピー |
| `claude/` | グローバル設定の実体（CLAUDE.md・エージェント・汎用スキル） |
| `vscode/` | VS Code 設定・拡張機能 |
| `zshrc` | zsh 設定 |

**開発フロー plugin（orchestra）は別リポジトリ [boon-neko/ai-driven-skills](https://github.com/boon-neko/ai-driven-skills) に分離した。**
plugin marketplace 登録時にクローンされて導入される（下記 Step 2）。

セットアップの流れ: **① Mac 基本設定 → ② ユーティリティ/開発ツール → ③ Claude Code（グローバル設定 + orchestra plugin）→ ④ 現場プロジェクトごとに `/orchestra:flow-init`**

## mac基本設定
日本語のライブ変換をオフ  
トラックパッド→軌跡の速さを早める、その他のジェスチャでアプリケーション間スワイプを4本指に  
アクセシビリティ→ポインタコントロール→トラックパッドオプション→ドラッグ方法を3本指に  

## zshrcの設定
cp ./zshrc ~/.zshrc  
  
~/Developmentディレクトリを作成

## ユーティリティ系

### Clippy
https://clipy-app.com/

### Alfred
https://www.alfredapp.com/  
起動をcmd+Spaceに

### DisplayLink Manager
https://www.synaptics.com/products/displaylink-graphics/downloads/macos

### Karabinner Elements
https://karabiner-elements.pqrs.org/
https://ke-complex-modifications.pqrs.org/#japanese  
外部キーボード接続中はmacのキーボードをオフに  
Function Keyの設定をデフォルトに
右コマンドキーを英数・かなのトグルに変更する→https://misclog.jp/karabiner-elements/
## 開発系

### Homebrew
https://brew.sh/ja/  
```/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"```

### Intellij
https://account.jetbrains.com/login

### VSCode
https://azure.microsoft.com/ja-jp/products/visual-studio-code

### Docker Desktop
https://docs.docker.jp/desktop/install/mac-install.html

### Postman
https://www.postman.com/

### asdf
https://asdf-vm.com/

### peco & tac
```shell
brew install peco
brew install coreutils
```

### k9s
https://github.com/derailed/k9s

### GitHub CLI (gh)
```shell
brew install gh
gh auth login
```
GitHubの操作をCLIから実行可能（PR作成、Issue管理など）

### Claude Code
```shell
asdf plugin-add nodejs
asdf install nodejs latest
# asdf list all nodejs でバージョン確認も可能

npm install -g @anthropic-ai/claude-code
```
パスを通す
export PATH=$PATH:$(npm prefix --location=global)/bin
.zshrcに追記

#### セットアップ手順（新しい Mac）

**Step 1: グローバル設定**

```shell
# このリポジトリをクローン後
./setup.sh
```

| メニュー | 内容 |
|----------|------|
| **1) Claude Code 基本設定** | `~/.claude/` にグローバル設定（CLAUDE.md・エージェント・汎用スキル）をコピー。mise / gh の導入確認も行う |
| **2) Orchestra セットアップ** | **ai-driven-skills リポジトリを呼び出し時にクローン**し、対象プロジェクトに `.codex/` `.gemini/` `lint-config.json` を配置（plugin を使わない場合は hooks/skills のコピーも） |
| **3) ディスプレイ解像度設定** | 1800x1169 に変更 |
| **4) VS Code セットアップ** | 設定・拡張機能の一括インストール |
| **5) すべてインストール** | 上記すべて |

**Step 2: orchestra plugin の導入**（開発フロー本体。全プロジェクト共通なので Mac ごとに1回）

plugin は別リポジトリ。marketplace 登録時にクローンされ、更新は `claude plugin update orchestra` で取り込む:

```shell
claude plugin marketplace add boon-neko/ai-driven-skills   # ローカルクローンのパス指定でも可
claude plugin install orchestra@ai-driven-skills
# Claude Code を再起動して反映
```

**Step 3: Codex / Gemini CLI**（レビュー係・リサーチ係。使う現場のみ）

```shell
npm install -g @openai/codex @google/gemini-cli
codex login
gemini login
```

Codex CLI が使えない現場では、レビュアーを Claude サブエージェントに切り替えられる（`/orchestra:flow-init` で選択）。

**Step 4: 現場プロジェクトごとの初期化**（プロジェクトごとに1回）

```shell
cd /path/to/project
claude
```

セッション内で `/orchestra:flow-init` を実行（メニューでは `flow-init` を選択）。
タスク管理ツール・ブランチ規則・マージ方式（PR or ローカルマージ）・レビュアーを質問して
CLAUDE.md の Workflow Conventions に書き込む。**以降のフロースキルは全てこれを読んで動く。**

`.codex/` `.gemini/` 設定が必要なら `./setup.sh` のメニュー 2（Orchestra セットアップ。
ai-driven-skills を呼び出し時にクローンして実行）を使う。

## Claude Code Orchestra（開発フロー plugin・別リポジトリ）

AC駆動の開発フロー — **設計ステージ（要件定義 → ドメイン知識 → 情報収集 → 正常系/異常系の動作洗い出し →
システム構成・データ管理 → 設計レビュー）→ 計画 → 実装 → AC毎の要件適合レビュー → AC検証表で完了報告** — と、
Codex CLI（レビュー）/ Gemini CLI（リサーチ）の協調をまとめた plugin。
日常の入口は `/orchestra:sin-task {issue番号}`（単体）/ `/orchestra:para-task {issue番号}`（並行）、
設計だけ回すなら `/orchestra:design {feature}`。

| カテゴリ | 内容 |
|----------|------|
| **設計ステージ Skills (8)** | design（一括ラッパー）/ design-core（共通基盤）/ requirements / domain-knowledge / info-gathering / behavior-analysis / system-design / design-review |
| **フロー・その他 Skills (15)** | flow-init / startproject / sin-task / para-task / plan / retro / research / research-lib / codex-system / gemini-system / parallel-workflow / subagent-driven-development / lang-go / lang-python / lang-typescript |
| **Hooks (10)** | 入口ゲート（承認なしの実装委譲をブロック）+ 出口ゲート（AC検証表のない完了宣言を差し戻し）+ 提案系8本 |
| **Agents** | general-purpose（Codex/Gemini を直接呼べる委譲用サブエージェント） |

**スキル一覧・hooks・Model Policy・`/goal` 併用などの詳細は
[boon-neko/ai-driven-skills](https://github.com/boon-neko/ai-driven-skills) の README を参照**
（フローの全体像はそちらだけで分かるようにしてある）。
