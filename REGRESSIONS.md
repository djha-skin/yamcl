# REGRESSIONS.md

Known issues to fix for yamcl JSON scalar support.

## Issue 1: false and null are indistinguishable

**Status**: OPEN  
**Severity**: High  
**Description**: `parse-from` parses both `false` and `null` into CL's `nil`, making them indistinguishable.

**Expected behavior** (per jzon/nrdl design):
- `null` → `cl:null` (out-of-band symbol)
- `false` → `nil` (CL nil)
- `true` → `t` (CL t)
- `~` → `cl:null`

**Reference**: nrdl's `convert-to-symbol` function

---

## Issue 2: JSON String Escape Sequences Not Handled

**Status**: OPEN  
**Severity**: High  
**Description**: `parse-string` does not handle JSON escape sequences as per RFC 8259 section 7.

**Expected escapes** (per RFC 8259):
- `\"` → `"`
- `\\` → `\`
- `\/` → `/`
- `\b` → Backspace
- `\f` → Page
- `\n` → Newline
- `\r` → Return
- `\t` → Tab
- `\uXXXX` → Unicode character

**Reference**: nrdl's `extract-quoted` function, RFC 8259

---

## Issue 3: parse-from and generate-to take strings instead of streams

**Status**: OPEN  
**Severity**: Medium  
**Description**: Current API takes strings directly. Should take streams with wrapper functions.

**Expected API**:
- `parse-from` → takes streams (file-stream, string-stream, etc.)
- `generate-to` → takes streams
- `parse-from-string` → wrapper using `with-input-from-string`
- `generate-to-string` → wrapper using `with-output-to-string`

**Reference**: nrdl's API design

---

## Issue 4: generate-to does not handle cl:null

**Status**: OPEN  
**Severity**: Medium  
**Description**: When generating YAML/JSON, `generate-to` should convert `cl:null` back to `null`.

**Expected behavior**:
- `nil` → `false`
- `cl:null` → `null`
- `t` → `true`

**Reference**: nrdl's `inject-symbol` function

---

## Completion Checklist

- [ ] Issue 1: Distinguish false vs null
- [ ] Issue 2: JSON string escape sequences
- [ ] Issue 3: Stream-based API
- [ ] Issue 4: generate-to handles cl:null
