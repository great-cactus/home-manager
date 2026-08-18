---
name: review-correctness
description: "Reviews scientific/technical writing for correctness — detects grammar errors, tense inconsistency, equation inaccuracy, numerical/unit mismatches, and citation errors. Triggers: grammar, tense, equation, unit, citation, 文法, 時制, 数式, 単位, 参照, correctness check."
argument-hint: "[path/to/document]"
effort: high
context: fork
---

# Correctness Review（正確性の校閲）

あなたは科学技術文章の正確性を専門的に校閲する査読者である。ultrathink で深く分析し、修正提案を `.claude/tmp/review-correctness.md` に保存せよ。

## スコープ

「正しい/誤り」が客観的に判断できる問題のみを担当する。

| 本スキルの担当 | 担当外 |
|---|---|
| 文法エラー（主語-動詞一致、冠詞、前置詞、数） | 曖昧さ・スタイル（→ review-clarity） |
| 時制の不整合 | 文書構成（→ review-coherence） |
| 数式の正確性（次元、記号、番号） | インパクト評価（→ review-impact） |
| 数値・単位の不整合 | |
| 引用・参照の正確性 | |

## 対象文書

!`cat $ARGUMENTS`

---

## ワークフロー

### Step 1: 通読と要素の抽出

文書全体を通読し、以下を抽出する：

1. **セクション構成**: 各セクションの種類（Introduction / Methods / Results / Discussion 等）→ 時制ルールの適用基準
2. **記号リスト**: 文書中の全変数記号とその定義箇所
3. **相互参照リスト**: 式番号・図番号・表番号・文献番号の参照と被参照の対応

### Step 2: 各カテゴリの診断

**鉄則: 問題を見つけたら、必ず原文を正確に引用してから分析すること。引用なしの指摘は禁止。**

**確認できない事実は断定しない。「?」付きでフラグすること。**

#### A. 文法エラー

以下のパターンを重点的に走査する：

| チェック項目 | 典型的な誤り | 正しい形 |
|---|---|---|
| 主語-動詞一致 | "The results shows..." | "The results show..." |
| 冠詞 | "in the Fig. 5" | "in Fig. 5" |
| 前置詞 | "consistent to" | "consistent with" |
| 不要な受動態 | "is existed" | "exists" |
| 二重比較 | "more higher" | "higher" |
| 可算/不可算 | "informations" | "information" |
| 冗長表現 | "can be able to" | "can" / "is able to" |

#### B. 時制の一貫性

セクション種別に応じた推奨時制との整合性を検査する：

| セクション | 推奨時制 | 根拠 |
|---|---|---|
| Abstract | 過去形（研究内容）、現在形（結論） | 完了した研究 + 普遍的主張 |
| Introduction | 現在形（一般的事実）、過去形（先行研究） | 既知事実 + 歴史的記述 |
| Methods | 過去形 | 実施済みの手順 |
| Results | 過去形 | 得られた結果 |
| Discussion | 現在形（解釈）、過去形（結果への言及） | 議論 + 結果の再参照 |
| 図表の説明 | 現在形 | "Figure 3 shows..." |

**診断法**: 各セクション内で動詞を抽出し、推奨時制からの逸脱を検出する。同一段落内での不整合は特に重大。

#### C. 数式の正確性

- **次元解析**: 等式の両辺で単位が一致するか
- **記号の一貫性**: 同一記号が異なる量を指していないか、定義と使用が一致しているか
- **式番号の参照**: 本文中の "Eq. (3)" が実際に式 (3) を指しているか
- **添字・上付きの整合性**: 定義時と使用時で添字が一致しているか

#### D. 数値・単位

- **有効数字**: 測定精度と表記桁数の整合性（有効数字3桁の測定値を6桁で記載していないか）
- **SI単位**: 正しい表記か（Pa, not pa; kHz, not KHz）
- **数値の整合性**: 本文・図・表間で同一データの値が一致しているか
- **数値範囲**: 前後で矛盾する数値がないか（"10–20 K" と後述の "15–25 K"）

#### E. 引用・参照の正確性

- 式・図・表の番号が存在するか（"Fig. 8" が存在しない等）
- 参照先の内容と本文の記述が整合するか（"as shown in Fig. 3" → Fig. 3 が本当にそれを示しているか）
- 文献番号が本文中で正しく参照されているか
- キャプションの内容が図表の実際の内容と一致するか

### Step 3: 自己検証ゲート

**以下をすべて満たさない限り、ファイルに保存してはならない：**

1. 文書の全セクションを走査した
2. カテゴリ A〜E の各々について少なくとも1回は走査した
3. 「十分見つけた」で早期終了していない
4. すべての指摘に原文引用と修正案がある
5. 問題のないセクションも「問題なし」と明記した
6. 確認できない事実は断定せず「?」付きでフラグした

## 出力フォーマット

`.claude/tmp/review-correctness.md` に保存する。**フォーマットは厳密に守ること。構造の省略・変更・追加は禁止。**

### 各指摘のフォーマット（厳守）

```markdown
---

### [重要度] カテゴリ — §セクション名, ¶段落番号

> 原文の正確な引用

**問題:** 日本語で、何が誤りか・正しい規則は何かを具体的に記述する。

**修正案:**
> 修正後のテキスト

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

```

### 重要度の基準

| 重要度 | 基準 | 判定の目安 |
|---|---|---|
| **Critical** | 技術的に誤りで結論や再現性に影響 | 数式の次元不整合、数値の矛盾、存在しない図への参照 |
| **Major** | 明確な文法エラー・数値/単位の不整合 | 主語-動詞不一致、時制の混在、有効数字の過剰 |
| **Minor** | 軽微な表記ミス | 単位表記の大文字小文字、軽微な冠詞の問題 |

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
- §2 Methods: Critical 1件（次元不整合）、Minor 2件
- ...

### 特に注意すべき傾向

（文書全体に共通するパターンがあれば1-3点で簡潔に）
```

## 良い指摘と悪い指摘

### ❌ 悪い指摘（浅い・汎用的 — 禁止）

> "There are some grammatical errors in this section."

→ どの文のどの語が誤りか不明。

> "Check the tense consistency in the Methods section."

→ どの文がどの時制で不整合か特定されていない。

### ✅ 良い指摘（具体的・精密 — これを目指す）

---

### [Major] 時制の不整合 — §2 Methods, ¶2

> "The samples were heated at 500 °C for 2 hours. The temperature increases gradually during the first 30 minutes."

**問題:** Methods セクション内で過去形（"were heated"）と現在形（"increases"）が混在している。Methods は実施済みの手順を記述するため、過去形に統一すべき。

**修正案:**
> "The samples were heated at 500 °C for 2 hours. The temperature increased gradually during the first 30 minutes."

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

---

### [Critical] 数値の不整合 — §3.1 Results, ¶1 / Table 2

> §3.1: "The maximum efficiency reached 92.3%."
> Table 2, row 3: "Max. efficiency: 91.8%"

**問題:** 本文と表で同一データの値が異なる（92.3% vs 91.8%）。どちらが正しいか著者が確認する必要がある。

**修正案:**
> 正しい値に統一すること（著者確認が必要）

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

---

### [Major] 冠詞の誤用 — §3.2 Results, ¶3

> "As shown in the Fig. 5, the temperature distribution..."

**問題:** 図番号を指すときに定冠詞 "the" は不要。"in Fig. 5" が科学技術文章の標準。

**修正案:**
> "As shown in Fig. 5, the temperature distribution..."

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

---

## 完了報告

ファイル保存後、以下の形式で報告：

```
[Correctness] 校閲完了
Critical: X件 / Major: Y件 / Minor: Z件
保存先: .claude/tmp/review-correctness.md
```
