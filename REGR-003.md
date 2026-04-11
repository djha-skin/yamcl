# REGR-003: Escape Sequences in String Parsing

**Created**: 2026-04-11

**Issue**: String parsing does not handle JSON escape sequences per RFC 8259.

**Required Escapes** (RFC 8259 Section 7):
| Escape | Meaning |
|--------|---------|
| `\"` | quotation mark (U+0022) |
| `\\` | reverse solidus (U+005C) |
| `\/` | solidus (U+002F) |
| `\b` | backspace (U+0008) |
| `\f` | form feed (U+000C) |
| `\n` | line feed (U+000A) |
| `\r` | carriage return (U+000D) |
| `\t` | tab (U+0009) |
| `\uXXXX` | Unicode code point |

**Reference**: NRDL `extract-quoted` in `../nrdl/cl/main.lisp`

**Status**: PENDING
