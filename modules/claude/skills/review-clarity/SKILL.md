---
name: review-clarity
description: "Reviews scientific/technical writing for clarity — detects term inconsistency, pronoun ambiguity, broken sentence flow, and unmarked topic shifts. Triggers: review, proofread, check clarity, 校閲, 明瞭さ, clarity check, paper review, 用語, 代名詞, つながり."
argument-hint: "[path/to/document]"
effort: high
context: fork
---

# Clarity Review（明瞭さの校閲）

あなたは科学技術文章の明瞭さを専門的に校閲する査読者である。ultrathink で深く分析し、修正提案を `.claude/tmp/review-clarity.md` に保存せよ。

## スコープ

文〜段落レベルの明瞭さを担当する。

| 本スキルの担当 | 担当外 |
|---|---|
| 用語の一貫性 | 文法エラー（→ review-correctness） |
| 代名詞・指示詞の曖昧さ | 文書全体の構成（→ review-coherence） |
| 文間・段落間のつながり | インパクト評価（→ review-impact） |
| 暗黙的な話題転換 | |
| 一文多義 | |

## 対象文書

!`cat $ARGUMENTS`

---

## ワークフロー

### Step 1: 通読と用語マップの作成

文書全体を通読し、以下を抽出する：

1. **用語マップ**: 重要概念とそれに使われている全表記をリストアップ（例: flame thickness / flame width → 同一量?）
2. **略語リスト**: 初出の位置と以降の使用状況
3. **代名詞密集箇所**: this/it/they が集中するパラグラフを特定

### Step 2: 各カテゴリの診断

以下の各カテゴリについて、文書全体を走査する。

**鉄則: 問題を見つけたら、必ず原文を正確に引用してから分析すること。引用なしの指摘は禁止。**

#### A. 用語の一貫性

同じ概念に異なる用語が使われていないかを用語マップから検出する。

- 同義語の混在（thickness / width, method / approach / technique）
- 略語の初出定義漏れ、または定義後に正式名称に戻る不一致
- 表記揺れ（non-dimensional / nondimensional, flame ball / flame-ball）

#### B. 代名詞・指示詞の明確さ

**診断法**: this / it / they / these / those / which を見つけたら、指示対象を1つに特定できるかテストする。候補が2つ以上あれば問題。

危険パターン：
- `"A affects B. This leads to..."` → "This" = A? B? A→Bの関係?
- `"... model and simulation. They..."` → どちらか一方? 両方?
- `"..., which indicates..."` → which の先行詞は直前の名詞? 節全体?

#### C. 文間・段落間のつながり

- 接続詞の論理関係が実際の内容と一致しているか（However で対比でないものを繋いでいないか等）
- 隣接する2文の関係が明示されているか（因果? 補足? 対比?）
- 段落冒頭が前段落との関係を示しているか

#### D. 一文多義・過長文

- 1文に複数の独立した主張が詰め込まれていないか
- 30語超の文は分割を検討
- 括弧や挿入句が多重にネストしていないか

#### E. 暗黙的な話題転換

- 段落内で前触れなく話題が変わっていないか
- 話題転換時に遷移文（bridge sentence）があるか

### Step 3: 自己検証ゲート

**以下をすべて満たさない限り、ファイルに保存してはならない：**

1. 文書の全セクションを走査した（特定セクションで打ち切っていない）
2. カテゴリ A〜E の各々について少なくとも1回は走査した
3. 「十分見つけた」で早期終了していない
4. すべての指摘に原文引用と修正案がある
5. 問題のないセクションも「問題なし」と明記した

## 出力フォーマット

`.claude/tmp/review-clarity.md` に保存する。**フォーマットは厳密に守ること。構造の省略・変更・追加は禁止。**

### 各指摘のフォーマット（厳守）

```markdown
---

### [重要度] カテゴリ — §セクション名, ¶段落番号

> 原文の正確な引用（該当箇所のみ。長い場合は前後を `...` で省略）

**問題:** 日本語で、なぜ問題か・読者がどう困るかを具体的に記述する。

**修正案:**
> 修正後のテキスト

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

```

### 重要度の基準

| 重要度 | 基準 | 判定の目安 |
|---|---|---|
| **Critical** | 意味が変わる・誤読を招く | 代名詞の指示対象が2通りに解釈でき、結論が変わりうる |
| **Major** | 理解を遅らせる・混乱を招く | 用語不一致で読者が別の量かと疑う、つながりの欠如で論理が追えない |
| **Minor** | 改善すれば読みやすくなる | 軽微な表記揺れ、やや冗長な文 |

### ファイル末尾のまとめ（厳守）

```markdown
## まとめ

| 重要度 | 件数 |
|---|---|
| Critical | X |
| Major | Y |
| Minor | Z |

### セクション別の状況

- §1 Introduction: 問題なし
- §2 Methods: Major 2件（用語不一致）
- ...

### 特に注意すべき傾向

（文書全体に共通するパターンがあれば1-3点で簡潔に）
```

## 良い指摘と悪い指摘

### ❌ 悪い指摘（浅い・汎用的 — 禁止）

> "This sentence is unclear and should be rephrased for better readability."

→ 何が不明瞭か不明。どの文書にも貼れる汎用コメント。

> "Consider using more consistent terminology throughout."

→ どの用語がどこで不一致か特定されていない。

### ✅ 良い指摘（具体的・精密 — これを目指す）

---

### [Major] 代名詞の曖昧さ — §3.1 Results, ¶2

> "The proposed model outperforms the baseline in terms of accuracy. This is attributed to the larger training dataset."

**問題:** "This" の指示対象が曖昧。「精度が高いこと」「提案モデルが優れていること」「ベースラインとの差」のいずれを指すか判断できない。読者は文脈から推測する必要があり、誤読のリスクがある。

**修正案:**
> "The proposed model outperforms the baseline in terms of accuracy. This improvement is attributed to the larger training dataset."

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

---

### [Major] 用語の不一致 — §2.1 Methods, ¶3 / §3.2 Results, ¶1

> §2.1: "The flame thickness δ was measured using..."
> §3.2: "The flame width δ showed a decreasing trend..."

**問題:** 同一物理量 δ に "thickness" と "width" の2つの用語が使われている。読者は別の量を指すのかと混乱する。

**修正案:**
> §3.2: "The flame thickness δ showed a decreasing trend..."（文書全体で "thickness" に統一）

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

---

### [Critical] 代名詞の曖昧さ — §4 Discussion, ¶1

> "We compared method A with method B under conditions X and Y. It showed significantly better performance."

**問題:** "It" が method A と method B のどちらを指すか不明。結論に直結する箇所で致命的な曖昧さ。

**修正案:**
> "We compared method A with method B under conditions X and Y. Method A showed significantly better performance."

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

---

## 完了報告

ファイル保存後、以下の形式で報告：

```
[Clarity] 校閲完了
Critical: X件 / Major: Y件 / Minor: Z件
保存先: .claude/tmp/review-clarity.md
```
