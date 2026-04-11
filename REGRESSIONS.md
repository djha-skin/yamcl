# REGRESSIONS.md

Known issues that need fixing before production-ready YAML parsing.

## REGR-001: API - Streams Only (No String Arguments)

**Problem**: `parse-from` and `generate-to` currently accept strings directly.

**Required Behavior**:
- `parse-from` and `generate-to` must take **streams only**
- Helper functions `parse-from-string` and `generate-to-string` wrap with `with-input-from-string` / `with-output-to-string`

**Reference**: NRDL `../nrdl/cl/main.lisp` uses this pattern:
```lisp
(defun parse-from (strm)
  (declare (type streamable strm))
  ...)

;; Helper for string convenience:
;; (with-input-from-string (s "yaml content") (parse-from s))
```

**Status**: [ ] Not started

---

## REGR-002: null vs false Distinction

**Problem**: `parse-from` parses both `false` and `null` into CL's `nil`, making them indistinguishable.

**Required Behavior**:
- Parse `null` (and `~`) → `cl:null` (the symbol, not CL's nil)
- Parse `false` → `nil` (CL's nil)
- `generate-to` must output `"null"` for `cl:null` and `"false"` for `nil`

**Reference**: NRDL `convert-to-symbol` and `symbol-string`:
```lisp
(defun convert-to-symbol (final-string)
  (cond ((string= final-string "false") nil)
        ((string= final-string "null") 'cl:null)
        ...))

(defun symbol-string (sym)
  (cond ((eql sym 'nil) "false")
        ((eql sym 'cl:null) "null")
        ...))
```

**Status**: [ ] Not started

---

## REGR-003: Escape Sequences in String Parsing

**Problem**: String parsing doesn't handle backslash escape sequences.

**Required Behavior** (per RFC 8259 Section 7):
| Escape | Meaning |
|--------|---------|
| `\"` | quotation mark |
| `\\` | reverse solidus (backslash) |
| `\/` | solidus (forward slash) |
| `\b` | backspace |
| `\f` | form feed |
| `\n` | line feed (newline) |
| `\r` | carriage return |
| `\t` | tab |
| `\uXXXX` | Unicode code point |

**Reference**: NRDL `extract-quoted` handles all these:
```lisp
(cond
  ((eql last-read quote-char) (push quote-char building))
  ((char= last-read #\\) (push last-read building))
  ((char= last-read #\/) (push last-read building))
  ((char= last-read #\b) (push #\Backspace building))
  ...)
```

**Status**: [ ] Not started

---

## REGR-004: Escape Sequences in String Generation

**Problem**: `generate-to` doesn't escape special characters in strings.

**Required Behavior**:
- Escape newlines, tabs, quotes, backslashes, and unprintable characters
- `\t` for tab
- `\n` for newline
- `\r` for carriage return
- `\f` for form feed
- `\b` for backspace
- `\"` for double quote
- `\\` for backslash
- `\uXXXX` for unprintable control characters

**Reference**: NRDL `inject-quoted` and `unprintable-p`:
```lisp
(defparameter *escape-characters*
  '((#\Newline . #\n)
    (#\Page . #\f)
    (#\Backspace . #\b)
    (#\Return . #\r)
    (#\Tab . #\t)
    (#\\ . #\\)))

(defun unprintable-p (chr)
  (and
    (not (whitespace-p chr))
    (let ((code (char-code chr)))
      (or (< code #x1f) (= code #x7f) ...))))
```

**Status**: [ ] Not started

---

## Implementation Order

1. **REGR-001**: Change API to streams only (breaking change, but clean)
2. **REGR-002**: Distinguish null from false
3. **REGR-003**: Add escape sequence parsing
4. **REGR-004**: Add escape sequence generation

Each should be committed separately with passing tests.
