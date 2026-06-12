#!/usr/bin/env python3
"""
PreToolUse hook: Worktree実装エージェント起動前に開発フロー遵守を強制する。

Worktreeエージェント起動 = 実装の委譲。
要件定義（AC）→ ユーザー承認 → 永続化 が済んでいなければブロックする。
このフローで唯一のブロッキングフック（他は提案のみ）。

フラグはセッションIDごとに分離し、並行セッション間の競合を防ぐ。

フロー:
  1. Worktree Agent起動 → フラグなし → exit 2 でブロック（チェックリスト提示）
  2. Claude: 開発フロー全工程を実施（要件定義→計画→ユーザー承認→書き戻し）
  3. Claude: フラグ作成（bash: touch /tmp/claude-worktree-approved-{session_id}）
  4. Worktree Agent再起動 → フラグあり → 許可（フラグ削除、1回使い捨て）
"""

import json
import os
import sys

GATE_FILE_PREFIX = "/tmp/claude-worktree-approved-"


def main():
    try:
        data = json.load(sys.stdin)
        tool_name = data.get("tool_name", "")
        tool_input = data.get("tool_input", {})
        session_id = data.get("session_id", "unknown")

        # サブエージェントツール以外はスルー（旧名: Task / 新名: Agent）
        if tool_name not in ("Task", "Agent"):
            sys.exit(0)

        # worktree分離でない場合はスルー（リサーチ等のサブエージェントは許可）
        isolation = tool_input.get("isolation", "")
        if isolation != "worktree":
            sys.exit(0)

        # セッション固有のフラグファイルをチェック
        gate_file = f"{GATE_FILE_PREFIX}{session_id}"

        # フラグファイルが存在すれば許可（1回使い捨て）
        if os.path.exists(gate_file):
            os.remove(gate_file)
            sys.exit(0)

        # フラグなし → ブロック（開発フロー全体のチェックリストを提示）
        description = tool_input.get("description", "unknown task")
        print(
            f"[Workflow Gate] Worktree実装エージェント '{description}' をブロックしました。\n"
            "\n"
            "実装委譲の前に、開発フローを遵守してください:\n"
            "\n"
            "□ タスク確認\n"
            "  - タスク管理ツール上のタスク/Issueと既存のタスクファイルを確認したか？\n"
            "\n"
            "□ 要件定義\n"
            "  - 受け入れ条件（AC）・非ゴール・検証方法を文書化したか？\n"
            "  - 「このACが全て満たされたら完了」をユーザーに確認したか？\n"
            "\n"
            "□ 設計判断\n"
            "  - 変更対象の既存コードを読んで理解したか？\n"
            "  - 複数アプローチがある場合、Codexに相談したか？\n"
            "\n"
            "□ ユーザー承認\n"
            "  - 実装計画を提示し、明示的な承認を得たか？\n"
            "\n"
            "□ 永続化\n"
            "  - 要件+承認済み計画をタスクファイル（または docs/plans/）に書き込んだか？\n"
            "\n"
            f"全て完了後: touch {gate_file} を実行してから再試行してください。",
            file=sys.stderr,
        )
        sys.exit(2)

    except Exception as e:
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()
