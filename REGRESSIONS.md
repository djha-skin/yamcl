# REGRESSIONS.md

Known issues and required fixes for yamcl.

## Open Issues

(None currently - all known issues resolved)

## Completed Fixes

### Issue: `generate-to` used wrong error type
**Fixed**: Created `generation-error` condition distinct from `extraction-error`
- `generate-to` now signals `generation-error` for unsupported types

### Issue: Special YAML floats (.inf, .nan) not parsed
**Fixed**: Implemented parsing of:
- `.inf`, `.Inf`, `.INF` → `:+inf` (positive infinity as keyword)
- `-.inf`, etc. → `:-inf` (negative infinity as keyword)
- `.nan`, `.NaN`, `.NAN` → `nan` (CL's NaN)

### Issue: Invalid numbers like `+.foo` partially parsed
**Fixed**: Added validation for decimal points
- After `.` expects digit or special float keyword
- Signals `extraction-error` for invalid patterns like `+.foo`, `1.`

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
