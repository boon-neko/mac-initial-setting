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

#### Claude Code設定のセットアップ
```shell
# このリポジトリをクローン後、以下を実行
./setup-claude.sh
```
このスクリプトは以下を実行します：
- **GitHub CLI (gh) のインストール確認** - 未インストールの場合はHomebrewでインストール
- `claude/`ディレクトリ内の設定を`~/.claude/`にコピー

`claude/`ディレクトリ内の以下の設定が`~/.claude/`にコピーされます：
- `config/` - 基本設定ファイル（ルール、モード、MCP設定など）
- `agents/` - カスタムエージェント設定
- `skills/` - 各種スキル
- `commands/` - カスタムコマンド
