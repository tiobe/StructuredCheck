# Plan: make ';' optional after END_xxx-terminated constructs

Approved by Paul (2026-07-27): the grammar should stop requiring a `;`
after constructs that already end in their own closing keyword
(`END_STRUCT`, `END_IF`, `END_FOR`, `END_WHILE`, `END_CASE`,
`END_REPEAT`), to match common real-world PLC tooling. This reverses the
"require it, strict-to-standard" call recorded in project memory
(`grammar_optional_struct_semicolon.md`) and in `tests/FINDINGS.md` #1.

## Scope

Only constructs that end in their own `END_*` keyword. Everything else
keeps a mandatory `;` - it's the only thing separating two of them
syntactically (e.g. two bare assignments, or `RETURN` followed by
another statement).

**In scope:**
- `structure_type_declaration` (`... : STRUCT ... END_STRUCT`)
- `if_statement` (`END_IF`)
- `case_statement` (`END_CASE`)
- `for_statement` (`END_FOR`)
- `while_statement` (`END_WHILE`)
- `repeat_statement` (`END_REPEAT`)

**Out of scope** (keep mandatory `;`):
- `single_element_type_declaration`, `array_type_declaration`,
  `string_type_declaration`, `type_name_reference` (data type decls that
  don't end in a keyword)
- `assignment_statement`, `subprogram_control_statement` (incl. bare
  `RETURN`)

## Work items

1. **`grammar/data_types.bnf`** - split `data_type_declaration`'s
   `(type_declaration ';')+` into two paths, one requiring `;`, one
   making it optional:
   ```
   data_type_declaration -> 'TYPE' (_terminated_type_decl ';'? | _plain_type_decl ';')+ 'END_TYPE'
   _terminated_type_decl -> structure_type_declaration
   _plain_type_decl -> single_element_type_declaration
                     | array_type_declaration
                     | string_type_declaration
                     | type_name_reference
   ```
   (`type_declaration` itself may need to stay as an alias for anything
   still referencing it elsewhere - check call sites before removing it.)

2. **`grammar/st.bnf`** - same split for `statement_list`:
   ```
   statement_list -> (_terminated_statement ';'? | _plain_statement ';')+
   _terminated_statement -> selection_statement | iteration_statement
   _plain_statement -> assignment_statement | subprogram_control_statement
   ```
   Check whether the existing bare-`;` empty-statement allowance
   (`statement?` in the current rule) needs preserving, and whether the
   existing `%conflicts [statement_list]` (for the case_element/
   enumerated_value ambiguity) still applies once the rule shape changes.

3. **Regenerate and check for new conflicts** - `make grammar`, watch for
   anything ts-bnf-tool flags, particularly around `_terminated_statement`
   vs. whatever currently disambiguates `case_element`.

4. **Add missing coverage** - the current corpus
   (`tests/community_samples.txt`) only exercises this for `END_STRUCT`,
   `END_IF`, `END_FOR`. Nothing exercises `END_CASE`, `END_WHILE`, or
   `END_REPEAT` with an omitted `;`, in either the corpus or anywhere
   else. Add corpus/synthetic cases (or find real-world samples) for
   those three before calling this done, both with and without the
   trailing `;`, to confirm the optional form works and the mandatory
   one didn't regress.

5. **Consider reverting the earlier corpus adaptations** - "Structure
   type" and "Function block with FOR loop..." had their `;` added back
   in specifically to satisfy the old strict requirement. Once the
   grammar accepts both forms, it may be worth reverting those two
   samples to their original (semicolon-less) real-world form, since
   that's now equally valid and more faithful to the original source -
   not required, since the grammar will accept either.

6. **Update the paper trail**:
   - `tests/FINDINGS.md` #1: mark resolved, note the actual fix (not the
     original sketch verbatim - update to match whatever shape the rules
     end up taking).
   - `tests/SOURCES.md`: update or remove the "Missing `;` after
     block-terminated constructs" adaptation entry if item 5 above is
     done (samples no longer need adapting for this reason).
   - Project memory `grammar_optional_struct_semicolon.md`: flip from
     "decided: require it" to "decided: optional, approved by Paul
     2026-07-27" - this is a reversal of a previously-recorded decision,
     not a new open question.

7. **Full regression** - `make test` (and `make check`) after all of the
   above; confirm no prior passing sample stopped parsing.
