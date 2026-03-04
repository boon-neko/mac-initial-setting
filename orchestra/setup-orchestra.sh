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

# ── CLI ツールの確認 ──────────────────────────
echo "🔧 Checking Orchestra CLI tools..."
echo ""

# Codex CLI
if command -v codex &> /dev/null; then
    echo "  ✅ Codex CLI: $(codex --version 2>/dev/null || echo 'installed')"
else
    echo "  ⚠️  Codex CLI: not installed"
    echo "     Install: npm install -g @openai/codex"
    echo "     Login:   codex login"
fi

# Gemini CLI
if command -v gemini &> /dev/null; then
    echo "  ✅ Gemini CLI: $(gemini --version 2>/dev/null || echo 'installed')"
else
    echo "  ⚠️  Gemini CLI: not installed"
    echo "     Install: npm install -g @google/gemini-cli"
    echo "     Login:   gemini login"
fi

echo ""

# ── API キー設定 ──────────────────────────────
echo "🔑 Checking API keys..."
GEMINI_ENV="${HOME}/.gemini/.env"

if [ -f "$GEMINI_ENV" ] && grep -q "GEMINI_API_KEY" "$GEMINI_ENV" 2>/dev/null; then
    echo "  ✅ GEMINI_API_KEY is already configured in ~/.gemini/.env"
else
    echo ""
    echo "  Gemini CLI をAPIキー認証で使用すると、データがモデル学習に利用されません。"
    echo "  APIキーは Google AI Studio で発行できます: https://aistudio.google.com/apikey"
    echo ""
    read -p "  🔑 GEMINI_API_KEY を設定しますか？ [Y/n]: " setup_gemini_key
    if [[ ! "$setup_gemini_key" =~ ^[Nn]$ ]]; then
        read -sp "  🔑 GEMINI_API_KEY を入力してください: " gemini_key
        echo ""
        if [ -n "$gemini_key" ]; then
            mkdir -p "${HOME}/.gemini"
            echo "GEMINI_API_KEY=\"${gemini_key}\"" >> "$GEMINI_ENV"
            echo "  ✅ GEMINI_API_KEY を ~/.gemini/.env に追加しました"
        else
            echo "  ⏭️  スキップしました（空の入力）"
        fi
    else
        echo "  ⏭️  スキップしました"
    fi
fi

echo ""

# ── Hooks ──────────────────────────────────
echo "📁 Copying hooks..."
mkdir -p "$TARGET_DIR/.claude/hooks"
cp -r "$SCRIPT_DIR/claude/hooks/"* "$TARGET_DIR/.claude/hooks/"
hook_count=$(find "$SCRIPT_DIR/claude/hooks" -type f | wc -l | tr -d ' ')
echo "   ✅ Copied ${hook_count} hook scripts"

# ── Delegation Rules ───────────────────────
echo "📁 Copying delegation rules..."
mkdir -p "$TARGET_DIR/.claude/rules"
cp -r "$SCRIPT_DIR/claude/rules/"* "$TARGET_DIR/.claude/rules/"
echo "   ✅ Copied delegation rules"

# ── Docs & Logs ────────────────────────────
mkdir -p "$TARGET_DIR/.claude/docs/research"
mkdir -p "$TARGET_DIR/.claude/docs/libraries"
mkdir -p "$TARGET_DIR/.claude/logs"
touch "$TARGET_DIR/.claude/docs/research/.gitkeep"
touch "$TARGET_DIR/.claude/docs/libraries/.gitkeep"
touch "$TARGET_DIR/.claude/logs/.gitkeep"
echo "   ✅ Created docs/ and logs/ directories"

# ── lint-config.json ───────────────────────
cp "$SCRIPT_DIR/lint-config.json" "$TARGET_DIR/.claude/"
echo "   ✅ Copied lint-config.json"

# ── Skills ─────────────────────────────────
echo "📁 Copying skills..."
if [ -d "$SCRIPT_DIR/claude/skills" ]; then
    mkdir -p "$TARGET_DIR/.claude/skills"
    cp -r "$SCRIPT_DIR/claude/skills/"* "$TARGET_DIR/.claude/skills/"
    skill_count=$(find "$SCRIPT_DIR/claude/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
    echo "   ✅ Copied ${skill_count} skills"
fi

# ── Commands ───────────────────────────────
echo "📁 Copying commands..."
if [ -d "$SCRIPT_DIR/claude/commands" ]; then
    mkdir -p "$TARGET_DIR/.claude/commands"
    cp -r "$SCRIPT_DIR/claude/commands/"* "$TARGET_DIR/.claude/commands/"
    command_count=$(find "$SCRIPT_DIR/claude/commands" -type f -name '*.md' | wc -l | tr -d ' ')
    echo "   ✅ Copied ${command_count} commands"
fi

# ── Codex 設定 ─────────────────────────────
echo "📁 Copying Codex configuration..."
mkdir -p "$TARGET_DIR/.codex/skills/context-loader"
cp -r "$SCRIPT_DIR/codex/"* "$TARGET_DIR/.codex/"
echo "   ✅ Copied .codex/"

# ── Gemini 設定 ────────────────────────────
echo "📁 Copying Gemini configuration..."
mkdir -p "$TARGET_DIR/.gemini/skills/context-loader"
cp -r "$SCRIPT_DIR/gemini/"* "$TARGET_DIR/.gemini/"
echo "   ✅ Copied .gemini/"

# ── settings.json に hooks をマージ ────────
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

# ── .gitignore 推奨 ────────────────────────
echo ""
echo "📝 Recommended .gitignore additions:"
echo "   .claude/logs/"
echo "   .claude/settings.json.backup"

echo ""
echo "✨ Orchestra setup complete!"
echo ""
echo "📊 Installed components:"
echo "   • Hooks (agent-router, codex/gemini integration)"
echo "   • Delegation rules (codex-delegation, gemini-delegation)"
echo "   • Skills (startproject, codex-system, gemini-system, research-lib, subagent-driven-development)"
echo "   • Commands (research, sc:spawn, sc:workflow, sc:task, sc:brainstorm)"
echo "   • Codex CLI configuration"
echo "   • Gemini CLI configuration"
echo ""
echo "💡 Next steps:"
echo "   1. Review .claude/settings.json"
echo "   2. Customize .claude/lint-config.json for your project"
echo "   3. Run: codex login && gemini login"
