#!/bin/bash

# Claude Code設定セットアップスクリプト
# .claudeディレクトリに設定ファイルをコピーします

set -e

echo "🚀 Claude Code設定のセットアップを開始します..."
echo ""

# mise のインストール確認
echo "🔧 mise のインストールを確認しています..."
if command -v mise &> /dev/null; then
    echo "  ✅ mise は既にインストールされています ($(mise --version))"
else
    echo "  ⚠️ mise がインストールされていません"
    if command -v brew &> /dev/null; then
        echo "  📦 Homebrew を使用して mise をインストールします..."
        brew install mise
        echo "  ✅ mise のインストールが完了しました"
        echo ""
        echo "  💡 シェルにmiseを有効化するには以下を~/.zshrcに追加してください:"
        echo '     eval "$(mise activate zsh)"'
    else
        echo "  ❌ Homebrew がインストールされていません"
        echo "  💡 Homebrew をインストール後、以下を実行してください:"
        echo "     brew install mise"
    fi
fi
echo ""

# GitHub CLI (gh) のインストール確認
echo "🔧 GitHub CLI (gh) のインストールを確認しています..."
if command -v gh &> /dev/null; then
    echo "  ✅ GitHub CLI は既にインストールされています ($(gh --version | head -n 1))"
else
    echo "  ⚠️ GitHub CLI がインストールされていません"
    if command -v brew &> /dev/null; then
        echo "  📦 Homebrew を使用して GitHub CLI をインストールします..."
        brew install gh
        echo "  ✅ GitHub CLI のインストールが完了しました"
        echo ""
        echo "  💡 GitHub認証を設定するには以下を実行してください:"
        echo "     gh auth login"
    else
        echo "  ❌ Homebrew がインストールされていません"
        echo "  💡 Homebrew をインストール後、以下を実行してください:"
        echo "     brew install gh"
        echo "     gh auth login"
    fi
fi
echo ""

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"

# ソースディレクトリの定義
CLAUDE_SOURCE_DIR="${SCRIPT_DIR}/claude"
CLAUDE_CONFIG_DIR="${CLAUDE_SOURCE_DIR}/config"
CLAUDE_AGENTS_DIR="${CLAUDE_SOURCE_DIR}/agents"
CLAUDE_SKILLS_DIR="${CLAUDE_SOURCE_DIR}/skills"
CLAUDE_COMMANDS_DIR="${CLAUDE_SOURCE_DIR}/commands"

# .claudeディレクトリの存在確認と作成
if [ ! -d "${CLAUDE_HOME}" ]; then
    echo "📁 .claudeディレクトリを作成します..."
    mkdir -p "${CLAUDE_HOME}"
else
    echo "✅ .claudeディレクトリが既に存在します"
fi

# 必要なサブディレクトリの作成
mkdir -p "${CLAUDE_HOME}/agents"
mkdir -p "${CLAUDE_HOME}/skills"
mkdir -p "${CLAUDE_HOME}/commands"

# コピー成功カウンター
copied_files=0
copied_dirs=0

# 設定ファイル（.md）のコピー
if [ -d "${CLAUDE_CONFIG_DIR}" ]; then
    echo ""
    echo "📝 設定ファイルをコピーしています..."
    for file in "${CLAUDE_CONFIG_DIR}"/*.md; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            cp "$file" "${CLAUDE_HOME}/${filename}"
            echo "  ✅ ${filename}"
            ((copied_files++))
        fi
    done
fi

# settings.jsonのコピー
if [ -f "${CLAUDE_SOURCE_DIR}/settings.json" ]; then
    echo ""
    echo "⚙️ settings.jsonをコピーしています..."
    cp "${CLAUDE_SOURCE_DIR}/settings.json" "${CLAUDE_HOME}/settings.json"
    echo "  ✅ settings.json"
    ((copied_files++))
fi

# エージェント設定のコピー
if [ -d "${CLAUDE_AGENTS_DIR}" ]; then
    echo ""
    echo "🤖 エージェント設定をコピーしています..."
    cp -r "${CLAUDE_AGENTS_DIR}"/* "${CLAUDE_HOME}/agents/" 2>/dev/null || true
    agent_count=$(ls -1 "${CLAUDE_AGENTS_DIR}"/*.md 2>/dev/null | wc -l)
    echo "  ✅ ${agent_count}個のエージェント設定"
    ((copied_files+=agent_count))
fi

# スキル設定のコピー
if [ -d "${CLAUDE_SKILLS_DIR}" ]; then
    echo ""
    echo "🎯 スキル設定をコピーしています..."
    cp -r "${CLAUDE_SKILLS_DIR}"/* "${CLAUDE_HOME}/skills/" 2>/dev/null || true
    skill_count=$(find "${CLAUDE_SKILLS_DIR}" -type d -mindepth 1 -maxdepth 1 | wc -l)
    echo "  ✅ ${skill_count}個のスキル"
    ((copied_dirs+=skill_count))
fi

# コマンド設定のコピー
if [ -d "${CLAUDE_COMMANDS_DIR}" ]; then
    echo ""
    echo "🎮 コマンド設定をコピーしています..."
    cp -r "${CLAUDE_COMMANDS_DIR}"/* "${CLAUDE_HOME}/commands/" 2>/dev/null || true
    command_count=$(find "${CLAUDE_COMMANDS_DIR}" -type f 2>/dev/null | wc -l)
    echo "  ✅ ${command_count}個のコマンド"
    ((copied_files+=command_count))
fi

# 結果表示
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 セットアップが完了しました！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 ${copied_files}個のファイルをインストールしました："
echo ""

# インストールされたファイルをリスト表示
for file in "${CLAUDE_HOME}"/*.md "${CLAUDE_HOME}/settings.json"; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        # ファイルサイズも表示
        size=$(ls -lh "$file" | awk '{print $5}')
        echo "  • ${filename} (${size})"
    fi
done

echo ""
echo "💡 Claude Codeを再起動すると設定が反映されます"
echo ""