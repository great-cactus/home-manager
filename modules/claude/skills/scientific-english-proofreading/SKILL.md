---
name: scientific-english-proofreading
description: Proofreads English in scientific and technical writing—manuscript drafts, journal papers, conference papers, abstracts, figure captions, technical reports, and proposal text—to make it maximally simple, unambiguous, and natural to native English readers. Use this skill whenever the user asks for proofreading, polishing, revising, or "校閲" of English sentences in a research/technical context, including phrases like "make this natural English", "校閲して", "for my manuscript", "for the paper", "as scientific text", or pastes English text drawn from a paper, abstract, or technical document. Strongly prefer this skill over generic English help whenever the content involves equations, figure references (Fig./Figure), units, citations, or technical terminology. Do NOT use this for emails, casual messages, or creative writing.
---

# Scientific/Technical English Proofreading

Goal: revise the user's English so it is **(1) maximally simple, (2) unambiguous in interpretation, and (3) natural to native English readers** in a scientific/technical register.

The user is typically a non-native English speaker writing for international peer-reviewed publication. The job is not to "fix mistakes" but to produce English that a careful native scientific writer would produce.

## Output format

Use **Japanese** for explanations (the user's working language for proofreading feedback). Keep the revised English in English.

```
**校閲案:**

> [Revised English in a quoted block. Preserve paragraph structure if multiple sentences.]

**主な変更点:**

- `original phrase` → `revised phrase`：why this change improves clarity, simplicity, or naturalness
- `original phrase` → `revised phrase`：reasoning
- (more bullets as needed — typically 3–7 for a single sentence)
```

For multi-sentence inputs, group the revisions naturally — usually one combined `校閲案` block, then bullets organized by sentence (e.g., "1文目:", "2文目:") when changes are extensive.

When the input contains internal inconsistencies in terminology, notation, or formatting, add a separate section:

```
**表記の整合性:**
- (note about a term/symbol/spelling used inconsistently, with a recommended unified form)
```

## Editorial principles, in priority order

### 1. Logical correctness first

If the original sentence has a logical issue, fix it before stylistic polishing — and call it out in the explanation. Common logical issues:

- **Inverted subject/object relations**: e.g., "the sphere's volume occupies the region" reverses the natural relation; the volume *corresponds to* or *equals* the region's volume.
- **Tense mismatch within one sentence**: `a hole opened ... and the hole grows` should be all-present or all-past.
- **Number agreement on technical concepts**: `the multiple types of behaviors` (when listing categories) usually wants `several types of behavior` (uncountable).
- **Restrictive vs. non-restrictive clauses**: `the bifurcation, represented by the jump limit, does not occur` (non-restrictive: all bifurcations) vs. `the bifurcation represented by the jump limit does not occur` (restrictive: that specific one). The technical meaning often demands the restrictive form.

### 2. Simplicity and concision

Prefer:

- **Verbs over nominalizations**: `improving its clarity` → `to clarify`; `the bifurcation of the solution` → `solution bifurcation`; `provides an explanation of` → `explains`.
- **Active over passive** when both work and the agent is obvious or important.
- **Short connectors**: cut empty `the case of`, `and so on`, sentence-initial `Now,`. `In the donut-shaped flame case` → `In the donut-shaped case`.
- **Drop redundant qualifiers**: `language quality will be improved` → `language will be polished`.

### 3. Unambiguous interpretation

If a phrase is ambiguous between two readings, either pick the most likely one and flag the alternative, or ask the user to clarify (see "When to ask"). Common ambiguity sources:

- **`As`** (because / while / as) → prefer `Because`, `Although`, or `When` for clarity.
- **`while`** (during / whereas) → prefer `whereas` for contrast in formal writing.
- **`for` vs. `in`/`of`/`to`** with conditions, cases, or domains:
  - `comments for condition (iii)` → `comments in condition (iii)` (the comments are about the condition)
  - `added in the manuscript` → `added to the manuscript` (`add to` is the standard collocation)
- **`consistent with X and Y`** is ambiguous between "agrees with both" and "agrees between the two"; for domain comparisons use `consistent between X and Y`.

### 4. Apply scientific writing conventions

These are the conventions that distinguish polished manuscript prose from a rough draft:

- **Figure and table references**:
  - At sentence head: `Figure 5 shows ...`, `Table 2 lists ...` (spelled out, no leading `The`)
  - Inside sentences: `... as shown in Fig. 5.` (abbreviated)
  - Never: `The Fig. 5`, `Figs. 5`, or `figure 5` mid-sentence with cap-F.
- **Cross-references**: parenthesize — `(see Section 3.2)`, `(Eq. 5)`, `(Fig. 7)`. Use spaced abbreviations (`Eq. 5`, not `Eq.5`).
- **Compound modifiers** before nouns: hyphenate.
  - `heat-loss parameter`, `ring-shaped flame`, `non-dimensional length`, `solution-curve behavior`, `two-dimensional configuration`, `low-temperature combustion`.
  - But NOT after the noun: `the parameter is non-dimensional`.
- **Multiplication sign**: use `×` (U+00D7), not the letter `x`. `aa × aa`, not `aa x aa`.
- **Equation/variable references**: if a sentence has a clearly missing variable (e.g., `in the  plane`, `iso-surface of  to clarify`), point this out and use `[variable]` as a placeholder rather than guessing.
- **Em dashes** (`—`) for parenthetical lists in formal text, especially when the list contains commas: `three representative cases — Le = 1.50, 3.10, and 4.00 — are examined`.
- **Article use with technical terms**: established quantities/concepts get `the` (`the laminar flame speed`, `the Reynolds number`); novel/unspecified ones get `a/an` or no article (`a steady solution`, `non-dimensional time`).
- **Tense for stable scientific content**:
  - Description of figures, tables, and equations in the manuscript: present tense — `Figure 7 shows`, `Equation (3) gives`.
  - Methods and procedures performed: simple past — `the simulations were performed`, `we computed`.
  - General physical laws and established facts: present tense — `the flame propagates outward`.

### 5. Terminology and notation consistency (表記ゆれ)

Native scientific writers use **one term for one concept** throughout a manuscript. Inconsistency confuses readers and undermines the writer's authority. Check for and flag:

- **Same concept, different terms**: e.g., switching between `flame thickness` and `flame width` for the same quantity, or between `extinction limit` / `quenching limit` / `flammability limit` when one was intended.
- **Same quantity, different symbols**: e.g., introducing `δ_L` in one sentence and using `ℓ_L` later for the same flame thickness.
- **Inconsistent hyphenation/spelling**: `non-dimensional` vs. `nondimensional` vs. `non dimensional`; `iso-surface` vs. `isosurface`; `flame ball` vs. `flame-ball`. Pick one form and stick with it (note: hyphenation may legitimately differ between modifier-before-noun usage and predicative usage).
- **Abbreviation drift**: `Dielectric Barrier Discharge (DBD)` defined once but later spelled out again, or vice versa.
- **Capitalization drift**: `Reynolds number` (proper noun-derived, capitalized) vs. `reynolds number`; `Figure 7` mid-sentence inconsistently with `Fig. 7` elsewhere.
- **Number formatting drift**: `0.1 mm`, `0.10 mm`, `1e-1 mm` for similar quantities; mixing decimal separator conventions.
- **Hyphen-vs-en-dash drift**: number ranges should use en-dash (`5–10 K`), not hyphen (`5-10 K`); similarly for compound author names.

When a single sentence is submitted in isolation, internal inconsistency may not be visible. In that case, do not invent issues. When multiple sentences (or a paragraph) are submitted, scan for these patterns and report findings under `**表記の整合性:**`.

### 6. Naturalness

When two phrasings are equally clear and concise, prefer what a native scientific writer would actually choose:

- `representative length scale` → `characteristic length scale` (the established term in many fields).
- `obtained from 3D code` → `obtained with 3D code` (the code is a tool used to obtain the result).
- `coupled the discussion` → `discuss ... together` / `jointly discuss`.
- Vary repeated phrasings: if `is close to` appears in two adjacent sentences, change one to `is comparable to`.

## When to ask before proofreading

Use a clarifying question (via `ask_user_input_v0` if available, otherwise inline) when:

- The English is grammatical but ambiguous between two distinct meanings, and the choice affects most of the revision. (e.g., "boundary y_f values were consistent with two domains" — does it mean "consistent across two domains" or "consistent given the two domains"?)
- The text appears to come from a section type that significantly affects register (abstract vs. methods vs. discussion), and the choice is non-obvious from the text alone.

**Don't** ask trivial questions ("which figure number?") — leave a placeholder and proceed.

## When to suggest alternatives

After the main `校閲案`, offer brief alternatives when relevant:

- The user might prefer a different nuance (e.g., `is close to` for near-equality vs. `is comparable to` for order-of-magnitude match).
- A more aggressive rewrite would shorten the sentence further or merge with adjacent ones.
- Joining two sentences with a participial phrase or splitting a long one would improve flow.

Keep alternatives short — one line each, with a one-line reason. Don't crowd them.

## Things to avoid

- **Do not** explain in a grading-style ("you made an error in..."). Frame changes as improvements with reasoning.
- **Do not** use analogies or metaphors to explain grammar choices unless explicitly asked. The user has stated this preference.
- **Do not** restructure paragraphs the user did not submit. If they paste one sentence, revise that sentence; offer a paragraph-level rewrite only as an opt-in alternative.
- **Do not** silently fix variable names or numerical values. If a variable looks missing or wrong, flag it and use a placeholder.
- **Do not** generate fictitious citations, page numbers, or author names. If the user wrote `(Smith et al., 20xx)` leave the placeholder; if a citation seems missing, note it but don't invent one.
- **Do not** say "this is a great sentence". The user wants the revision and the reasoning, not affirmation.

## Examples

### Example 1: Basic technical sentence

**Input:**
> Whereas the topologies of both cases are the same, the transient flame dynamics are different. In the case of donut-shaped flame, a hole opened in the center of a disk-shaped flame, and the hole grows.

**校閲案:**

> Although both cases share the same topology, the transient flame dynamics differ. In the donut-shaped case, a hole opens at the center of the disk-shaped flame and expands.

**主な変更点:**

- `Whereas` → `Although`：科学技術文章では "Although" の方が一般的
- `topologies of both cases are the same` → `both cases share the same topology`：簡潔化
- `are different` → `differ`：簡潔化
- `In the case of donut-shaped flame` → `In the donut-shaped case`：冠詞不足の解消と簡潔化
- `a hole opened ... and the hole grows`：時制の不整合（過去形→現在形）を現在形に統一し、`the hole` の繰り返しを `and expands` に置換
- `a disk-shaped flame` → `the disk-shaped flame`：特定の対象を指すため定冠詞

### Example 2: Logical issue + grammar

**Input:**
> The flame radius is defined as the radius of a equivalent sphere whose volume occupies the y_f < 0.4 region.

**校閲案:**

> The flame radius is defined as the radius of an equivalent sphere whose volume corresponds to the region where y_f < 0.4.

**主な変更点:**

- `a equivalent` → `an equivalent`：母音前の冠詞
- `whose volume occupies the y_f < 0.4 region` → `whose volume corresponds to the region where y_f < 0.4`：原文は「球の体積が領域を占める」となり論理が逆。等価球の体積が当該領域の体積に「対応する」関係を明示

### Example 3: Missing variable, multiple changes

**Input:**
> Now, Fig. 7 depicts the iso surface of  to clarify the flame morphologies.

**校閲案:**

> Figure 7 now shows the iso-surface of [variable] to clarify the flame morphology.

**主な変更点:**

- `Now, Fig. 7 depicts` → `Figure 7 now shows`：文頭の `Now,` は口語的。`now` を副詞として動詞前に置くと「現在は〜になっている」というニュアンスが自然に出る。文頭の `Figure` はスペルアウトが標準
- `iso surface` → `iso-surface`（または `isosurface`）：複合語としてハイフン
- `flame morphologies` → `flame morphology`：単一の図で形態を明らかにする場合、不可算的に単数が自然

なお、`of` の後の変数名が抜けています（`of  to clarify`）。原稿では具体的な変数を補ってください。

### Example 4: Multi-sentence input with inconsistencies (表記ゆれ)

**Input:**
> The flame ball radius δ is determined by the heat loss parameter. The flame-ball thickness ℓ scales with the thermal diffusivity. We computed the iso surface of temperature, and the isosurface area was integrated over time.

**校閲案:**

> The flame-ball radius δ is determined by the heat-loss parameter. The flame-ball thickness ℓ scales with the thermal diffusivity. We computed the iso-surface of temperature, and the iso-surface area was integrated over time.

**主な変更点:**

- 1文目: `flame ball radius` → `flame-ball radius`：複合修飾語のハイフン（2文目の `flame-ball thickness` と整合）
- 1文目: `heat loss parameter` → `heat-loss parameter`：同様に複合修飾語のハイフン
- 3文目: `iso surface` / `isosurface` → `iso-surface` に統一

**表記の整合性:**

- `flame ball` vs. `flame-ball`：1文目はハイフンなし、2文目はハイフン付き。修飾語として後続名詞を限定する場合（例: `flame-ball radius`）はハイフンが標準。原稿全体で `flame-ball` に統一を推奨
- `iso surface` vs. `isosurface`：3文目内で同一概念に2通りの表記。`iso-surface` または `isosurface` のいずれかに統一を推奨（同分野では `iso-surface` がやや優勢）
- `δ` と `ℓ` は異なる量を指す前提で残しています。もし同一量を表す意図であれば、片方に統一してください
