#!/usr/bin/env python3
"""
Stop hook: 完了宣言にACごとの検証結果表が含まれているかを検査する。

「完了報告はAC検証表で行う」ルールの機械的な担保。
完了を宣言する応答に検証エビデンス（AC表）が無ければ exit 2 で差し戻す。

誤ブロックを避けるため:
- 完了マーカーは「タスク/実装の完了宣言」に限定（単発作業の「〜しました」では発火しない）
- 判定に少しでも失敗したら素通し（exit 0）
- 差し戻しはフラグで1回まで（無限ループ防止）。AC表付きの完了報告が通ると
  フラグを解除し、次のタスクで再び有効になる
"""

import json
import os
import sys

# 差し戻し済みフラグ（セッションIDごと）
GATE_FLAG_PREFIX = "/tmp/claude-completion-gate-blocked-"

# 完了宣言とみなすマーカー（タスクフローの完了宣言に限定）
COMPLETION_MARKERS = [
    "完了報告",
    "実装完了",
    "タスク完了",
    "マージしました",
    "task complete",
    "implementation complete",
]

# 検証エビデンスとみなすマーカー
EVIDENCE_MARKERS = [
    "| ac",
    "ac-1",
    "検証結果",
    "検証表",
]

# transcriptの末尾読み込みサイズ（巨大ファイル対策）
TAIL_BYTES = 200_000


def read_tail_lines(path: str) -> list[str]:
    """ファイル末尾の行を読み込む（先頭の欠け行はJSONパース失敗でスキップされる）."""
    try:
        with open(path, "rb") as f:
            f.seek(0, os.SEEK_END)
            size = f.tell()
            f.seek(max(0, size - TAIL_BYTES))
            return f.read().decode("utf-8", errors="ignore").splitlines()
    except Exception:
        return []


def last_assistant_text(transcript_path: str) -> str:
    """transcript(JSONL)から最後のassistantメッセージのテキストを取得する."""
    for line in reversed(read_tail_lines(transcript_path)):
        try:
            entry = json.loads(line)
        except Exception:
            continue
        if entry.get("type") != "assistant":
            continue
        content = entry.get("message", {}).get("content", "")
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            texts = [
                p.get("text", "")
                for p in content
                if isinstance(p, dict) and p.get("type") == "text"
            ]
            if texts:
                return "\n".join(texts)
        return ""
    return ""


def main():
    try:
        data = json.load(sys.stdin)

        # stop hookによる継続中の再停止はブロックしない（フィールドが存在する場合のみ）
        if data.get("stop_hook_active"):
            sys.exit(0)

        session_id = "".join(
            c for c in str(data.get("session_id", "default")) if c.isalnum() or c in "-_"
        ) or "default"
        gate_flag = f"{GATE_FLAG_PREFIX}{session_id}"

        text = last_assistant_text(data.get("transcript_path", ""))
        if not text:
            sys.exit(0)

        lower = text.lower()

        if not any(m.lower() in lower for m in COMPLETION_MARKERS):
            sys.exit(0)

        if any(m in lower for m in EVIDENCE_MARKERS):
            # AC表付きの完了報告が通った → フラグを解除して次のタスクに備える
            if os.path.exists(gate_flag):
                os.remove(gate_flag)
            sys.exit(0)

        # 既にこのセッションで差し戻し済みならブロックしない（無限ループ防止）
        if os.path.exists(gate_flag):
            sys.exit(0)
        with open(gate_flag, "w") as f:
            f.write("1")

        print(
            "[Completion Gate] 完了宣言にACごとの検証結果表が含まれていません。\n"
            "\n"
            "完了報告には以下を含めてください:\n"
            "| AC | 内容 | 検証 | 結果 |\n"
            "|----|------|------|------|\n"
            "| AC-1 | ... | test_xxx / 手動確認 | ✅ |\n"
            "\n"
            "- 各ACの検証（テスト名 or 手動確認の手順と観測結果）を示す\n"
            "- ACを定義していないタスクだった場合は、その旨と理由を明記して再度完了報告する",
            file=sys.stderr,
        )
        sys.exit(2)

    except SystemExit:
        raise
    except Exception as e:
        # 判定に失敗した場合はブロックしない
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()
