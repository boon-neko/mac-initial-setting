---
name: lang-typescript
description: |
  TypeScriptコードの実装・レビュー時のガイドライン。strict前提の型設計、境界バリデーション、
  非同期エラーハンドリング、テストの書き方、禁止事項を定義。
  Use when writing, reviewing, or designing TypeScript code.
---

# TypeScript Implementation Guidelines

linter（eslint / prettier / `tsc --strict`）で強制できることはここに書かない。設計判断とイディオムのみ。
フレームワーク固有ルール（React / Next.js 等）はプロジェクト側の CLAUDE.md / rules に置く。

## 型設計

- `strict: true` 前提。**`any` 禁止** — 型が不明なものは `unknown` で受けて narrowing する
- 外部入力（APIレスポンス・フォーム・env）は **zod 等のスキーマで実行時バリデーション**してから型付きで内部へ。
  `as` キャストで型を「宣言」しない
- 状態のバリエーションは **discriminated union** で表現し、`switch` + `never` チェックで網羅を保証する:

```typescript
type FetchState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; error: Error };
```

- `enum` より union 型（`type Role = "admin" | "member"`）
- 取り違えやすいID等のプリミティブは branded type を検討
- 公開関数の戻り値型は明示する（推論任せにしない）

## 非同期・エラー

- **Promise を放置しない**（floating promise 禁止 — `await` するか `void` で意図を明示）
- `catch (e)` の `e` は `unknown` — 型を確認してから使う
- 失敗が通常フローの操作（バリデーション等）は throw ではなく Result 型 / union での返却を検討
- 独立した非同期処理は `Promise.all` で並列化（直列 `await` を積み重ねない）

## 設計イディオム

- `null` と `undefined` を混ぜない（基本 `undefined` に寄せる）
- イミュータブル優先: `readonly`、スプレッドでの新オブジェクト生成
- barrel file（re-export だけの index.ts）の乱用は循環参照の温床 → 公開境界だけに限定
- `utils.ts` の肥大化禁止 — ドメイン名でファイル分割
- ESM 前提（`import` / `export`）

## テスト

- vitest（または jest）。AAA パターン + 命名はふるまいを書く
- 外部 I/O はモック（`vi.mock`）。ただしモックだらけのテストは設計の臭い —
  純粋関数に切り出してモック不要にする方が先
- 型で守れるものをテストで守らない（型レベルの保証は型に任せる）

## よく使うコマンド

```bash
npx tsc --noEmit          # 型チェック
npx eslint --fix .
npx vitest run --coverage
```

## 禁止事項

1. `any`（`unknown` + narrowing で代替）
2. 検証なしの `as` キャストによる外部データの型付け
3. floating promise（`await` / `void` の明示なし）
4. `@ts-ignore`（やむを得ない場合は `@ts-expect-error` + 理由コメント）
5. `utils.ts` への雑多な追加
