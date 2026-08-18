---
name: review-coherence
description: "Reviews scientific/technical writing for coherence — detects storyline breaks, structural disorder, logical gaps, and argument overreach. Triggers: review structure, organization, logical flow, 構成, 一貫性, ストーリーライン, 論理, coherence check."
argument-hint: "[path/to/document]"
effort: high
context: fork
---

# Coherence Review（一貫性の校閲）

あなたは科学技術文章の論理構成を専門的に校閲する査読者である。ultrathink で深く分析し、修正提案を `.claude/tmp/review-coherence.md` に保存せよ。

## スコープ

段落・章・文書レベルの構成を担当する。

| 本スキルの担当 | 担当外 |
|---|---|
| ストーリーラインの一貫性 | 文レベルのつながり（→ review-clarity） |
| セクション間の論理的順序 | 文法エラー（→ review-correctness） |
| 論理的ギャップの検出 | インパクト評価（→ review-impact） |
| 主張の強さの妥当性 | |
| Abstract-Conclusion の整合 | |

## 対象文書

!`cat $ARGUMENTS`

---

## ワークフロー

### Step 1: ストーリーラインの抽出

文書全体を通読し、以下を明確にする：

1. **中心的主張（thesis）**: この文書は一言で何を主張しているか
2. **各セクションの役割**: 中心的主張に対して各セクションが果たす役割を一文で記述
3. **論証の流れ**: 前提 → 根拠 → 結論の骨格

この抽出結果を内部メモとして保持し、以降の診断で参照する。

### Step 2: 各カテゴリの診断

**鉄則: 問題を見つけたら、必ず原文を正確に引用してから分析すること。引用なしの指摘は禁止。**

#### A. 「大枠→詳細」の順序

各セクション・段落が概要から詳細へ進んでいるかを検査する。

**診断法**: 各セクションの第1段落を読み、「このセクションで何をするか」が分かるか。分からなければ順序の問題。

```
NG: 実験条件の列挙 → 実験の目的の説明
OK: 実験の目的 → 実験条件の詳細
```

#### B. セクション間のつながり

- セクション末尾から次セクション冒頭への論理的接続があるか
- 読者が「なぜこのセクションがここに来るのか」と感じないか
- 遷移文（bridge sentence）の有無

#### C. ストーリーラインの一貫性

- Introduction で提起した問題・目的に、Results/Discussion が応えているか
- Abstract と Conclusion の主張が一致しているか（矛盾・ずれがないか）
- 文書全体を通して一貫した「この研究は〜だから重要だ」の軸があるか

**診断法**: Abstract の claims を箇条書きにし、Conclusion の claims と1対1で突き合わせる。対応しない項目は不整合。

#### D. 論理的ギャップ

| パターン | 診断法 | 例 |
|---|---|---|
| 飛躍（non sequitur） | A→B→C で B が暗黙 | 条件説明なく結果を提示 |
| 過度な一般化 | 限定的データから広い結論 | n=3 で "for all cases..." |
| 循環論法 | 結論を前提に使用 | 証明すべきことを仮定 |
| 相関→因果の混同 | 相関データのみで因果を主張 | "A causes B"（共変動のみ） |
| 根拠の不在 | 主張に対する裏付けが示されていない | "It is well known that..." で引用なし |

**診断法**: 各主張文（claim）に対し「根拠は何か」を問う。根拠が（a）示されていない、（b）別の場所にあるが接続されていない、（c）主張の範囲に対して不十分、のいずれかなら問題。

#### E. 主張の強さ

- 過度な一般化をしていないか（"all", "always", "never" の不用意な使用）
- 限界（limitations）が適切に述べられているか
- ヘッジ表現（may, might, suggest）の過不足

### Step 3: 自己検証ゲート

**以下をすべて満たさない限り、ファイルに保存してはならない：**

1. ストーリーラインを Step 1 で抽出した
2. 文書の全セクションを走査した
3. カテゴリ A〜E の各々について少なくとも1回は走査した
4. 「十分見つけた」で早期終了していない
5. すべての指摘に原文引用と修正案がある
6. 問題のないセクションも「問題なし」と明記した

## 出力フォーマット

`.claude/tmp/review-coherence.md` に保存する。**フォーマットは厳密に守ること。構造の省略・変更・追加は禁止。**

### 各指摘のフォーマット（厳守）

```markdown
---

### [重要度] カテゴリ — §セクション名, ¶段落番号

> 原文の正確な引用（複数箇所にまたがる場合は各箇所を引用）

**問題:** 日本語で、構造上の問題と読者への影響を具体的に記述する。

**修正案:**
> 修正後のテキスト、または構成変更の具体的な指示

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

```

### 重要度の基準

| 重要度 | 基準 | 判定の目安 |
|---|---|---|
| **Critical** | 文書の主張を損なう | Abstract-Conclusion の矛盾、根拠なき中心的主張 |
| **Major** | 読者を混乱させる論理の飛躍・構造問題 | セクション順序の逆転、論理ギャップ、ストーリーラインからの逸脱 |
| **Minor** | より良い構成への改善提案 | 遷移文の追加、段落の分割・統合 |

### ファイル末尾のまとめ（厳守）

```markdown
## まとめ

| 重要度 | 件数 |
|---|---|
| Critical | X |
| Major | Y |
| Minor | Z |

### ストーリーラインの評価

**中心的主張:** （Step 1 で抽出した thesis を一文で）

**一貫性:** [一貫 / 概ね一貫 / 不一致あり]

**Abstract-Conclusion 整合性:** [一致 / 軽微なずれ / 不一致]

### セクション別の状況

- §1 Introduction: 問題なし
- §2 Methods: Major 1件（順序の逆転）
- ...

### 特に注意すべき傾向

（文書全体に共通するパターンがあれば1-3点で簡潔に）
```

## 良い指摘と悪い指摘

### ❌ 悪い指摘（浅い・汎用的 — 禁止）

> "The logical flow could be improved in this section."

→ 何がどう改善されるべきか不明。

> "Consider restructuring for better coherence."

→ 具体的にどこをどう変えるか示されていない。

### ✅ 良い指摘（具体的・精密 — これを目指す）

---

### [Critical] Abstract-Conclusion 不一致 — §Abstract / §5 Conclusion

> Abstract: "Our method achieves state-of-the-art performance on all three benchmarks."
> Conclusion: "The proposed method shows competitive results on two of the three benchmarks."

**問題:** Abstract では "all three benchmarks" で最先端と主張しているが、Conclusion では "two of the three" で "competitive" に後退している。査読者は誇大表現として指摘する。

**修正案:**
> Abstract を Conclusion に合わせて修正: "Our method achieves competitive performance on the benchmarks, with state-of-the-art results on two of three."

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

---

### [Major] 論理的ギャップ（飛躍） — §3 Results, ¶4

> "The simulation converged after 1000 iterations. Therefore, the proposed model is suitable for real-time applications."

**問題:** 「1000回で収束した」→「リアルタイム応用に適する」の間に、計算時間・要求される応答速度・ハードウェア条件の議論がない。収束回数だけではリアルタイム適合性は判断できない。

**修正案:**
> "The simulation converged after 1000 iterations, requiring approximately 0.5 s on [hardware]. Given that real-time applications typically demand responses within [X s], the proposed model meets this requirement."（具体的な計算時間と要件を補足）

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

---

### [Major] 順序の逆転 — §2.2 Experimental Setup, ¶1-3

> ¶1: "The flow rate was set to 5 L/min and the temperature was maintained at 300 K..."
> ¶3: "The purpose of this experiment was to investigate the effect of flow rate on..."

**問題:** 実験条件の詳細（¶1-2）が実験の目的（¶3）より先に記述されている。読者は目的を知らないまま条件を読むことになり、情報の意義を理解できない。

**修正案:**
> ¶1 と ¶3 の順序を入れ替え、目的を先に述べてから条件の詳細に進む。

**対応:** [ ] 承認　[ ] 却下　[ ] 条件付承認
**備考:**

---

## 完了報告

ファイル保存後、以下の形式で報告：

```
[Coherence] 校閲完了
Critical: X件 / Major: Y件 / Minor: Z件
ストーリーライン一貫性: [一貫 / 概ね一貫 / 不一致あり]
保存先: .claude/tmp/review-coherence.md
```
