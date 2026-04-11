# REGR-004: Escape Sequences in String Generation

**Created**: 2026-04-11

**Issue**: String generation does not escape special characters.

**Required Behavior** (per JSON RFC 8259):
- Escape `\` as `\\`
- Escape `"` as `\"`
- Escape newlines as `\n`
- Escape tabs as `\t`
- Escape carriage returns as `\r`
- Escape backspace as `\b`
- Escape form feed as `\f`
- Escape unprintable characters as `\uXXXX`

**Reference**: NRDL `inject-quoted` in `../nrdl/cl/main.lisp`

**Status**: PENDING
