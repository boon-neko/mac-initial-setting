#!/usr/bin/env python3
"""
PreToolUse hook: Suggest Gemini for research tasks.

Analyzes web search/fetch operations and suggests using Gemini CLI
for comprehensive research with its larger context window.
"""

import json
import sys

# 深いリサーチがGeminiの恩恵を受けることを示すキーワード
RESEARCH_INDICATORS = [
    "documentation",
    "best practice",
    "comparison",
    "library",
    "framework",
    "tutorial",
    "guide",
    "example",
    "pattern",
    "architecture",
    "migration",
    "upgrade",
    "breaking change",
    "api reference",
    "specification",
]

# Geminiが必要ない単純な検索
SIMPLE_LOOKUP_PATTERNS = [
    "error message",
    "stack trace",
    "version",
    "release notes",
    "changelog",
]


def should_suggest_gemini(query: str, url: str = "") -> tuple[bool, str]:
    """このリサーチにGeminiを提案すべきか判断する."""
    query_lower = query.lower()
    url_lower = url.lower()
    combined = f"{query_lower} {url_lower}"

    # 単純な検索はスキップ
    for pattern in SIMPLE_LOOKUP_PATTERNS:
        if pattern in combined:
            return False, ""

    # リサーチ指標をチェック
    for indicator in RESEARCH_INDICATORS:
        if indicator in combined:
            return True, f"Research involves '{indicator}'"

    # 長いクエリは複雑なリサーチを示唆
    if len(query) > 100:
        return True, "Complex research query detected"

    return False, ""


def main():
    try:
        data = json.load(sys.stdin)
        tool_name = data.get("tool_name", "")
        tool_input = data.get("tool_input", {})

        # ツールタイプに基づいてクエリ/URLを取得
        query = ""
        url = ""
        if tool_name == "WebSearch":
            query = tool_input.get("query", "")
        elif tool_name == "WebFetch":
            url = tool_input.get("url", "")
            query = tool_input.get("prompt", "")

        should_suggest, reason = should_suggest_gemini(query, url)

        if should_suggest:
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "additionalContext": (
                        f"[Gemini Research Suggestion] {reason}. "
                        "For comprehensive research, consider using Gemini CLI (1M token context). "
                        "**Recommended**: Use Task tool with subagent_type='general-purpose' "
                        "to consult Gemini and save results to .claude/docs/research/. "
                        "(Direct call OK for quick questions: `gemini -p '...' 2>/dev/null`)"
                    )
                }
            }
            print(json.dumps(output))

        sys.exit(0)

    except Exception as e:
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()
