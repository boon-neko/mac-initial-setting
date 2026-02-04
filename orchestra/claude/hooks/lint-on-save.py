#!/usr/bin/env python3
"""
Post-tool hook: Run linter based on file extension using lint-config.json.

Triggered after Edit or Write tools modify files.
Loads linter commands from lint-config.json and executes them based on file extension.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

# 入力検証の定数
MAX_PATH_LENGTH = 4096

# lint-config.jsonの場所
CONFIG_FILE = Path(__file__).parent.parent.parent / "lint-config.json"


def validate_path(file_path: str) -> bool:
    """ファイルパスをセキュリティのために検証する."""
    if not file_path or len(file_path) > MAX_PATH_LENGTH:
        return False
    # パストラバーサルをチェック
    if ".." in file_path:
        return False
    return True


def load_config() -> dict:
    """linter設定を読み込む."""
    # プロジェクト固有の設定を優先
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    project_config = Path(project_dir) / ".claude" / "lint-config.json"

    if project_config.exists():
        with open(project_config) as f:
            return json.load(f)

    # フォールバックとしてテンプレート設定を使用
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            return json.load(f)

    return {"linters": {}}


def get_file_extension(path: str) -> str:
    """ファイルの拡張子を取得する."""
    return Path(path).suffix


def get_file_path() -> str | None:
    """ツール入力からファイルパスを抽出する."""
    tool_input = os.environ.get("CLAUDE_TOOL_INPUT", "")
    if not tool_input:
        return None

    try:
        data = json.loads(tool_input)
        return data.get("file_path")
    except json.JSONDecodeError:
        return None


def run_command(cmd: list[str], cwd: str) -> tuple[int, str, str]:
    """コマンドを実行して(returncode, stdout, stderr)を返す."""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=30,
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return 1, "", "Command timed out"
    except FileNotFoundError:
        return 1, "", f"Command not found: {cmd[0]}"


def get_linter_commands(extension: str, file_path: str) -> list[list[str]]:
    """ファイル拡張子に対するlinterコマンドを取得する."""
    config = load_config()
    linter = config.get("linters", {}).get(extension, {})

    commands = []
    for key in ["format", "check", "type_check"]:
        if key in linter:
            cmd = [arg.replace("{file}", file_path) for arg in linter[key]]
            commands.append(cmd)
    return commands


def main() -> None:
    file_path = get_file_path()
    if not file_path:
        return

    # 入力を検証
    if not validate_path(file_path):
        return

    extension = get_file_extension(file_path)
    if not extension:
        return

    # この拡張子用のlinterコマンドを取得
    commands = get_linter_commands(extension, file_path)
    if not commands:
        return

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())

    # 表示用の相対パスを決定
    if file_path.startswith(project_dir):
        rel_path = os.path.relpath(file_path, project_dir)
    else:
        rel_path = file_path

    issues: list[str] = []

    # 各linterコマンドを実行
    for cmd in commands:
        ret, stdout, stderr = run_command(cmd, cwd=project_dir)
        if ret != 0:
            output = stdout or stderr
            if output.strip():
                cmd_name = cmd[0] if cmd else "linter"
                issues.append(f"{cmd_name} issues:\n{output}")

    # 結果を報告
    if issues:
        print(f"[lint-on-save] Issues found in {rel_path}:", file=sys.stderr)
        for issue in issues:
            print(issue, file=sys.stderr)
        print(
            "\nPlease review and fix these issues.",
            file=sys.stderr,
        )
    else:
        print(f"[lint-on-save] OK: {rel_path} passed all checks")


if __name__ == "__main__":
    main()
