---
name: lang-go
description: |
  Goコードの実装・レビュー時のガイドライン。インターフェース設計、エラーハンドリング、
  並行処理、テーブル駆動テスト、禁止事項を定義。
  Use when writing, reviewing, or designing Go code.
---

# Go Implementation Guidelines

linter（gofmt / go vet / golangci-lint）で強制できることはここに書かない。設計判断とイディオムのみ。
プロジェクト固有のディレクトリ構成・フレームワーク規約はプロジェクト側の CLAUDE.md / rules に置く。

## インターフェース設計

- **インターフェースは利用側（consumer）で定義する**。実装側パッケージに大きなインターフェースを置かない
- **小さく保つ**（1〜3メソッド目安）。大きくなったら責務分割のサイン
- 「Accept interfaces, return structs」
- レイヤー境界（Handler → Service → Repository 等）はインターフェースで分離し、コンストラクタ注入でテスト可能にする
- コンパイル時チェックを入れる: `var _ UserRepository = (*userRepository)(nil)`
- **`any` / `interface{}` を引数型に使わない**（JSON marshal 等の汎用ユーティリティ関数を除く）

## エラーハンドリング

- ラップして文脈を足す: `fmt.Errorf("fetch user %s: %w", id, err)`
- 判定は `errors.Is` / `errors.As`。エラーメッセージの文字列比較をしない
- 呼び出し側が分岐する必要があるエラーだけ sentinel（`var ErrNotFound = errors.New(...)`）または独自型にする
- ライブラリコードで `panic` しない。`panic` は「プログラマのバグ」（起動時の設定不備等）のみ
- エラーを握りつぶさない。意図的に無視する場合は `_ = f()` で明示

## 並行処理

- `context.Context` は第1引数。構造体フィールドに保持しない
- goroutine を起動したら**終了条件と誰が待つかを必ず決める**（野良 goroutine 禁止）
- 複数 goroutine のエラー収集は `errgroup`
- channel は「所有者（送信側）が close する」。受信側で close しない
- 共有状態より channel / 不変データを優先。mutex を使うなら保護対象をコメントで明示

## パッケージ構成

- `utils` / `common` / `helpers` パッケージを作らない（ドメイン名で分割）
- 外部公開しないコードは `internal/` へ
- パッケージ名は単数形・小文字・短く（`user`, `auth`）
- グローバル可変変数を避ける。依存はコンストラクタ注入

## テスト

**テーブル駆動テスト**を基本形にする:

```go
func TestParseDuration(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		want    time.Duration
		wantErr bool
	}{
		{"valid hours", "2h", 2 * time.Hour, false},
		{"empty input", "", 0, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := ParseDuration(tt.input)
			if tt.wantErr {
				require.Error(t, err)
				return
			}
			require.NoError(t, err)
			assert.Equal(t, tt.want, got)
		})
	}
}
```

- モックはインターフェースの手書き実装（関数フィールド方式）で十分。モック生成ツールは必要になってから
- 統合テストは `testing.Short()` と環境変数でスキップ可能にする:

```go
if testing.Short() {
	t.Skip("skipping integration test in short mode")
}
```

- 状態を共有しないテストには `t.Parallel()` を付ける

## よく使うコマンド

```bash
go test -short ./...          # ユニットテストのみ
go test -race ./...           # データ競合検出（CIでは必須）
go test -cover ./internal/... # カバレッジ
go vet ./...
```

## 禁止事項

1. `any` / `interface{}` の引数型（汎用ユーティリティを除く）
2. Service 層からの具象型直接依存（テスト困難になる）
3. 生成コード（protoc / gqlgen 等）の手動編集
4. グローバル可変変数・`init()` での重い処理
5. ライブラリコードでの `panic` / `os.Exit`
