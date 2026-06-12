---
name: lang-python
description: |
  Pythonコードの実装・レビュー時のガイドライン。uv/ruffワークフロー、型ヒント、
  境界バリデーション、pytestの書き方、禁止事項を定義。
  Use when writing, reviewing, or designing Python code.
---

# Python Implementation Guidelines

linter（ruff）で強制できることはここに書かない。設計判断とイディオムのみ。
プロジェクト固有のフレームワーク規約はプロジェクト側の CLAUDE.md / rules に置く。

## ツールチェーン

- パッケージ管理は **uv のみ**（pip 直接使用禁止）: `uv add` / `uv sync` / `uv run`
- lint/format は ruff、型チェックは ty（または mypy）
- 実行は常に `uv run` 経由（`uv run pytest`, `uv run python script.py`）

## 型

- **全ての関数に型ヒント必須**（引数・戻り値）
- `Any` は境界（JSONパース直後など）でのみ許容し、即座に具体型へ変換する
- 外部入力（API・ファイル・環境変数）は **pydantic** でバリデーションしてから内部に渡す
- 内部のデータ構造は dict のバケツリレーではなく `dataclass` / `NamedTuple` / pydantic モデル
- `str | None` 形式（PEP 604）を使う。`Optional[str]` は使わない
- 構造的型付けが必要なら `Protocol`

## 設計イディオム

- Early return でネストを浅く保つ
- **ミュータブルなデフォルト引数禁止**（`def f(items: list = [])` はバグ）
- 可変グローバル状態を避ける。状態はクラスか引数で持ち回す
- パス操作は `pathlib.Path`（`os.path` は使わない）
- リソースは context manager（`with`）で管理
- 例外は具体型で捕捉する。`except Exception` での握りつぶしは最上位のエラーハンドラのみ可
- ログは遅延評価形式: `logger.info("user %s", user_id)`（f-string を渡さない）

## テスト（pytest）

- AAA パターン + 命名 `test_{対象}_{条件}_{期待結果}`
- 外部依存（API・DB・時刻）は必ずモック。`patch` は「定義場所」ではなく「使われる場所」に当てる
- 共通セットアップは `conftest.py` の fixture へ
- 入力バリエーションは `@pytest.mark.parametrize` で網羅
- カバレッジ目標 80%+。ただし数字合わせの無意味なテストは書かない

```python
@pytest.mark.parametrize(
    ("input_text", "expected"),
    [
        ("2h", timedelta(hours=2)),
        ("30m", timedelta(minutes=30)),
    ],
)
def test_parse_duration_with_valid_input_returns_timedelta(input_text, expected):
    assert parse_duration(input_text) == expected
```

## よく使うコマンド

```bash
uv run ruff check --fix . && uv run ruff format .
uv run pytest -x -v
uv run pytest --cov=src --cov-report=term-missing
```

## 禁止事項

1. pip の直接使用（必ず uv を通す）
2. 型ヒントなしの関数追加
3. ミュータブルなデフォルト引数
4. 秘密情報のベタ書き（環境変数 + 存在チェックで読む）
5. `except: pass`（エラーの黙殺）
