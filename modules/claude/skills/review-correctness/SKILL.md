---
name: review-correctness
description: "Review scientific/technical writing for correctness: grammar errors, tense consistency, equation accuracy, numerical/unit consistency, and citation validity. Use when asked to check grammar, equations, numbers, units, or references in a paper or technical document."
argument-hint: "[path/to/document]"
effort: high
context: fork
---

対象の科学技術文章の「**正確性（Correctness）**」を専門的に校閲し、修正提案を `.claude/tmp/review-correctness.md` に保存せよ。

## スコープ

「正しい/誤り」が客観的に判断できる問題のみを担当する：
文法エラー・数式・数値・単位・引用参照の正確性。
曖昧さ・スタイル・構成は review-clarity / review-coherence の担当。

## 対象文書

!`cat $ARGUMENTS`

---

## 1. 深層分析

校閲開始前に文章全体を通読し、思考過程を `<thinking>` ブロックに明示せよ。

## 2. チェック項目

### 文法エラー
- 主語と動詞の一致
- 冠詞（a, an, the）の適切な使用
- 前置詞の正確さ
- 複数形・単数形の使い分け

#### 学術・技術文書での推奨時制

| セクション | 推奨時制 |
|-----------|---------|
| Abstract | 過去形（研究内容）、現在形（結論） |
| Introduction | 現在形（一般的事実）、過去形（先行研究） |
| Methods | 過去形 |
| Results | 過去形 |
| Discussion | 現在形（解釈）、過去形（結果への言及） |

#### よくある文法ミス

| 避けるべき表現 | 推奨表現 |
|--------------|---------|
| is existed | exists |
| can be able to | can / is able to |
| more higher | higher |
| the value is increased | the value increases |

### 数式の正確性
- 次元解析（単位の整合性）
- 記号の定義と一貫した使用
- 方程式番号の参照の正確さ

### 数値・単位
- 有効数字の適切さ
- SI単位の正しい表記
- 数値の整合性（本文・図・表間）

### 引用・参照の正確性
- 参照番号が正しいか
- 式・図・表への参照が存在するか
- 参照先の内容と本文の記述が一致するか

### 図表の技術的正確性
- 軸ラベルと単位が正しいか
- キャプションが正確か

## 3. 自己検証（保存前に必ず実施）

- [ ] 文書全体を通読した
- [ ] 全チェック項目を確認した
- [ ] 「十分見つけた」で止めず網羅的に探した
- [ ] 各問題に場所と修正案がある
- [ ] 問題のないセクションも「問題なし」と明示した
- [ ] 確認できない事実は断定せず「?」付きでフラグした

禁止：チェックリスト未完了で保存 / 独自判断で確認できない事実を断定

## 4. 修正提案の保存

`.claude/tmp/review-correctness.md` に書き込め（存在しない場合は新規作成）。

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
- **Critical** — 技術的に誤りで結論や再現性に影響する
- **Major** — 明確な文法エラー、数値・単位の不整合
- **Minor** — 軽微な表記ミス

## 5. 完了報告

```
[Correctness] 校閲完了
Critical: X件 / Major: Y件 / Minor: Z件
保存先: .claude/tmp/review-correctness.md
```
