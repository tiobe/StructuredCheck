# Findings from testing against real-world ST code

`community_samples.txt` (see `SOURCES.md` for provenance) surfaced four
grammar gaps beyond the tree-sitter conflict fixes. This documents each one:
the failing example, the root cause, and a recommended fix. No grammar
changes have been made for these yet - this is a decision record to act on.

## 1. Mandatory `;` after constructs that already end in a closing keyword

**Fails today:**

```
TYPE
	FLOAT_ARRAY_STATISTICS : STRUCT
		count : UDINT;
	END_STRUCT
END_TYPE
```

**Root cause:** `data_types.bnf:132`

```
data_type_declaration -> 'TYPE' (type_declaration ';')+ 'END_TYPE'
```

and `st.bnf:102`

```
statement_list -> (statement? ';')+
```

Both require a trailing `;` after *every* element, with no exception for one
that already ends in its own closing keyword (`END_STRUCT`, `END_IF`,
`END_FOR`, `END_WHILE`, `END_CASE`, ...). Two of the six corpus samples hit
this: the struct `TYPE` (`END_STRUCT` directly followed by `END_TYPE`, no
`;`) and `utTestReporter` (`END_IF` directly followed by the next `IF`, no
`;`). Neither is a corpus mistake - both source files consistently omit the
`;` in this position.

**Recommended fix:** make the separator optional specifically after
block-terminated alternatives, rather than loosening the rule everywhere
(which would also silently accept `42   ;;;;   43` as a valid decimal
literal - not the intent). Concretely, split `statement` into "the
alternatives that end in their own keyword" (`selection_statement`,
`iteration_statement`, `case_statement`, ...) and "the ones that don't"
(`assignment_statement`, `subprogram_control_statement`, ...), and only
require `;` after the latter:

```
statement_list -> (_terminated_statement | _self_terminated_statement ';'?)*
```

(exact rule split needs a look at every `statement` alternative; sketch only)
Same idea for `type_declaration ';'` in `data_type_declaration` - only
`single_element_type_declaration`/`type_name_reference` (bare `identifier
[:= ...]`, no closing keyword of their own) strictly need the `;`;
`array_type_declaration`/`structure_type_declaration`/`string_type_declaration`
already end in `END_STRUCT` or a length suffix and could make it optional the
same way.

**Rationale:** this matches both real-world samples without becoming lenient
about the cases where `;` is the *only* thing separating two statements
(e.g. two bare assignments) - dropping it there would be a real ambiguity
risk, not just a style relaxation.

## 2. `enumerated_value` requires a mandatory `TypeName#` qualifier

**Fails today:**

```
TYPE
	BINARY_ENCODING : (BASE64, BASE64_URL);
END_TYPE
```

**Root cause:** `data_types.bnf:178`

```
enumerated_value -> ((identifier => enumerated_type_name) '#') identifier
```

The `identifier '#'` qualifier prefix is not wrapped in `(...)?` - it's
mandatory. That's backwards for the most common case: when *declaring* an
enum's own value list (`enumerated_specification -> '(' enumerated_value
(',' enumerated_value)* ')'`, `data_types.bnf:170`), the values are bare
identifiers - `TypeName#Value` qualification is for *using* an enum value
elsewhere (disambiguating which enum a shared value name belongs to), not for
defining the list in the first place.

**Recommended fix:**

```
enumerated_value -> ((identifier => enumerated_type_name) '#')? identifier
		  ;
```

**Rationale:** every real enum declaration in the corpus (and every IEC
example this reviewer is aware of) writes the value list as bare
identifiers. Making the qualifier optional doesn't lose the ability to parse
`TypeName#Value` where it's meaningful (`enumerated_value` is also reachable
from `_type_name_reference_init`/`array_initial_element` etc., where
qualification matters more), it just stops rejecting the declaration form.

## 3. `STRING[n]` not accepted as a general type name

**Fails today:**

```
FUNCTION CONCAT3 : STRING[254]
	VAR_INPUT
		in1 : STRING[254];
	END_VAR
	CONCAT3 := in1;
END_FUNCTION
```

(fails on the `: STRING[254]` return type specifically; `in1 : STRING[254]`
inside `VAR_INPUT` is fine)

**Root cause:** `data_types.bnf:23` / `variables.bnf:220`

```
elementary_type_name -> numeric_type_name | date_type_name
		      | bit_string_type_name | /W?STRING/ | 'TIME'
		      ;

single_byte_string_spec -> 'STRING' ('[' integer ']')? (':=' single_byte_character_string)?
			 ;
```

The `[length]` suffix only exists on `single_byte_string_spec` /
`double_byte_string_spec`, which are reachable from a `VAR` declaration's
`_var1_init_decl`/`located_var_spec_init`, but *not* from
`_function_type_name` (`pou.bnf:29`, `elementary_type_name | type_name`) or
`simple_specification` (`data_types.bnf:153`, `-> elementary_type_name`
alone). Anywhere a `STRING`/`WSTRING` needs a length and isn't going through
one of the two `*_string_spec` rules, it can't have one.

**Recommended fix:** thread the optional length onto `elementary_type_name`'s
`/W?STRING/` alternative directly (or a wrapper rule used in its place),
since the type name and its length aren't really separable concepts:

```
elementary_type_name -> numeric_type_name | date_type_name
		      | bit_string_type_name
		      | /W?STRING/ ('[' integer ']')?
		      | 'TIME'
		      ;
```

then drop the now-redundant `('[' integer ']')?` from
`single_byte_string_spec`/`double_byte_string_spec`, which would just be
`elementary_type_name (':=' ...)?` at that point - worth checking whether
those two rules collapse into `simple_spec_init` entirely once this lands,
rather than leaving a parallel path.

**Rationale:** a return type, an input, and a plain variable are all "a type
name" in the same sense; there's no reason the length suffix should only be
reachable from one of the three paths that all eventually mean "this is a
`STRING`".

## 4. `_function_decls` is single-occurrence and has no `VAR_TEMP`

**Fails today:**

```
FUNCTION STRING_STARTSWITH : BOOL
	VAR_INPUT
		in1 : STRING[254];
	END_VAR
	VAR_TEMP
		in1_len : INT;
	END_VAR
	STRING_STARTSWITH := TRUE;
END_FUNCTION
```

**Root cause:** `pou.bnf:19,33`

```
function_declaration -> 'FUNCTION' derived_function_name ':' _function_type_name? _function_decls function_body 'END_FUNCTION'
		      ;

_function_decls -> io_var_declarations
		 | function_var_decls
		 ;
```

Two separate problems: (a) `_function_decls` appears exactly once in
`function_declaration` - a function can have only *one* declarations block
total, when `VAR_INPUT`, `VAR_OUTPUT`, `VAR_IN_OUT`, and a temp/local block
are all ordinarily present together; (b) `function_var_decls -> 'VAR'
'CONSTANT'? ...` covers `VAR [CONSTANT] ... END_VAR`, but there's no
alternative covering `VAR_TEMP ... END_VAR` for functions - `temp_var_decls`
(`pou.bnf:109`) exists but is only wired into `other_var_declarations`, which
`_program_decls` (programs) uses, not `_function_decls` (functions).

**Recommended fix:**

```
_function_decls -> (io_var_declarations | function_var_decls | temp_var_decls)*
		 ;
```

**Rationale:** matches how `_program_decls`/`other_var_declarations`
already handle repeated, mixed declaration blocks for `PROGRAM` and
`FUNCTION_BLOCK` - `FUNCTION` was the odd one out. Also brings the grammar in
line with the standard's own `+`/`*` cardinality on `io_var_declarations` in
the formal function-declaration production (a function needs at least one
input in practice, even though nothing here enforces that semantically - see
the existing `FIXME: NOTE 1` comment at `pou.bnf:57`).

## Suggested order

(2) and (4) are narrow, low-risk, single-rule changes. (3) touches a
lexical-ish rule used in a few places, worth a `make test` pass after. (1) is
the most involved - it changes cardinality/structure rather than adding an
alternative, and is worth doing last so the corpus can catch any fallout from
the other three first.
