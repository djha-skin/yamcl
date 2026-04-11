# REGRESSIONS.md

This document tracks known issues and planned fixes for yamcl.

---

## REGR-001: API - Streams Only

**Status**: Pending

**Description**: `parse-from` and `generate-to` currently take string arguments.
They should take streams only, with helper functions `parse-from-string`
and `generate-to-string` wrapping them with `with-input-from-string` /
`with-output-to-string`.

**Reference**: NRDL `../nrdl/cl/main.lisp` - NRDL uses streams-only API.

**Tasks**:
- [ ] Change `parse-from` to accept a stream (not string)
- [ ] Change `generate-to` to accept a stream (not string)
- [ ] Create `parse-from-string` wrapper
- [ ] Create `generate-to-string` wrapper
- [ ] Update tests to use string wrappers

---

## REGR-002: null vs false Distinction

**Status**: Pending

**Description**: `parse-from` currently parses both YAML `false` and `null`
into CL's `nil`. They should be distinguishable.

**Behavior**:
- `null` (YAML) → `cl:null` (out-of-band symbol)
- `false` (YAML) → `nil` (CL's nil)

**Reference**: NRDL `convert-to-symbol` function.

**Tasks**:
- [ ] Update `parse-boolean` to return `cl:null` for null
- [ ] Update `parse-null` to return `cl:null`
- [ ] Update tests to verify distinction
- [ ] Document this in code

---

## REGR-003: Escape Sequences in Parsing

**Status**: Pending

**Description**: String parsing does not handle backslash escape sequences.

**Required escapes** (per RFC 8259 Section 7):
- `\\` → `\`
- `\"` → `"`
- `\/` → `/`
- `\b` → Backspace (character 8)
- `\f` → Form feed (character 12)
- `\n` → Newline
- `\r` → Carriage return
- `\t` → Tab
- `\uXXXX` → Unicode character

**Reference**: NRDL `extract-quoted` function.

**Tasks**:
- [ ] Implement escape sequence handling in string parsing
- [ ] Handle `\uXXXX` 4-digit hex escapes
- [ ] Handle `\uXXXX\uYYYY` surrogate pairs if needed
- [ ] Add tests for all escape sequences

---

## REGR-004: Escape Sequences in Generation

**Status**: Pending

**Description**: `generate-to` does not escape strings in output.

**Required escapes**:
- `\` → `\\`
- `"` → `\"`
- Newline → `\n`
- Tab → `\t`
- Carriage return → `\r`
- Form feed → `\f`
- Backspace → `\b`
- Unprintable chars → `\uXXXX`

**Reference**: NRDL `inject-quoted` function.

**Tasks**:
- [ ] Implement escape sequence handling in generation
- [ ] Handle unprintable characters with `\uXXXX`
- [ ] Add tests for round-trip escaping

---

## Implementation Notes

### cl:null vs nil

- `cl:null` is an out-of-band symbol with no special meaning in Common
  Lisp. It exists solely to distinguish YAML null from YAML false.
- CL's `nil` represents both CL's false and CL's null (absence of value).
  In our YAML parsing, `nil` represents YAML's `false` boolean.
- This is consistent with NRDL's approach.

### Stream-based API

The YAML library takes a stream-based approach for consistency and
flexibility. Users can wrap with:

```lisp
;; Parsing
(parse-from-string "hello: world")
;; Equivalent to:
(let ((stream (make-string-input-stream "hello: world")))
  (parse-from stream))

;; Generation
(generate-to-string '("hello" . "world"))
;; Equivalent to:
(with-output-to-string (stream)
  (generate-to stream '("hello" . "world")))
```
