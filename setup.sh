#!/bin/bash

# メインセットアップスクリプト
# Claude Code 基本設定と Orchestra 環境をメニューから選択してインストール

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# メニュー表示
show_menu() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Mac Initial Setting - セットアップメニュー"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  1) Claude Code 基本設定   ← ~/.claude/ にグローバル設定"
    echo "  2) Orchestra セットアップ  ← 対象プロジェクトに Orchestra 環境"
    echo "  3) すべてインストール"
    echo "  q) 終了"
    echo ""
}

# Claude Code 基本設定
setup_claude() {
    echo ""
    echo "🚀 Claude Code 基本設定を開始します..."
    echo ""
    bash "${SCRIPT_DIR}/setup-claude.sh"
}

# Orchestra セットアップ
setup_orchestra() {
    local ORCHESTRA_SCRIPT="${SCRIPT_DIR}/orchestra/setup-orchestra.sh"

    if [ ! -f "$ORCHESTRA_SCRIPT" ]; then
        echo "  ❌ orchestra/setup-orchestra.sh が見つかりません"
        return 1
    fi

    echo ""
    read -p "📂 対象プロジェクトのパスを入力してください（デフォルト: カレントディレクトリ）: " orchestra_target
    orchestra_target="${orchestra_target:-.}"

    # パスの存在確認
    if [ ! -d "$orchestra_target" ]; then
        echo "  ❌ ディレクトリが見つかりません: $orchestra_target"
        return 1
    fi

    echo ""
    bash "$ORCHESTRA_SCRIPT" "$orchestra_target"
}

# メインループ
while true; do
    show_menu
    read -p "  選択してください [1-3/q]: " choice

    case "$choice" in
        1)
            setup_claude
            ;;
        2)
            setup_orchestra
            ;;
        3)
            setup_claude
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  続いて Orchestra セットアップを実行します"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            setup_orchestra
            ;;
        q|Q)
            echo ""
            echo "👋 セットアップを終了します"
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo "⚠️  無効な選択です。1, 2, 3, q のいずれかを入力してください。"
            ;;
    esac

    echo ""
    read -p "🔄 メニューに戻りますか？ [Y/n]: " continue_choice
    if [[ "$continue_choice" =~ ^[Nn]$ ]]; then
        echo ""
        echo "👋 セットアップを終了します"
        echo ""
        exit 0
    fi
done
