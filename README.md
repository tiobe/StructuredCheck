# StructuredCheck

A [tree-sitter](https://tree-sitter.github.io/tree-sitter/) grammar for IEC
61131-3 Structured Text (ST), the textual PLC programming language. The
grammar is hand-derived from the standard's Annex B formal BNF and converted
into a tree-sitter parser via a BNF-to-grammar.js toolchain (`ts-bnf-tool`),
rather than being written directly against tree-sitter's grammar DSL.

## Repository layout

```
grammar/    BNF source files, one per Annex B section (see below)
tests/      Corpus tests against real-world ST code, plus provenance/findings
build/      Generated tree-sitter parser (gitignored, produced by `make grammar`)
```

### Grammar files

`grammar/st.bnf` is the entry point; it `%include`s the rest and holds the
top-level declarations and statement grammar (Annex B.3.2). The others each
cover one section of Annex B:

| File                | Covers                                        |
|---------------------|------------------------------------------------|
| `literals.bnf`      | Numeric/string/time literals, comments          |
| `data_types.bnf`    | Elementary and derived data types (B.1.3)       |
| `variables.bnf`     | Variable declarations and references (B.1.4)    |
| `pou.bnf`           | Functions, function blocks, programs (B.1.5)    |
| `sfc.bnf`           | Sequential function chart elements (B.1.6)      |
| `configuration.bnf` | Resources, tasks, configurations (B.1.7)        |

## Prerequisites

- [`tree-sitter`](https://github.com/tree-sitter/tree-sitter) CLI
- `ts-bnf-tool`, on your `PATH`

## Building

```
make grammar   # generate the tree-sitter parser into build/tree-sitter-st
make check     # run ts-bnf-tool's static checks on the BNF source
```

## Testing

```
make test          # run tests/*.txt as tree-sitter corpus tests
make test-update   # same, then freeze any newly-correct parse trees back into tests/
```

Run `make` or `make help` for the full list of targets.

## Status

All corpus tests in `tests/community_samples.txt` (real, permissively-licensed
ST code, not synthetic) currently pass. A few samples needed small edits to
match the standard's own text where the original source used a construct
common in PLC tooling but not actually IEC 61131-3-conformant (e.g. a sized
string as a function return type); see `tests/SOURCES.md` for exactly what
was adapted and why, and `tests/FINDINGS.md` for the fuller list of grammar
gaps this corpus surfaced along the way.

## License

MIT - see `LICENSE`.
