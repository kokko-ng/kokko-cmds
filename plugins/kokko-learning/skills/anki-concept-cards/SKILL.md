---
name: anki-concept-cards
description: Generate JSON files of flashcards in the format required by the BulkCardCreator Anki add-on (Ifiora-Timothy/BulkCardCreator-anki-addon). Use whenever the user wants to memorize the NAMES of concepts — the front of each card is a prose description of the concept and the back is the concept's name. Trigger this skill whenever the user mentions Anki, BulkCardCreator, "bulk card creator", flashcards for memorizing terminology/jargon/vocabulary, or asks for cards in a "describe-the-concept, name-it" / "definition on front, term on back" format. Also trigger when the user supplies a list of terms or concepts and asks for study cards, an Anki import file, or a JSON of flashcards — even if they don't say "Anki" explicitly.
---

# Anki Concept Cards (BulkCardCreator JSON)

Generate JSON files for the BulkCardCreator Anki add-on (<https://github.com/Ifiora-Timothy/BulkCardCreator-anki-addon>) where the **front** is a prose description of a concept and the **back** is the concept's **name**. The user is memorizing names from descriptions, so the central craft of this skill is writing descriptions that uniquely identify a concept *without leaking the name*.

---

## Output format

The add-on requires a JSON array of flat objects. Each object's keys must exactly match the field names of the Anki note type the user is importing into. Default to Anki's built-in **Basic** note type (`Front` / `Back`) unless the user specifies otherwise.

```json
[
  { "Front": "<description of concept 1>", "Back": "<name of concept 1>" },
  { "Front": "<description of concept 2>", "Back": "<name of concept 2>" }
]
```

Format rules:

- The top level must be a JSON array.
- Each card is a flat object — no nesting.
- Keys must be identical across every object in the file.
- Save the file with a `.json` extension as `<descriptive-name>.json`. Write it where the user asked; with no location given, use the current working directory. Do not scatter card files into a repo the user is working in without saying where you put it.

If the user mentions a non-Basic note type or names custom fields (e.g. `Question`/`Answer`, `Definition`/`Term`), use those exact field names instead of `Front`/`Back`. Field names are case-sensitive.

---

## Writing the description (front of card)

The description's job is to evoke the concept in the user's mind so they can produce its name. Two properties matter:

1. **Distinctive** — someone who understands the concept can name it from the description alone, without ambiguity. The description should pick out one concept, not a family of related ones.
2. **Non-leaky** — the description does not contain the name itself or surface-level cues that let the user guess the answer by pattern-matching instead of by understanding.

Aim for one to four sentences of natural prose. Describe what the concept *is* and what makes it distinctive — its role, mechanism, function, or the situations it applies to. Test understanding, not trivia: a description like "the theory proposed in 1859 by an English naturalist" is a worse card than one that captures the *idea* of the theory.

### Write a concept, not a list

Use flowing prose, not bullet points or numbered properties. If the description reads like "It is X. It does Y. It has Z." or like a glossary stub, rewrite it. Prefer one synthetic sentence that captures the concept's essence over three brittle sentences enumerating features.

### Non-leakage rules

The description must NOT contain:

1. **The concept's name in any form.** If the back is "Photosynthesis", the front cannot contain "photosynthesis."
2. **Morphological variants of any word in the name.** Stem-match: for a back of "Encryption", also avoid "encrypt", "encrypted", "encrypting." For "Refactoring", avoid "refactor", "refactored", "refactors." For "Inflation", avoid "inflate", "inflationary."
3. **Acronym letters or their expansion.** If the back is "TCP", do not write "transmission control protocol." If it's "DNS", avoid both "DNS" and any phrase that spells out a plausible expansion ("domain name system", "domain name service"). If the back is the spelled-out form ("Random Access Memory"), do not write the acronym ("RAM") anywhere.
4. **Eponyms inside the name.** For "Bayes' theorem", the front cannot say "Bayes" or "Bayesian." For "Pythagorean theorem", avoid "Pythagoras" and "Pythagorean." For "Occam's razor", avoid "Occam."
5. **Direct translation of a foreign-language name.** For "Schadenfreude", avoid the gloss "joy at others' misfortune" — describe the affect, the situations, or the cultural context instead. (If the concept genuinely has no description that doesn't translate the name, flag it to the user rather than silently leaking.)
6. **Trivial-rename synonyms.** For "the Big Bang", "the explosive beginning of the universe" is just a paraphrase of the name — describe what the theory actually claims instead. For "Survival of the Fittest", "the survival of the most well-adapted" is the same trick.

Common stopwords (a, an, the, of, in, and, to, for, by, etc.) and generic linking verbs (is, has, does) are fine even when they appear inside multi-word names.

### Self-check before writing each card to JSON

Run this mental check on every front/back pair:

1. Lowercase both the front and the back.
2. For each content word (non-stopword) in the back, confirm no word in the front shares its stem.
3. If the back is or contains an acronym, scan the front for both the letters and any plausible spelled-out expansion.
4. If the back contains a person's name, confirm the surname does not appear in the front.
5. Confirm the description is prose, not an enumerated list.
6. Confirm the description picks out the concept uniquely — would a knowledgeable reader name something else from this front? If so, sharpen it.

If any check fails, rewrite the front and re-check. Don't ship a leaky card.

---

## Examples

### Back: Photosynthesis

- Leaky: "The process of photosynthesis used by green plants." *(contains the name)*
- Leaky: "Plants use light to make food in a photosynthetic reaction." *(morphological variant)*
- Clean: "Green organisms convert light energy into chemical energy stored in sugar, drawing carbon dioxide from the air and releasing oxygen as a byproduct. It happens primarily in chloroplasts and underpins almost all life on Earth."

### Back: TCP

- Leaky: "A transmission control protocol used on the internet." *(spells out the acronym)*
- Leaky: "Network protocol where T, C, and P stand for the layers of reliable delivery." *(letters)*
- Clean: "A connection-oriented network protocol that guarantees reliable, in-order delivery of bytes between two hosts by breaking data into segments, acknowledging receipt, and retransmitting anything lost. Pairs with IP at the transport layer."

### Back: Bayes' theorem

- Leaky: "The Bayesian rule for updating probabilities." *(eponym + variant)*
- Clean: "A formula that tells you how to revise your belief in a hypothesis after seeing new evidence, by combining the prior probability of the hypothesis with the likelihood of the evidence under that hypothesis. Foundational to a whole school of statistical inference."

### Back: Schadenfreude

- Leaky: "German word for joy at others' misfortune." *(literal translation of the name)*
- Clean: "The small, somewhat shameful pleasure a person feels when someone they dislike — a rival, or someone they envy — suffers a setback. The word comes from German and has no clean single-word English equivalent."

### Back: Refactoring

- Leaky: "The act of refactoring messy code." *(name)*
- Leaky: "When you refactor code to clean it up." *(morphological variant)*
- Clean: "Restructuring existing source code to improve its internal design — readability, modularity, ease of change — without altering its external behavior. Tests stay green; the program does the same thing, just more clearly."

---

## Workflow

1. **Gather the concepts.** Either the user provides a list directly, or they ask for cards on a topic. If the topic is broad, briefly agree on scope and rough count before generating (e.g., "core data-structure terms, ~15 cards").
2. **Confirm field names** if the user mentioned a non-Basic note type. Otherwise default to `Front` and `Back`.
3. **Draft each card.** For each concept, write a prose description, then run the self-check from above. Rewrite anything that leaks.
4. **Assemble the JSON array.** Make sure it's valid JSON — verify with `jq . <file>` (or `python3 -m json.tool`) after writing, rather than eyeballing it. Escape any quotes inside descriptions and leave no trailing commas.
5. **Save and report.** Write to `<topic>-anki.json` (see the format rules above for where), then state the full path and how many cards are in the file.
6. **Briefly remind the user how to import**: in Anki, open *Tools → Bulk Card Creator*, set the deck and note type, switch to JSON mode, paste or load the file, click Validate JSON, then Create Cards.

For batches over ~50 cards, offer to split the file by sub-topic so the user can review and import in chunks.
