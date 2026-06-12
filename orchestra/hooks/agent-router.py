#!/usr/bin/env python3
"""
UserPromptSubmit hook: ユーザー入力を分析して適切なエージェントを提案する。

設計/デバッグ → Codex、リサーチ/マルチモーダル → Gemini。

ノイズ対策:
- トリガーは強いシグナルのみに限定（「エラー」「見て」のような汎用語は
  通常の依頼でも頻出し、リマインダーが形骸化するため除外）
- 提案はセッションごと・エージェントごとに1回まで
"""

import json
import os
import sys

FLAG_FILE_PREFIX = "/tmp/claude-agent-router-"

# Codex向けのトリガー（設計、デバッグ、深い推論）
CODEX_TRIGGERS = {
    "ja": [
        "設計", "アーキテクチャ",
        "なぜ動かない", "デバッグ",
        "どちらがいい", "比較して", "トレードオフ",
        "実装方法", "どう実装",
        "リファクタ",
    ],
    "en": [
        "design", "architect",
        "debug", "not working",
        "trade-off", "tradeoff", "which is better",
        "how to implement",
        "refactor",
    ],
}

# Gemini向けのトリガー（リサーチ、マルチモーダル、大規模コンテキスト）
GEMINI_TRIGGERS = {
    "ja": [
        "調べて", "リサーチ", "調査",
        "動画", "音声", "pdf",
        "コードベース全体", "リポジトリ全体",
        "公式ドキュメント", "最新情報",
    ],
    "en": [
        "research", "investigate", "look up",
        "pdf", "video", "audio",
        "entire codebase", "whole repository",
        "official documentation", "latest documentation",
    ],
}


def sanitize_session_id(session_id: str) -> str:
    """セッションIDをファイル名に安全な形に整形する."""
    safe = "".join(c for c in session_id if c.isalnum() or c in "-_")
    return safe or "default"


def already_suggested(session_id: str, agent: str) -> bool:
    """このセッションで該当エージェントを提案済みか."""
    return os.path.exists(f"{FLAG_FILE_PREFIX}{session_id}-{agent}")


def mark_suggested(session_id: str, agent: str) -> None:
    """提案済みフラグを立てる."""
    try:
        with open(f"{FLAG_FILE_PREFIX}{session_id}-{agent}", "w") as f:
            f.write("1")
    except Exception:
        pass


def detect_agent(prompt: str) -> tuple[str | None, str]:
    """どのエージェントが適しているかを判定する."""
    prompt_lower = prompt.lower()

    # Codexトリガーをチェック
    for triggers in CODEX_TRIGGERS.values():
        for trigger in triggers:
            if trigger in prompt_lower:
                return "codex", trigger

    # Geminiトリガーをチェック
    for triggers in GEMINI_TRIGGERS.values():
        for trigger in triggers:
            if trigger in prompt_lower:
                return "gemini", trigger

    return None, ""


def main():
    try:
        data = json.load(sys.stdin)
        prompt = data.get("prompt", "")
        session_id = sanitize_session_id(data.get("session_id", "default"))

        # 短いプロンプトはスキップ
        if len(prompt) < 10:
            sys.exit(0)

        agent, trigger = detect_agent(prompt)

        if agent is None or already_suggested(session_id, agent):
            sys.exit(0)

        mark_suggested(session_id, agent)

        if agent == "codex":
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": (
                        f"[Agent Routing] Detected '{trigger}' - this task may benefit from "
                        "Codex CLI's deep reasoning capabilities. Consider: "
                        "`codex exec --sandbox read-only --full-auto "
                        '"{task description}"` for design decisions, debugging, or complex analysis.'
                    )
                }
            }
            print(json.dumps(output))

        elif agent == "gemini":
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": (
                        f"[Agent Routing] Detected '{trigger}' - this task may benefit from "
                        "Gemini CLI's research capabilities. Consider: "
                        '`gemini -p "Research: {topic}" 2>/dev/null` '
                        "for documentation, library research, or multimodal content."
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
