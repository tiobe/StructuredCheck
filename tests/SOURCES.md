# Provenance of tests/community_samples.txt

The test cases in `community_samples.txt` are small, complete excerpts of real,
human-written Structured Text taken from permissively-licensed open-source
repositories (not AI-generated), reformatted only to remove indentation that
came from a vendor-specific module wrapper the original files were nested in
(see below), and adapted in a few small, specific spots to follow IEC
61131-3:2003 where the original diverged from it (see "Standard-conformance
adaptations" below). Each is reproduced under the terms of the source
project's MIT license, which permits copying and redistribution provided the
copyright notice is retained - reproduced here:

## WengerAG/structured-text-utilities

<https://github.com/WengerAG/structured-text-utilities> - MIT License,
Copyright (c) 2019 Wenger Automation & Engineering AG, Winterthur, Switzerland.

Used for: "Enumerated type", "Structure type", "Function with nested call
expression", "Function with VAR_TEMP and IF/ELSE", "Function referencing a
derived type and calling another function".

Source files: `UTILITIES_BYTE.st`, `UTILITIES_MATH.st`, `UTILITIES_STRING.st`,
`UTILITIES_TIME.st`. In the original repository these declarations live inside
a B&R Automation Studio `UNIT ... INTERFACE ... IMPLEMENTATION ... END_UNIT`
module wrapper, which is a vendor-specific packaging construct, not part of
IEC 61131-3 itself; only the leading indentation from that wrapper was
stripped when extracting each declaration as a standalone top-level
`library_element_declaration`.

## tkucic/UniTest

<https://github.com/tkucic/UniTest> - MIT License, Copyright (c) 2021 Toni Kucic.

Used for: "Function block with FOR loop, array indexing and struct field
access" (`UniTest_br/UniTest/utTestReporter.st`).

Note: two other files from this repository (`assertEqual_BOOL.st`, a
`FUNCTION`, and `Library_tests/main/main.st`, a `PROGRAM`) were considered but
dropped - in B&R Automation Studio projects the signature/`VAR` block of a POU
is stored in a separate companion file the IDE manages, so on their own these
particular files are implementation-only and don't parse as complete,
standalone declarations. They were not "fixed" with invented `VAR` blocks,
since that would stop being real source.

## Standard-conformance adaptations

A few samples used constructs that are common in real-world PLC tooling but
that IEC 61131-3:2003's own grammar (and, for the semicolon cases, its own
worked examples - checked directly against the extracted standard text) does
not actually permit. Rather than relaxing the grammar to match vendor
practice, these specific spots were edited to match the standard instead:

- **"Function with nested call expression"**: the function's return type was
  `STRING[254]`; a sized string is not a legal `function_declaration` return
  type per B.1.5.1 (`elementary_type_name | derived_type_name` only - a bare
  `STRING` keyword or a type-alias identifier, never a size). Changed to a
  bare `STRING`.
- **Missing `;` after block-terminated constructs** - IEC 61131-3:2003
  requires a `;` after every `type_declaration` (B.1.3) and every
  `statement` (B.3.2), even ones that already end in their own closing
  keyword (`END_STRUCT`, `END_IF`, `END_FOR`, ...) - confirmed against
  nearly every worked example in the standard, which consistently write
  e.g. `END_STRUCT ;` and `END_FOR ;`. Two samples omitted it:
  - **"Structure type"**: no `;` between `END_STRUCT` and `END_TYPE`.
  - **"Function block with FOR loop, array indexing and struct field
    access"**: nested `IF...END_IF` and `FOR...END_FOR` statements not
    followed by a `;` before the next statement.
  Added the missing `;`s in both.

These are judgment calls, not the only possible resolution - an equally
valid alternative would have been to relax the grammar to accept the
originals as written, since both patterns are widely tolerated by real PLC
tooling (CODESYS, TwinCAT). That door isn't closed: these decisions are
recorded (with the standard-conformance evidence found for each) as
StructuredCheck project memory, to revisit if a strong enough reason comes
up to prioritize real-world leniency over strict standard conformance for
either of them.

## Coverage gap

No standalone `PROGRAM` or `CONFIGURATION` declaration is included - these
tend to be project-specific and IDE-scaffolded rather than published in
shared, reusable libraries, so they were hard to find as complete, hand-written,
permissively-licensed single-file examples.
