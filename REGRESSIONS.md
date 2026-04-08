# REGRESSIONS.md

Known issues and required fixes for yamcl.

## Open Issues

### 1. String escape tests fail due to `format` limitations
**Severity**: Test Defect
**Status**: Open

Tests using `format` with `~%` produce incorrect output for certain escape sequences.
The `parse-string` implementation is correct; tests need to use literal character constants.

### 2. Tab character tests fail
**Severity**: Test Defect
**Status**: Open

The test for `\t` (tab) uses `format` which doesn't produce correct tab characters.
Need to use literal `#\Tab` character constant instead.

## Completed Fixes

### Issue #4: `generate-to` is a placeholder
**Fixed**: Implemented proper scalar serialization
- `nil` → `"false"`
- `+null+` → `"null"`
- `t` → `"true"`
- numbers → `prin1` output
- strings → double-quoted with escapes

### Issue #3: API takes strings instead of streams
**Fixed**: API redesigned per NRDL pattern
- `parse-from` takes a stream
- `generate-to` takes a stream
- `parse-from-string` wrapper added
- `generate-to-string` wrapper added

### Issue #2: String escape sequences not fully implemented
**Fixed**: All RFC 8259 Section 7 escapes implemented
- `\"` → `"`
- `\\` → `\\`
- `\/` → `/`
- `\b` → backspace (code-char 8)
- `\f` → form feed (code-char 12)
- `\n` → newline
- `\r` → carriage return
- `\t` → tab
- `\uXXXX` → Unicode character

### Issue #1: `parse-from` conflates `false` and `null`
**Fixed**: Distinction now preserved
- `false` → CL's `nil` (falsy)
- `null` / `~` → `+null+` sentinel (truthy)
