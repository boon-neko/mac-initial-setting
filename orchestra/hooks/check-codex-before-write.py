#!/usr/bin/env python3
"""
PreToolUse hook: Write/Edit の前に Codex 相談を提案する。

設計判断を伴う変更（アーキテクチャ・スキーマ・抽象定義など）を検知して
Codex 相談のリマインダーを注入する。

ノイズ対策:
- トリガーは「設計判断の可能性が高い」パターンに限定する
  （「class 」「config」のような汎用語は大半の編集で発火し形骸化するため除外）
- 提案はセッションごとに最大 MAX_SUGGESTIONS_PER_SESSION 回まで
"""

import json
import os
import sys

# 入力検証の定数
MAX_PATH_LENGTH = 4096
MAX_CONTENT_LENGTH = 1_000_000

# セッションあたりの提案回数上限（毎回出る警告は読まれなくなるため）
MAX_SUGGESTIONS_PER_SESSION = 3
COUNT_FILE_PREFIX = "/tmp/claude-codex-suggest-count-"


def sanitize_session_id(session_id: str) -> str:
    """セッションIDをファイル名に安全な形に整形する."""
    safe = "".join(c for c in session_id if c.isalnum() or c in "-_")
    return safe or "default"


def load_count(path: str) -> int:
    """このセッションでの提案回数を読み込む."""
    try:
        if os.path.exists(path):
            with open(path) as f:
                return int(f.read().strip() or 0)
    except Exception:
        pass
    return 0


def save_count(path: str, count: int) -> None:
    """提案回数を保存する."""
    try:
        with open(path, "w") as f:
            f.write(str(count))
    except Exception:
        pass


def validate_input(file_path: str, content: str) -> bool:
    """入力をセキュリティのために検証する."""
    if not file_path or len(file_path) > MAX_PATH_LENGTH:
        return False
    if len(content) > MAX_CONTENT_LENGTH:
        return False
    # パストラバーサルをチェック
    if ".." in file_path:
        return False
    return True


# 設計/アーキテクチャの決定を強く示唆するパスパターン
DESIGN_PATH_INDICATORS = [
    "design.md",
    "architecture.md",
    "architecture",
    "schema",
    "migration",
    "interface",
    "abstract",
    ".proto",
]

# コンテンツ内の強い設計パターン（抽象定義のみ）
DESIGN_CONTENT_INDICATORS = [
    "abstract class",
    "from abc import",
    "Protocol",
    "interface ",
]

# 新規ファイルとして「大きい」と判断するサイズ（文字数）
LARGE_NEW_FILE_THRESHOLD = 2000

# 通常は単純な編集のファイル（提案をスキップ）
SIMPLE_EDIT_PATTERNS = [
    ".gitignore",
    "README.md",
    "CHANGELOG.md",
    "requirements.txt",
    "package.json",
    "pyproject.toml",
    ".env.example",
]


def should_suggest_codex(
    tool_name: str, file_path: str, content: str | None = None
) -> tuple[bool, str]:
    """Codex相談を提案すべきか判断する."""
    filepath_lower = file_path.lower()

    # 単純な編集はスキップ
    for pattern in SIMPLE_EDIT_PATTERNS:
        if pattern.lower() in filepath_lower:
            return False, ""

    # ファイルパスで設計指標をチェック
    for indicator in DESIGN_PATH_INDICATORS:
        if indicator in filepath_lower:
            return True, f"File path contains '{indicator}' - likely a design decision"

    if content:
        # コンテンツ内の設計パターンをチェック
        for indicator in DESIGN_CONTENT_INDICATORS:
            if indicator in content:
                return True, f"Content contains '{indicator}' - likely architectural code"

        # 大きな新規ファイル（Write のみ＝新規作成・全置換）
        if tool_name == "Write" and len(content) > LARGE_NEW_FILE_THRESHOLD:
            return True, "Creating a large new file"

    return False, ""


def main():
    try:
        data = json.load(sys.stdin)
        tool_name = data.get("tool_name", "")
        session_id = sanitize_session_id(data.get("session_id", "default"))
        tool_input = data.get("tool_input", {})
        file_path = tool_input.get("file_path", "")
        content = tool_input.get("content", "") or tool_input.get("new_string", "")

        # 入力を検証
        if not validate_input(file_path, content):
            sys.exit(0)

        # セッション上限チェック
        count_path = f"{COUNT_FILE_PREFIX}{session_id}"
        count = load_count(count_path)
        if count >= MAX_SUGGESTIONS_PER_SESSION:
            sys.exit(0)

        should_suggest, reason = should_suggest_codex(tool_name, file_path, content)

        if should_suggest:
            save_count(count_path, count + 1)
            # Claudeに追加のコンテキストを返す
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "additionalContext": (
                        f"[Codex Consultation Reminder] {reason}. "
                        "Consider consulting Codex before making this change. "
                        "**Recommended**: Use Task tool with subagent_type='general-purpose' "
                        "to preserve main context. "
                        "(Direct call OK for quick questions: "
                        "`codex exec --sandbox read-only --full-auto '...'`)"
                    )
                }
            }
            print(json.dumps(output))

        sys.exit(0)  # 常に許可、コンテキストを追加するだけ

    except Exception as e:
        # エラー時はブロックしない
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()
