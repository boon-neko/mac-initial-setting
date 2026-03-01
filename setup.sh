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
    echo "  3) Mac ディスプレイ解像度設定 ← 1800x1169 に変更"
    echo "  4) VS Code セットアップ    ← 設定・拡張機能の一括インストール"
    echo "  5) すべてインストール"
    echo "  q) 終了"
    echo ""
    echo "  ※ VS Code は事前にインストールが必要です"
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

# VS Code セットアップ
setup_vscode() {
    local VSCODE_SCRIPT="${SCRIPT_DIR}/vscode/setup-vscode.sh"

    if [ ! -f "$VSCODE_SCRIPT" ]; then
        echo "  ❌ vscode/setup-vscode.sh が見つかりません"
        return 1
    fi

    bash "$VSCODE_SCRIPT"
}

# Mac ディスプレイ解像度設定
setup_display() {
    echo ""
    echo "🖥️  Mac ディスプレイ解像度を 1800x1169 に設定します..."
    echo ""

    # displayplacer のインストール確認
    if ! command -v displayplacer &> /dev/null; then
        echo "  ⚠️  displayplacer がインストールされていません"
        if command -v brew &> /dev/null; then
            read -p "  📦 Homebrew を使用してインストールしますか？ [Y/n]: " install_choice
            if [[ ! "$install_choice" =~ ^[Nn]$ ]]; then
                brew tap jakehilborn/jakehilborn
                brew install displayplacer
                echo "  ✅ displayplacer のインストールが完了しました"
            else
                echo "  ❌ displayplacer が必要です。手動でインストールしてください:"
                echo "     brew tap jakehilborn/jakehilborn && brew install displayplacer"
                return 1
            fi
        else
            echo "  ❌ Homebrew がインストールされていません"
            echo "  💡 Homebrew をインストール後、以下を実行してください:"
            echo "     brew tap jakehilborn/jakehilborn && brew install displayplacer"
            return 1
        fi
    fi

    # 現在の解像度を表示
    echo "  📋 現在のディスプレイ設定:"
    displayplacer list | grep "Resolution:" | head -1
    echo ""

    # メインディスプレイのIDを取得
    local display_id
    display_id=$(displayplacer list | grep "Persistent screen id:" | head -1 | awk '{print $NF}')

    if [ -z "$display_id" ]; then
        echo "  ❌ ディスプレイIDを取得できませんでした"
        return 1
    fi

    # 解像度を設定
    displayplacer "id:${display_id} res:1800x1169 scaling:on"
    echo ""
    echo "  ✅ ディスプレイ解像度を 1800x1169 に設定しました"
}

# メインループ
while true; do
    show_menu
    read -p "  選択してください [1-5/q]: " choice

    case "$choice" in
        1)
            setup_claude
            ;;
        2)
            setup_orchestra
            ;;
        3)
            setup_display
            ;;
        4)
            setup_vscode
            ;;
        5)
            setup_claude
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  続いて Orchestra セットアップを実行します"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            setup_orchestra
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  続いてディスプレイ解像度を設定します"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            setup_display
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  続いて VS Code セットアップを実行します"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            setup_vscode
            ;;
        q|Q)
            echo ""
            echo "👋 セットアップを終了します"
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo "⚠️  無効な選択です。1, 2, 3, 4, q のいずれかを入力してください。"
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
