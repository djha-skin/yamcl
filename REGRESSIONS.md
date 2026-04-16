# REGRESSIONS.md

This file tracks issues with the current implementation that need to be fixed.

## REGR-001: API - Streams Only (No String Arguments)

**Status**: TODO

`parse-from` and `generate-to` currently take strings as arguments. They should
take streams instead. Users can wrap with `with-input-from-string` /
`with-output-to-string` for convenience.

**Reference**: NRDL `../nrdl/cl/main.lisp` uses this pattern.

**Changes Required**:
1. Change `parse-from` to take a stream
2. Change `generate-to` to take a stream
3. Add `parse-from-string` wrapper using `with-input-from-string`
4. Add `generate-to-string` wrapper using `with-output-to-string`

---

## REGR-002: null vs false Distinction

**Status**: TODO

Currently `parse-from` parses both `false` and `null` into CL's `nil`, making
them indistinguishable. We want jzon-like behavior:

- `false` → CL's `nil`
- `null` → `cl:null` (out-of-band symbol)
- `~` → `cl:null` (YAML null shorthand)

**Reference**: NRDL uses `convert-to-symbol` pattern.

**Changes Required**:
1. Modify `parse-boolean` to return `nil` for `false`
2. Modify `parse-null` to return `cl:null`
3. Update tests to verify distinction

---

## REGR-003: Escape Sequences in Parsing

**Status**: TODO

String parsing doesn't handle JSON escape sequences per RFC 8259 Section 7.

**Required escapes**:
- `\\` → `\`
- `\"` → `"`
- `\/` → `/`
- `\b` → Backspace
- `\f` → Form Feed
- `\n` → Newline
- `\r` → Carriage Return
- `\t` → Tab
- `\uXXXX` → Unicode character (4 hex digits)

**Reference**: NRDL `extract-quoted` handles this.

**Changes Required**:
1. Modify `parse-string` to handle escape sequences
2. Add tests for escaped strings

---

## REGR-004: Escape Sequences in Generation

**Status**: TODO

String generation doesn't escape special characters per JSON rules.

**Characters to escape**:
- `"` → `\"`
- `\` → `\\`
- Control characters (0x00-0x1F) → `\uXXXX`

**Reference**: NRDL `inject-quoted` handles this.

**Changes Required**:
1. Modify `generate-scalar` to escape strings
2. Add tests for escaped string generation
