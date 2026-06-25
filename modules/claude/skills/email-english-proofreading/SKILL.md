---
name: email-english-proofreading
description: Proofreads English emails — to colleagues, supervisors, collaborators, journal editors, administrative contacts, and other email recipients — to make them flow naturally with appropriate respect, register, and tone. Use this skill whenever the user asks for proofreading, polishing, or "校閲" of an email in English, including phrases like "check this email", "is this OK to send", "to my supervisor", "to a professor", "メール文として校閲して", or pastes a draft that opens with `Dear ...` / `Hi ...` / `Hello ...` and closes with `Best regards` / `Sincerely` / `Best`. Strongly prefer this skill over scientific-manuscript proofreading whenever the text is clearly an email, even when the topic is technical (e.g., a research email to a collaborator). Do NOT use this for manuscript prose, abstracts, response letters to reviewers, or other non-email document types.
---

# English Email Proofreading

Goal: revise the user's English email so it **(1) flows naturally, (2) conveys appropriate respect for the recipient, and (3) uses email-specific conventions** that distinguish it from manuscript prose.

The user is typically a non-native English speaker writing to senior academics, international collaborators, or administrative contacts. The job is to produce email that sounds like what a thoughtful, polite native English writer would send — without flattening the writer's voice.

## Output format

Use **Japanese** for explanations; keep the email itself in English.

```
**校閲案:**

> Dear ...,
> 
> [Revised email body. Preserve the user's paragraph breaks, or suggest splits if the original is one big block.]
> 
> Best regards,  
> [Name]

**主な変更点:**

- `original phrase` → `revised phrase`：reasoning
- (more bullets — typically 4–8 for a full email)

**確認事項:**（if needed）
- 論理ギャップ・意図不明の箇所など、書き手に確認してほしい点
```

The `確認事項` section is optional — include it only when there's a real ambiguity, missing context, or unverified intent that the user should resolve before sending.

When the email contains internal inconsistencies in how people, projects, or files are referenced, add:

```
**表記の整合性:**
- (note about an inconsistent reference, with a recommended unified form)
```

## How email proofreading differs from manuscript proofreading

Manuscript proofreading optimizes for **simplicity and unambiguous interpretation**. Email proofreading additionally optimizes for **register, rapport, and email-specific conventions**:

- **Greeting and sign-off matter, and they must match.**
  - `Dear Prof. Maruta,` → `Best regards, [Name]` or `Sincerely, [Name]`.
  - `Hi John,` → `Best,` or `Thanks,` (less formal sign-off OK).
  - Don't strip greetings or sign-offs even when shortening the body.
- **First-person reference in collaborator lists.**
  - In Japanese business email it is normal to refer to oneself by surname (`田中、山田、津田の3名で...`).
  - In English, this is unnatural; replace `... and Tsunoda are working on ...` with `... and I are working on ...`.
  - Exception: if the recipient is also Japanese and reading the surname-style is culturally fine, the user may keep it. Mention this option in the explanation.
- **Email-specific tense conventions.**
  - Attachments: `I have attached ...` (present perfect), not `I attached`.
  - Current state: `we are currently working on ...`, not `we work on`.
  - Soft proposals: `What would you think about ...?`, not the abrupt `What do you think about ...?`.
- **Concern expressions** — `concern` is a noun, not a verb in this register:
  - ❌ `we concern about X`
  - ✅ `our concern is X` / `we are concerned about X` / `our current concern is how to ...`
- **Politeness softeners.** Use `could`, `would`, `might` for proposals to a senior person. Avoid bare `can` / `will` in requests.
- **Paragraph breaks.** Short paragraphs (1–3 sentences) are easier to read on screen than dense blocks. If the user wrote one big paragraph, suggest splits.

## Editorial principles, in priority order

### 1. Match register to recipient

Identify the recipient relationship from the greeting and tailor the register accordingly:

| Recipient | Greeting | Register |
|---|---|---|
| Professor / senior collaborator / journal editor | `Dear Prof. X,` / `Dear Dr. X,` | Formal full sentences, polite softeners (`would`, `could`), full-name sign-off |
| Peer / regular collaborator | `Hi [Name],` / `Hello [Name],` | Less formal but still complete; contractions OK |
| Administrative contact | `Dear [Name],` or `Hello,` | Clear, direct, transactional; minimal small talk but keep courtesy |
| Unknown / cold outreach | `Dear Prof. X,` | Formal; introduce yourself in the first line |

### 2. Preserve the writer's voice

Don't make the email sound generic. If the user writes plainly, keep it plain; if they write warmly, keep the warmth. The job is to make the English natural, not to rewrite the personality.

### 3. Fix logical gaps

Email writers often skip context that's obvious to them but unclear to the reader. Common gaps to flag:

- References to "the latter case" / "the former" without prior mention in the email.
- Pronouns (`it`, `this`) without clear antecedents.
- "As we discussed" when the recipient may not remember which discussion.
- Implicit deadlines (`by next week` — which week?).

Put these in the `確認事項` section rather than guessing and silently rewriting.

### 4. Apply email conventions silently

Some conventions are non-negotiable and don't need a long explanation; just apply them:

- `I attached` → `I have attached` (no real explanation needed beyond "メール添付の慣用").
- Missing comma after `Dear Prof. Maruta`.
- Missing two-space line break before the signature (in plain text).
- Subject line capitalization (Title Case for formal, sentence case OK for casual).

### 5. Cultural awareness for Japanese ↔ English

- **Honorifics in mixed-Japanese contexts**: `〜sensei`, `〜kun`, `〜san` between Japanese colleagues writing in English are a common stylistic choice. Don't strip them automatically. If the recipient is non-Japanese, suggest English equivalents (`Prof. Akiba`, `Mr. Nishiyama`, or first names).
- **Apologetic openings**: heavily apologetic openings common in Japanese business writing (`I am very sorry for the late reply, please forgive my impoliteness...`) often translate awkwardly. Compress to `Thank you for your patience` or `My apologies for the delayed response`.
- **Excessive hedging**: phrases like `I think it might possibly be the case that perhaps we could maybe ...` should be tightened. One softener is enough.

### 6. Reference consistency (表記ゆれ)

Within a single email, the same person, project, file, or entity should be referenced the same way. Inconsistency confuses readers and can suggest carelessness. Check for and flag:

- **Same person, different forms**: e.g., switching between `Prof. Smith`, `John`, and `Dr. Smith` in one email without a deliberate reason. Pick one form (usually `Prof. Smith` for formal email, `John` once first-naming has been established) and stick with it.
- **Honorific inconsistency**: e.g., `Akiba-sensei` and `Akiba` mixed in the same email; `Mr. Nishiyama` and `Nishiyama-kun` mixed.
- **Same project/document, different names**: e.g., `the reply letter`, `the response`, `the rebuttal` for the same document.
- **File references**: if attaching multiple files, refer to them with the same naming pattern (`the manuscript` and `the reply letter`, not `the manuscript` and `the letter`).
- **Date and time formatting**: stick to one convention (`May 1, 2026` vs. `1 May 2026` vs. `2026-05-01`) within an email.

When a single short email is submitted, internal inconsistency may not be present. In that case, do not invent issues. Report findings under `**表記の整合性:**` only when a real inconsistency exists.

## When to ask before proofreading

Use `ask_user_input_v0` (or inline) when:

- The recipient relationship is genuinely unclear (greeting omitted, or `Dear Sir/Madam,` with no other clues), and the choice affects the whole register.
- Two interpretations of the writer's intent give very different revisions.
- A logical gap is severe enough that proofreading without clarification would produce a misleading email.

For minor ambiguities, proceed with the most plausible interpretation and put the question in `確認事項`.

## Things to avoid

- **Do not** flatten the writer's personality. Match what they're already doing in tone.
- **Do not** apply analogies/metaphors to explain choices (per user preference) unless asked.
- **Do not** add information the user didn't include (e.g., don't volunteer a deadline they didn't mention).
- **Do not** apply scientific-manuscript proofreading style to email content. Emails tolerate (and benefit from) some redundancy and warmth that manuscripts cut.
- **Do not** make every sentence formal-grade. If the original opens with `Hi Mike,` keep it casual throughout.
- **Do not** rewrite the user's name, title, or affiliation in the signature unless they explicitly ask.

## Examples

### Example 1: To a senior professor (supervisor)

**Input:**
> Dear Prof. Maruta,
> Akiba-sensei, Nishiyama-kun, and Tsunoda are working on revising our reply letter.
> I attached the revised draft of the letter and the submitted manuscript.
> Now, we concern about the justification of the choice of the two-dimensional coordinate.
> I would like to discuss the latter case.
> What do you think about attaching the ring-shaped flame obtained from 3D DTM code by Sagawa-kun?
> I think Sagawa-kun's core results can be comprehended by this manuscript.
> Best regards,

**校閲案:**

> Dear Prof. Maruta,
> 
> Akiba-sensei, Nishiyama-kun, and I are currently working on revising our reply letter. I have attached the revised draft of the letter along with the submitted manuscript.
> 
> Our current concern is how to justify the choice of the two-dimensional coordinate system. I would like to discuss the latter case with you.
> 
> Specifically, what would you think about including the ring-shaped flame obtained with Sagawa-kun's 3D DTM code? I believe his core results could be presented effectively within this manuscript.
> 
> Best regards,  
> [Your name]

**主な変更点:**

- `and Tsunoda` → `and I`：英語メールで自分を苗字で三人称的に呼ぶのは不自然（相手が日本人で慣行を理解していれば原文のままでも可）
- `I attached` → `I have attached`：メール添付の慣用は現在完了形
- `we concern about X` → `Our concern is X`：`concern` は名詞なので `we concern about` は文法誤り
- `the two-dimensional coordinate` → `the two-dimensional coordinate system`：座標系を指す場合は `system` を補う
- `What do you think about attaching` → `what would you think about including`：
  - `attaching` は「メールに添付する」のニュアンスで紛らわしい。原稿に組み込む意味なら `including` が明確
  - `would` で仮定法を入れると、提案を尋ねる柔らかいトーン
- `obtained from 3D DTM code by Sagawa-kun` → `obtained with Sagawa-kun's 3D DTM code`：所有関係を前置することで簡潔に。`from` → `with`（コードを「用いて」得たという関係）
- `can be comprehended by this manuscript` → `could be presented effectively within this manuscript`：
  - `comprehended by a manuscript` は不自然（原稿が理解する主体になってしまう）。意図は「この原稿の中で扱える/示せる」と解釈
  - `can` → `could`：提案のトーン

**確認事項:**

- 原文 `the latter case` の `latter` が指す対象が、このメール本文中に明示されていません。先生との以前のやり取りの続きであれば自然ですが、メール単独で意味が通るようにしたい場合は具体的に書き直すことを推奨します。

### Example 2: Casual peer email

**Input:**
> Hi Mike,
> Thanks for the data. I will check it tomorrow and let you know if everything is OK.
> Best,

**校閲案:**

> Hi Mike,
> 
> Thanks for the data — I'll go through it tomorrow and let you know how it looks.
> 
> Best,

**主な変更点:**

- `I will check` → `I'll go through`：カジュアルメールでは短縮形と動詞句 `go through` の方が自然
- `if everything is OK` → `how it looks`：`if everything is OK` はやや事務的。peer 間ではより自然な言い回し
- 段落の間に空行を追加：英語メールでは挨拶と本文の間に空行を入れるのが標準
