#!/usr/bin/env python3
"""
PostToolUse hook: Suggest Codex review after Plan tasks.

This hook runs after Task tool execution and suggests Codex consultation
for reviewing plans and implementation strategies.
"""

import json
import os
import sys

# 計画/設計作業を示唆するタスク説明
PLAN_INDICATORS = [
    "plan",
    "design",
    "architect",
    "structure",
    "implement",
    "strategy",
    "approach",
    "solution",
    "refactor",
    "migrate",
    "optimize",
]


def should_suggest_codex_review(tool_input: dict, tool_output: str | None = None) -> tuple[bool, str]:
    """タスク完了後にCodexレビューを提案すべきか判断する."""
    subagent_type = tool_input.get("subagent_type", "").lower()
    description = tool_input.get("description", "").lower()
    prompt = tool_input.get("prompt", "").lower()

    # Planエージェントかどうかをチェック
    if subagent_type == "plan":
        return True, "Plan task completed"

    # 説明/プロンプトで計画キーワードをチェック
    combined_text = f"{description} {prompt}"
    for indicator in PLAN_INDICATORS:
        if indicator in combined_text:
            return True, f"Task involves '{indicator}'"

    return False, ""


def main():
    try:
        data = json.load(sys.stdin)
        tool_name = data.get("tool_name", "")

        # サブエージェントツールのみ処理（旧名: Task / 新名: Agent）
        if tool_name not in ("Task", "Agent"):
            sys.exit(0)

        tool_input = data.get("tool_input", {})
        tool_output = data.get("tool_output", "")

        should_suggest, reason = should_suggest_codex_review(tool_input, tool_output)

        if not should_suggest:
            sys.exit(0)

        # セッションごとに1回だけ提案する（形骸化防止）
        session_id = "".join(
            c for c in data.get("session_id", "default") if c.isalnum() or c in "-_"
        ) or "default"
        flag_file = f"/tmp/claude-codex-plan-review-{session_id}"
        if os.path.exists(flag_file):
            sys.exit(0)
        try:
            with open(flag_file, "w") as f:
                f.write("1")
        except Exception:
            pass

        output = {
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": (
                    f"[Codex Review Suggestion] {reason}. "
                    "Consider having Codex review this plan for potential improvements. "
                    "**Recommended**: Use Task tool with subagent_type='general-purpose' "
                    "to consult Codex and preserve main context."
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
