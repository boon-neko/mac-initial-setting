---
name: research
description: "技術トピックの最新情報を調査し、Gemini CLIと壁打ちしながら深掘りして報告する"
category: utility
complexity: advanced
mcp-servers: []
personas: []
---

# /research - 最新情報調査コマンド

## Triggers
- 技術選定のための調査が必要な時
- 最新のライブラリ、フレームワーク、ツールの情報収集
- 比較検討が必要な時
- 「調査して」「調べて」「最新の情報を」などのリクエスト

## Usage
```
/research <トピック> [--depth quick|deep] [--save]
```

### Examples
```
/research MLXでのEmbedding実装
/research 日本語LLMの最新動向 --depth deep
/research pgvectorのパフォーマンス最適化 --save
```

## Behavioral Flow

### Phase 1: 初期調査
1. **WebSearch**で最新情報を収集
2. 公式ドキュメント、GitHub、Hugging Faceを優先
3. ベンチマーク結果や比較記事を探す
4. 調査時点の日付を明記

### Phase 2: Gemini壁打ち
Gemini CLIを使って調査内容を深掘り:

```bash
# 見落とし確認
gemini -p "以下のトピックについて、見落としている観点や追加で調べるべきことを教えて: <調査要約>"

# 技術的詳細の確認
gemini -p "以下の技術選択のメリット・デメリットを整理して: <選択肢>"

# 実装アドバイス
gemini -p "以下の構成で実装する場合の注意点は？: <構成案>"
```

壁打ちルール:
- 1回の質問は1トピックに絞る
- 新しい観点が出たらWebSearchで追加調査
- 3-5回の壁打ちで十分

### Phase 3: レポート作成
以下の形式で出力:

```markdown
## 調査レポート: <トピック>

### 調査日
YYYY-MM-DD

### サマリー
- 結論を3行以内で

### 比較表
| 項目 | 選択肢A | 選択肢B |
|------|---------|---------|

### 推奨
- 推奨する選択と理由

### 注意点
- 実装時の注意点

### 参考リンク
- ソース一覧

### Gemini壁打ちメモ
- 壁打ちで得られた洞察
```

### Phase 4: 保存（--save指定時）
```
docs/research/YYYY-MM-DD-<topic>.md
```

## Tool Coordination
- **WebSearch**: 最新情報の収集
- **WebFetch**: 公式ドキュメントの詳細取得
- **Bash**: Gemini CLI実行（`gemini -p "質問"`）
- **Write**: レポート保存

## Key Patterns
- **最新情報優先**: 調査時点の日付を必ず明記
- **一次情報重視**: 公式ドキュメント > ブログ記事
- **壁打ち活用**: Geminiで見落としチェック
- **ソース明記**: 全情報に出典を付ける

## Gemini CLI Reference
```bash
gemini -p "質問"      # 単発質問
gemini -i "質問"      # インタラクティブ
gemini -y -p "質問"   # 確認なし実行
```
