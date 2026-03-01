#!/bin/bash

# VS Code セットアップスクリプト
# settings.json のコピーと拡張機能の一括インストール

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"

echo ""
echo "🔧 VS Code セットアップを開始します..."
echo ""

# VS Code のインストール確認
VSCODE_BIN=""
if command -v code &> /dev/null; then
    VSCODE_BIN="code"
elif [ -f "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
    VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
else
    echo "  ❌ VS Code がインストールされていません"
    echo "  💡 https://code.visualstudio.com/ からインストールしてください"
    exit 1
fi

echo "  ✅ VS Code を検出: $("$VSCODE_BIN" --version | head -1)"
echo ""

# settings.json のコピー
echo "  📋 settings.json をコピーしています..."
mkdir -p "$VSCODE_SETTINGS_DIR"

if [ -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
    echo "  ⚠️  既存の settings.json が見つかりました"
    read -p "  上書きしますか？ [y/N]: " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "  ⏭️  settings.json のコピーをスキップしました"
    else
        cp "$SCRIPT_DIR/settings.json" "$VSCODE_SETTINGS_DIR/settings.json"
        echo "  ✅ settings.json をコピーしました"
    fi
else
    cp "$SCRIPT_DIR/settings.json" "$VSCODE_SETTINGS_DIR/settings.json"
    echo "  ✅ settings.json をコピーしました"
fi

echo ""

# Claude Code バイナリパスの自動検出・設定
CLAUDE_BIN=$(which claude 2>/dev/null || true)
if [ -n "$CLAUDE_BIN" ]; then
    # シンボリックリンクの場合は実体パスを解決
    CLAUDE_BIN=$(readlink -f "$CLAUDE_BIN" 2>/dev/null || realpath "$CLAUDE_BIN" 2>/dev/null || echo "$CLAUDE_BIN")

    # settings.json に claudeBinaryPath を書き込み（プレースホルダーがなければ追加）
    if command -v python3 &> /dev/null; then
        python3 -c "
import json
path = '$VSCODE_SETTINGS_DIR/settings.json'
with open(path) as f:
    # コメント行を除去してJSONパース
    lines = [l for l in f.readlines() if not l.strip().startswith('//')]
    data = json.loads(''.join(lines))
data['claudeCode.claudeBinaryPath'] = '$CLAUDE_BIN'
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
        echo "  ✅ Claude Code バイナリパスを設定: $CLAUDE_BIN"
    fi
else
    echo "  ⚠️  claude コマンドが見つかりません（後で手動設定が必要です）"
fi

echo ""

# 拡張機能のインストール
echo "  📦 拡張機能をインストールしています..."
echo ""

installed=0
failed=0

while IFS= read -r ext; do
    # コメント行と空行をスキップ
    ext=$(echo "$ext" | xargs)
    [[ -z "$ext" || "$ext" == \#* ]] && continue

    if "$VSCODE_BIN" --install-extension "$ext" --force 2>&1 | grep -q "was successfully installed"; then
        echo "  ✅ $ext"
        ((installed++))
    else
        echo "  ❌ $ext (インストール失敗)"
        ((failed++))
    fi
done < "$SCRIPT_DIR/extensions.txt"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  VS Code セットアップ完了"
echo "  ✅ インストール成功: ${installed}"
[ "$failed" -gt 0 ] && echo "  ❌ インストール失敗: ${failed}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
