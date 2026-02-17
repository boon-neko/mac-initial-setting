# mac-initial-setting

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

#### セットアップ
```shell
# このリポジトリをクローン後、以下を実行
./setup.sh
```

メニューから選択してインストールします：

| メニュー | 内容 |
|----------|------|
| **1) Claude Code 基本設定** | `~/.claude/` にグローバル設定（エージェント・スキル・コマンド等）をコピー |
| **2) Orchestra セットアップ** | 対象プロジェクトに Orchestra マルチエージェント環境を構築 |
| **3) すべてインストール** | 上記両方を実行 |

#### 個別実行
```shell
# Claude 基本設定のみ
./setup-claude.sh

# Orchestra を特定プロジェクトに導入
./orchestra/setup-orchestra.sh /path/to/project
```

## Claude Code Orchestra

マルチエージェント協調環境のテンプレート。Claude Code、Codex CLI、Gemini CLI を連携させます。

### 前提条件

```bash
# CLI ツールのインストール
npm install -g @openai/codex @google/gemini-cli

# ログイン
codex login
gemini login
```

### プロジェクトへの導入

```bash
# setup.sh のメニュー「2) Orchestra セットアップ」を選択するか、直接実行：
./orchestra/setup-orchestra.sh /path/to/project
```

### Orchestra で追加されるもの

| カテゴリ | 内容 |
|----------|------|
| **Hooks** | agent-router, codex/gemini 連携フック |
| **Rules** | Codex/Gemini デリゲーションルール |
| **Skills** | startproject, codex-system, gemini-system, research-lib, subagent-driven-development |
| **Commands** | /research, /sc:spawn, /sc:workflow, /sc:task, /sc:brainstorm |
| **CLI設定** | Codex CLI / Gemini CLI の設定 |

詳細は [orchestra/README.md](orchestra/README.md) を参照してください。
