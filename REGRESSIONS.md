# REGRESSIONS.md - yamcl

This document tracks known issues and regressions to fix before considering
the initial implementation complete.

## REGR-001: API - Streams Only (No String Arguments)

**Status**: Pending

**Problem**: `parse-from` and `generate-to` currently accept strings as
arguments, which is not the ideal API design.

**Desired Behavior**:
- `parse-from` and `generate-to` should accept only streams
- Users should use `with-input-from-string` / `with-output-to-string` wrappers
- Reference: NRDL `../nrdl/cl/main.lisp` does this correctly

**Helper Functions to Add**:
- `parse-from-string` - wraps `parse-from` with string input
- `generate-to-string` - wraps `generate-to` with string output

## REGR-002: null vs false Distinction

**Status**: Pending

**Problem**: `parse-from` parses both `false` and `null` into CL's `nil`,
making them indistinguishable.

**Desired Behavior** (jzon-like):
- `true` → `t` (CL's boolean true)
- `false` → `nil` (CL's boolean false)
- `null` → `cl:null` (out-of-band symbol, per NRDL design)

**Reference**: NRDL `convert-to-symbol` function handles this:
```lisp
((string= final-string "false") nil)
((string= final-string "null") 'cl:null)
```

## REGR-003: Escape Sequences in String Parsing

**Status**: Pending

**Problem**: String parsing does not handle backslash escape sequences.

**Required Escapes** (per RFC 8259 Section 7):
- `\"` → `"`
- `\\` → `\`
- `\/` → `/`
- `\b` → Backspace (code 8)
- `\f` → Form feed (code 12)
- `\n` → Newline
- `\r` → Carriage return
- `\t` → Tab
- `\uXXXX` → Unicode character

**Reference**: NRDL `extract-quoted` handles these escapes.

## REGR-004: Escape Sequences in String Generation

**Status**: Pending

**Problem**: `generate-to` does not escape special characters in strings.

**Required Escapes**:
- `"` → `\"`
- `\` → `\\`
- Newline → `\n`
- Tab → `\t`
- Carriage return → `\r`
- Backspace → `\b`
- Form feed → `\f`
- Unprintable characters → `\uXXXX`

**Reference**: NRDL `inject-quoted` handles this with `*escape-characters*`.

## REGR-005: Tests for JSON Scalar Edge Cases

**Status**: Pending

**Problem**: Tests do not cover escape sequences or null/false distinction.

**Required Tests**:
- [ ] Parse `"hello\nworld"` → string with embedded newline
- [ ] Parse `"quote\"escape"` → string with embedded quote
- [ ] Parse `"path\\to\\file"` → string with embedded backslashes
- [ ] Parse `"tab\there"` → string with embedded tab
- [ ] Parse `"crlf\r\n"` → string with CR LF
- [ ] Parse `"backspace\b"` → string with backspace char
- [ ] Parse `"ff\f"` → string with form feed
- [ ] Parse `"null"` → `cl:null`
- [ ] Parse `"false"` → `nil`
- [ ] Parse `"true"` → `t`
- [ ] Generate `nil` → `"false"`
- [ ] Generate `cl:null` → `"null"`
- [ ] Generate string with newline → `"hello\nworld"`
