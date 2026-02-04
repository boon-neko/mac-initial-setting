#!/bin/bash
# Orchestra テンプレートを対象プロジェクトにコピー＆マージ

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"

# 対象ディレクトリを絶対パスに変換
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "🎭 Setting up Claude Code Orchestra..."
echo "Target: $TARGET_DIR"
echo ""

# 1. .claude/hooks/ にコピー
echo "📁 Copying hooks..."
mkdir -p "$TARGET_DIR/.claude/hooks"
cp -r "$SCRIPT_DIR/claude/hooks/"* "$TARGET_DIR/.claude/hooks/"
echo "   ✅ Copied 8 hook scripts"

# 2. .claude/rules/ にコピー
echo "📁 Copying delegation rules..."
mkdir -p "$TARGET_DIR/.claude/rules"
cp -r "$SCRIPT_DIR/claude/rules/"* "$TARGET_DIR/.claude/rules/"
echo "   ✅ Copied delegation rules"

# 3. .claude/docs/ と .claude/logs/ 作成
mkdir -p "$TARGET_DIR/.claude/docs/research"
mkdir -p "$TARGET_DIR/.claude/logs"
touch "$TARGET_DIR/.claude/docs/research/.gitkeep"
touch "$TARGET_DIR/.claude/logs/.gitkeep"
echo "   ✅ Created docs/research/ and logs/ directories"

# 4. lint-config.json コピー
cp "$SCRIPT_DIR/lint-config.json" "$TARGET_DIR/.claude/"
echo "   ✅ Copied lint-config.json"

# 5. .codex/ にコピー
echo "📁 Copying Codex configuration..."
mkdir -p "$TARGET_DIR/.codex/skills/context-loader"
cp -r "$SCRIPT_DIR/codex/"* "$TARGET_DIR/.codex/"
echo "   ✅ Copied .codex/"

# 6. .gemini/ にコピー
echo "📁 Copying Gemini configuration..."
mkdir -p "$TARGET_DIR/.gemini/skills/context-loader"
cp -r "$SCRIPT_DIR/gemini/"* "$TARGET_DIR/.gemini/"
echo "   ✅ Copied .gemini/"

# 7. settings.json に hooks をマージ
echo ""
echo "🔧 Merging hooks into settings.json..."

SETTINGS_FILE="$TARGET_DIR/.claude/settings.json"
HOOKS_CONFIG="$SCRIPT_DIR/hooks-config.json"

if [ -f "$SETTINGS_FILE" ]; then
    # 既存の settings.json がある場合はマージ
    if command -v jq &> /dev/null; then
        # バックアップ作成
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

        # hooks をマージ（既存の hooks は上書き）
        jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$HOOKS_CONFIG" > "$SETTINGS_FILE.tmp"
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "   ✅ Merged hooks into existing settings.json"
        echo "   📋 Backup saved: settings.json.backup"
    else
        echo "   ⚠️  jq not found. Please manually merge hooks."
        echo "   📋 Hooks config: $HOOKS_CONFIG"
    fi
else
    # settings.json がない場合は hooks-config.json をコピー
    cp "$HOOKS_CONFIG" "$SETTINGS_FILE"
    echo "   ✅ Created settings.json with hooks"
fi

# 8. .gitignore 追加推奨
echo ""
echo "📝 Recommended .gitignore additions:"
echo "   .claude/logs/"
echo "   .claude/settings.json.backup"

echo ""
echo "✨ Orchestra setup complete!"
echo ""
echo "💡 Next steps:"
echo "   1. Review .claude/settings.json"
echo "   2. Customize .claude/lint-config.json for your project"
echo "   3. Run: codex login && gemini login"
