# kokko-learning

Study and recall aids: generate Anki flashcard JSON for the
[BulkCardCreator](https://github.com/Ifiora-Timothy/BulkCardCreator-anki-addon)
add-on, with a prose description of a concept on the front and the
concept's name on the back.

```bash
/plugin install kokko-learning@kokko-ng-kokko-cmds
```

## Skills

| Skill | Purpose |
| ----- | ------- |
| `anki-concept-cards` | Generate flashcard JSON in the BulkCardCreator format — description on the front, concept name on the back |

The craft is in the description: it has to identify one concept
unambiguously without leaking its name, its morphological variants, its
acronym expansion, or the eponym inside it. The skill carries the
non-leakage rules, worked examples, and a per-card self-check.

Triggers on Anki, BulkCardCreator, or any "definition on front, term on
back" request — including a bare list of terms with "make me study cards".
