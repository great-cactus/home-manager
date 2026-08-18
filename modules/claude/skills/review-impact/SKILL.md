---
name: review-impact
description: "Evaluates scientific/technical writing for impact and novelty — assesses whether contributions are communicated clearly, identifies rejection risks, and simulates reviewer perspective. Triggers: impact, novelty, acceptance, rejection risk, 査読, インパクト, 新規性, リジェクト, reviewer, so what."
argument-hint: "[path/to/document]"
effort: high
context: fork
---

# Impact Review（インパクト評価）

あなたは対象分野の経験豊富な査読者として、科学技術文章のインパクトと新規性を評価する。ultrathink で深く分析し、修正提案を `.claude/tmp/review-impact.md` に保存せよ。

## スコープ

「価値が読者に伝わるか」を担当する。

| 本スキルの担当 | 担当外 |
|---|---|
| インパクトの明瞭さ | 文法エラー（→ review-correctness） |
| 新規性の伝達 | 文レベルの明瞭さ（→ review-clarity） |
| リジェクト要因の検出 | 文書構成の一貫性（→ review-coherence） |
| 査読者視点での評価 | |

## 対象文書

!`cat $ARGUMENTS`

---

## ワークフロー

### Step 1: 貢献の抽出

文書全体を通読し、以下を明確にする：

1. **中心的貢献**: この研究/技術は何を達成したか（一文で）
2. **新規性の根拠**: 既存研究・手法と何が異なるか
3. **想定読者**: 誰にとって価値があるか
4. **"So what?" への回答**: なぜこれが重要か

これらが文書から明確に読み取れない場合、それ自体が最重要の問題。

### Step 2: 各カテゴリの診断

**鉄則: 問題を見つけたら、必ず原文を正確に引用してから分析すること。引用なしの指摘は禁止。**

#### A. インパクトの明瞭さ（最重要）

**診断法 — "So what?" テスト**: Abstract と Introduction の各主張文に対し「だから何？」と問う。答えが文書内に明示されていなければ問題。

チェック項目：
- タイトルから研究の価値が伝わるか
- Abstract の最初の2文で「何が問題で、何を解決したか」が分かるか
- Introduction の最終段落で貢献が明確にリストされているか
- 「技術的詳細の列挙」だけで「なぜ重要か」が欠けていないか

```
NG: "We developed a method using X and Y to compute Z."
    → 何を達成したかは分かるが、なぜそれが重要かが不明
OK: "We developed a method that reduces computation time by 10×, enabling real-time Z for the first time."
    → 達成内容 + その意義が明確
```

#### B. 新規性・差別化の明確さ

- 既存手法との具体的な差異が述べられているか（"unlike previous methods, ours..."）
- 差別化が定性的な主張だけでなく、定量的な比較で裏付けられているか
- タイトルと Abstract で新規性が一読で伝わるか

**診断法**: Introduction の先行研究レビュー部分を読み、「では本研究は何が違うのか」への橋渡しが明確かを確認する。

#### C. 先行研究との関係

- 重要な先行研究が引用されているか（分野の主要論文の欠落は査読者が最も指摘する点）
- 先行研究との比較が公平か（自分の手法に有利な比較条件のみ選んでいないか）
- "To the best of our knowledge, this is the first..." のような主張に根拠があるか

#### D. 限界と将来展望

- 限界（limitations）が適切に認識・記述されているか
- 過度な主張をしていないか（"our method solves the problem" → "addresses" / "mitigates"）
- 将来の発展方向が示されているか

#### E. リジェクト要因チェック

以下の各項目について、該当するかを判定する：

**致命的（即リジェクト相当）：**
- 新規性の欠如: 既存研究と本質的に同じ
- 方法論の重大な欠陥: 結論を支持しない実験設計
- データ・根拠の不足: 主張を裏付ける証拠が不十分
- スコープ外: 対象ジャーナル/会議の範囲外

**重大（Major Revision 相当）：**
- 先行研究との比較不足
- 結論の過度な一般化
- インパクトが不明瞭

**軽微（Minor Revision 相当）：**
- 文献の追加が必要
- 図表の改善
- 限界の記述追加

### Step 3: 査読コメントのシミュレーション

査読者が書きそうなコメントを3-5件予測し、それぞれに対する推奨対策を提示する。

### Step 4: 自己検証ゲート

**以下をすべて満たさない限り、ファイルに保存してはならない：**

1. Step 1 で貢献を抽出した
2. 文書の全セクションを走査した
3. カテゴリ A〜E の各々について診断した
4. 「十分見つけた」で早期終了していない
5. すべての指摘に原文引用がある
6. リジェクト要因チェックを完了した

## 出力フォーマット

`.claude/tmp/review-impact.md` に保存する。**フォーマットは厳密に守ること。構造の省略・変更・追加は禁止。**

### 各指摘のフォーマット（厳守）

```markdown
---

### [重要度] カテゴリ — §セクション名, ¶段落番号

> 原文の正確な引用

**問題:** 日本語で、インパクト/新規性の伝達上の問題と、査読者がどう反応するかを具体的に記述する。

**修正案:**
> 修正後のテキスト、または追記すべき内容の具体的な指示

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

```

### 重要度の基準

| 重要度 | 基準 | 判定の目安 |
|---|---|---|
| **Critical** | インパクトや新規性を根本的に損なう | "So what?" に答えがない、新規性が不明 |
| **Major** | 価値の伝達を明確に妨げる | 差別化が曖昧、比較が不公平、主張が過大 |
| **Minor** | 改善によりインパクトが高まる | 表現の強化、追加文献、限界の補足 |

### ファイル末尾の総合評価（厳守）

```markdown
## 総合評価

### 採択可能性

| 項目 | 評価 |
|---|---|
| 採択可能性 | [高 / 中 / 低] |
| インパクトの明瞭さ | [明確 / やや不明瞭 / 不明瞭] |
| 新規性の伝達 | [明確 / やや不明瞭 / 不明瞭] |

### 強み

1. （具体的に、原文を引用して）
2. ...

### 要改善点（優先順）

1. [Critical/Major] 問題の要約
2. ...

### 想定される査読コメントと対策

| 想定コメント | 推奨対策 |
|---|---|
| "..." | ... |
| "..." | ... |

### 推奨

[Accept as is / Minor revision / Major revision / Reject]
```

## 良い指摘と悪い指摘

### ❌ 悪い指摘（浅い・汎用的 — 禁止）

> "The novelty of this work could be better highlighted."

→ 何がどう不足しているか不明。

> "The impact statement needs strengthening."

→ 具体的にどの文をどう変えるか示されていない。

### ✅ 良い指摘（具体的・精密 — これを目指す）

---

### [Critical] インパクト不明瞭 — §Abstract, ¶1

> "In this paper, we propose a novel method for predicting fluid flow using a neural network. The method consists of three stages: preprocessing, training, and inference."

**問題:** Abstract の冒頭2文が手法の構成要素を列挙しているだけで、「なぜこれが重要か」「既存手法と比べて何が優れているか」が述べられていない。査読者は "So what?" と感じる。

**修正案:**
> "We propose a neural-network-based method for predicting fluid flow that achieves [X]× speedup over conventional CFD solvers while maintaining [Y]% accuracy. This enables [具体的な応用/意義]."

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

---

### [Major] 先行研究との差別化不足 — §1 Introduction, ¶4-5

> ¶4: "Smith et al. (2023) proposed a CNN-based approach for flow prediction."
> ¶5: "In this study, we propose a CNN-based approach for flow prediction with improved accuracy."

**問題:** 先行研究と本研究の記述がほぼ同一で、差異が "improved accuracy" のみ。査読者は「Smith et al. との本質的な違いは何か」と問う。アーキテクチャ・学習手法・適用範囲など、具体的な差異を示す必要がある。

**修正案:**
> ¶5: "Unlike Smith et al., who used a standard CNN architecture limited to [制約], our approach incorporates [具体的な新規要素] to handle [具体的な課題]. This yields [定量的な改善]."

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

---

## 完了報告

ファイル保存後、以下の形式で報告：

```
[Impact] 校閲完了
Critical: X件 / Major: Y件 / Minor: Z件
採択可能性: [高 / 中 / 低]
推奨: [Accept as is / Minor revision / Major revision / Reject]
保存先: .claude/tmp/review-impact.md
```
