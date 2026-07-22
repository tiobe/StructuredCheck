# Provenance of tests/community_samples.txt

The test cases in `community_samples.txt` are small, complete excerpts of real,
human-written Structured Text taken from permissively-licensed open-source
repositories (not AI-generated), reformatted only to remove indentation that
came from a vendor-specific module wrapper the original files were nested in
(see below). Each is reproduced under the terms of the source project's MIT
license, which permits copying and redistribution provided the copyright
notice is retained - reproduced here:

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

## Coverage gap

No standalone `PROGRAM` or `CONFIGURATION` declaration is included - these
tend to be project-specific and IDE-scaffolded rather than published in
shared, reusable libraries, so they were hard to find as complete, hand-written,
permissively-licensed single-file examples.
