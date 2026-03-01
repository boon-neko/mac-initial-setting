#!/usr/bin/env python3
"""
PreToolUse hook: Check if Codex consultation is recommended before Write/Edit.

This hook analyzes the file being modified and suggests Codex consultation
for design decisions, complex implementations, or architectural changes.
"""

import json
import sys
from pathlib import Path

# 入力検証の定数
MAX_PATH_LENGTH = 4096
MAX_CONTENT_LENGTH = 1_000_000


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


# 設計/アーキテクチャの決定を示唆するパターン
DESIGN_INDICATORS = [
    # ファイルパターン
    "DESIGN.md",
    "ARCHITECTURE.md",
    "architecture",
    "design",
    "schema",
    "model",
    "interface",
    "abstract",
    "base_",
    "core/",
    "/core/",
    "config",
    "settings",

    # コンテンツ内のコードパターン
    "class ",
    "interface ",
    "abstract class",
    "def __init__",
    "from abc import",
    "Protocol",
    "@dataclass",
    "TypedDict",
]

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


def should_suggest_codex(file_path: str, content: str | None = None) -> tuple[bool, str]:
    """Codex相談を提案すべきか判断する."""
    path = Path(file_path)
    filepath_lower = file_path.lower()

    # 単純な編集はスキップ
    for pattern in SIMPLE_EDIT_PATTERNS:
        if pattern.lower() in filepath_lower:
            return False, ""

    # ファイルパスで設計指標をチェック
    for indicator in DESIGN_INDICATORS:
        if indicator.lower() in filepath_lower:
            return True, f"File path contains '{indicator}' - likely a design decision"

    # コンテンツがある場合はチェック
    if content:
        # 大きなコンテンツの新規ファイル
        if len(content) > 500:
            return True, "Creating new file with significant content"

        # コンテンツ内の設計パターンをチェック
        for indicator in DESIGN_INDICATORS:
            if indicator in content:
                return True, f"Content contains '{indicator}' - likely architectural code"

    # src/ディレクトリ内の新規ファイル
    if "/src/" in file_path or file_path.startswith("src/"):
        if content and len(content) > 200:
            return True, "New source file - consider design review"

    return False, ""


def main():
    try:
        data = json.load(sys.stdin)
        tool_input = data.get("tool_input", {})
        file_path = tool_input.get("file_path", "")
        content = tool_input.get("content", "") or tool_input.get("new_string", "")

        # 入力を検証
        if not validate_input(file_path, content):
            sys.exit(0)

        should_suggest, reason = should_suggest_codex(file_path, content)

        if should_suggest:
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
