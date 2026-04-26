---
name: review-coherence
description: "Review scientific/technical writing for coherence: overall structure, section-level flow, storyline consistency, and logical gaps. Use when asked to review the structure, organization, or logical flow of a paper, report, or technical document."
argument-hint: "[path/to/document]"
effort: high
context: fork
---

対象の科学技術文章の「**一貫性（Coherence）**」を専門的に校閲し、修正提案を `.claude/tmp/review-coherence.md` に保存せよ。

## スコープ

段落・章・文書レベルの構成を担当する：ストーリーラインの一貫性・大枠→詳細の順序・論理的ギャップ。
文レベルのつながりは review-clarity、文法ミスは review-correctness の担当。

## 対象文書

!`cat $ARGUMENTS`

---

## 1. 深層分析

校閲開始前に文章全体を通読し、思考過程を `<thinking>` ブロックに明示せよ。

## 2. チェック項目

### 「大枠→詳細」の順序
- 各セクションは概要から始まり詳細に進んでいるか
- 結論・主張を先に述べ、その後に根拠を示しているか

```
NG: 詳細な手順 → 目的の説明
OK: 目的の説明 → 詳細な手順
```

### 段落・章間のつながり
- 遷移文が適切に使われているか
- 読者が「なぜこのセクションが今出てくるのか」と感じないか

### 構造のシンプルさ
- 議論が複雑に入り組んでいないか
- 一段落一主題になっているか
- 脱線・横道がないか

### ストーリーラインの一貫性
- 文書全体を通して一貫したストーリーがあるか
- 各章が全体のストーリーに位置づけられているか
- 主張と結論が一貫しているか（特に Abstract-Conclusion 間）

### 論理の一貫性
- 前提と結論の整合性
- 飛躍や論理的ギャップがないか
- 矛盾する記述がないか

### 主張の強さ
- 過度な一般化をしていないか
- 限界（limitations）が適切に述べられているか

## 3. 論理的ギャップのパターン診断

| パターン | 説明 | 例 |
|---------|------|-----|
| 非順序 | A→B→CでBが抜けている | 条件説明なく結果を提示 |
| 過度一般化 | 限定的データから広い結論 | "For all cases..." |
| 循環論法 | 結論を前提に使用 | 証明すべきことを仮定 |
| 相関と因果の混同 | 相関を因果として記述 | "A causes B"（相関のみ） |

## 4. 自己検証（保存前に必ず実施）

- [ ] 文書全体を通読した
- [ ] 全チェック項目を確認した
- [ ] 「十分見つけた」で止めず網羅的に探した
- [ ] 各問題に場所と修正案がある
- [ ] 問題のないセクションも「問題なし」と明示した

禁止：チェックリスト未完了で保存 / 曖昧な問題を場所・修正案なしで報告

## 5. 修正提案の保存

`.claude/tmp/review-coherence.md` に書き込め（存在しない場合は新規作成）。

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

重要度：
- **Critical** — 文書の主張を損なう致命的な論理エラー、Abstract-Conclusion矛盾
- **Major** — 読者を混乱させる論理の飛躍、構造問題
- **Minor** — より良い構成への改善提案

## 6. 完了報告

```
[Coherence] 校閲完了
Critical: X件 / Major: Y件 / Minor: Z件
保存先: .claude/tmp/review-coherence.md
```
