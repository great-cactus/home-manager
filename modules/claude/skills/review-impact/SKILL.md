---
name: review-impact
description: "Evaluate the impact and novelty of scientific/technical writing: whether contributions are communicated clearly, rejection risks, and reviewer perspective. Use when asked to assess impact, novelty, acceptance chances, or how to strengthen a paper or technical document."
argument-hint: "[path/to/document]"
effort: high
context: fork
---

対象の科学技術文章の「**インパクト（Impact）**」を専門的に評価し、修正提案を `.claude/tmp/review-impact.md` に保存せよ。

## スコープ

「価値が読者に伝わるか」を担当する：インパクトの明瞭さ・リジェクト要因の検出・査読者視点での評価。
正確性・明瞭さ・一貫性は review-correctness / review-clarity / review-coherence の担当。

## 対象文書

!`cat $ARGUMENTS`

---

## 1. 深層分析

校閲開始前に文章全体を通読し、思考過程を `<thinking>` ブロックに明示せよ。

## 2. チェック項目

### インパクトの明瞭さ（最重要）
- 研究・技術の貢献が**一読で伝わる**か
- 「何が新しいのか」「なぜ重要か」が明確か
- タイトル・Abstract で価値が伝わるか
- 読者が「だから何？（So what?）」と感じないか

```
NG: 技術的詳細を列挙するだけで意義が不明
OK: 「シンプルな手法で複雑な問題を解決した」という価値が明確
```

### 新規性・貢献の明確さ
- 既存研究・手法との差別化が明確か
- タイトルと Abstract で新規性が伝わるか

### 先行研究との比較
- 重要な先行研究が引用されているか
- 公平な比較がなされているか

### 限界・将来展望
- 研究の限界が適切に認識されているか
- 過度な主張をしていないか
- 将来の発展方向が示されているか

## 3. リジェクト要因チェックリスト

### 致命的（即リジェクト相当）
- [ ] **新規性の欠如**: 既存研究・手法と本質的に同じ
- [ ] **方法論の重大な欠陥**: 結論を支持しない
- [ ] **データ・根拠の不足**: 主張を裏付ける証拠が不十分
- [ ] **スコープ外**: 対象ジャーナルの範囲外

### 重大（Major Revision相当）
- [ ] 先行研究との比較不足
- [ ] 結論の過度な一般化
- [ ] **インパクトが不明瞭**

### 軽微（Minor Revision相当）
- [ ] 文献の追加が必要
- [ ] 図表の改善
- [ ] 軽微な技術的修正

## 4. 想定される査読コメントと対策

| 想定コメント | 対策 |
|------------|------|
| "新規性が不明" | Introduction で既存研究との差を明記 |
| "なぜこの手法?" | Methods で手法選択の理由を説明 |
| "データが少ない" | 追加実験または限界として明記 |
| "一般化しすぎ" | 結論を限定的に書き直す |
| "So what?" | インパクト・実用的価値を明示 |

## 5. 自己検証（保存前に必ず実施）

- [ ] 文書全体を通読した
- [ ] 全チェック項目を確認した
- [ ] 「十分見つけた」で止めず網羅的に探した
- [ ] 各問題に場所と修正案がある
- [ ] 問題のないセクションも「問題なし」と明示した

禁止：チェックリスト未完了で保存 / 曖昧な問題を場所・修正案なしで報告

## 6. 修正提案の保存

`.claude/tmp/review-impact.md` に書き込め（存在しない場合は新規作成）。

各修正案のフォーマット：

```markdown
## [重要度] 問題の種類 - 場所

#### 要修正箇所
（英語：該当箇所の原文）

#### 修正が必要な理由
（日本語）

#### 修正提案
（英語）

#### 対応
- [ ] 承認
- [ ] 拒否
- [ ] 条件付承認

##### modification
（承認後に最終的な修正内容を記載）

---
```

ファイルの末尾に総合評価を追記すること：

```markdown
## 総合評価

採択可能性: [高/中/低]
インパクトの明瞭さ: [明確/やや不明瞭/不明瞭]

強み:
1. ...

要改善点（優先順）:
1. [Critical/Major] ...

推奨: [Accept as is / Minor revision / Major revision / Reject]
```

重要度：
- **Critical** — インパクトや新規性を根本的に損なう問題
- **Major** — 価値の伝達を妨げる明確な問題
- **Minor** — 改善によりインパクトが高まる提案

## 7. 完了報告

```
[Impact] 校閲完了
Critical: X件 / Major: Y件 / Minor: Z件
採択可能性: [高/中/低]
保存先: .claude/tmp/review-impact.md
```
