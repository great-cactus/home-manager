---
name: review-clarity
description: "Review scientific/technical writing for clarity: term consistency, pronoun ambiguity, sentence-level flow, and topic transitions. Use when asked to review, proofread, or check clarity of a paper, report, or technical document."
argument-hint: "[path/to/document]"
effort: high
context: fork
---

対象の科学技術文章の「**明瞭さ（Clarity）**」を専門的に校閲し、修正提案を `.claude/tmp/review-clarity.md` に保存せよ。

## スコープ

文レベルの問題を担当する：用語の一貫性・代名詞の曖昧さ・文間のつながり・話題転換の明示性。
段落/章レベルの構成は review-coherence、文法ミスは review-correctness の担当。

## 対象文書

!`cat $ARGUMENTS`

---

## 1. 深層分析

校閲開始前に文章全体を通読し、思考過程を `<thinking>` ブロックに明示せよ。

## 2. チェック項目

### 用語の一貫性
- 同じ概念に異なる用語が使われていないか
- 略語は初出時に正式名称と共に導入されているか
- 略語と正式名称の使い分けが一貫しているか

### 代名詞・指示詞の明確さ
- **this, it, they, these, those** の指示対象が唯一に定まるか
- 関係代名詞（which, that, who）の先行詞が明確か

### 表記揺れ
- 同一概念に複数の表記が混在していないか

### 文間のつながり
- 接続詞・遷移文が適切に使われているか
- 読者が「なぜこの文が今出てくるのか」と感じないか

### 一文一メッセージ
- 一つの文に複数のメッセージが詰め込まれていないか
- 長い文は分割すべきか

### 暗黙的話題転換
- 文レベルで話題が突然変わっていないか
- 話題転換時に適切な導入があるか

## 3. 自己検証（保存前に必ず実施）

- [ ] 文書全体を通読した
- [ ] 全チェック項目を確認した
- [ ] 「十分見つけた」で止めず網羅的に探した
- [ ] 各問題に場所と修正案がある
- [ ] 問題のないセクションも「問題なし」と明示した

禁止：チェックリスト未完了で保存 / 曖昧な問題を場所・修正案なしで報告

## 4. 修正提案の保存

`.claude/tmp/review-clarity.md` に書き込め（存在しない場合は新規作成）。

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
- **Critical** — 意味が変わる、または理解を妨げる曖昧さ
- **Major** — 用語不一致、代名詞の曖昧さ、つながりの不明確さ
- **Minor** — 軽微な表記揺れ、スタイル改善

## 5. 完了報告

```
[Clarity] 校閲完了
Critical: X件 / Major: Y件 / Minor: Z件
保存先: .claude/tmp/review-clarity.md
```
