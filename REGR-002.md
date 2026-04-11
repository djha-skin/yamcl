# REGR-002: null vs false Distinction

**Created**: 2026-04-11

**Issue**: `parse-from` parses both `false` and `null` into CL's `nil`,
making them indistinguishable.

**Required Behavior**:
- Parse `null` → `cl:null` (out-of-band symbol, distinct from CL's nil)
- Parse `false` → `nil` (CL's nil)
- Parse `true` → `t` (CL's t)

**Reference**: NRDL `convert-to-symbol` in `../nrdl/cl/main.lisp`:
```lisp
((string= final-string "nil")    'cl:null)  ; JSON null
((string= final-string "false")  nil)        ; JSON false
((string= final-string "true")   t)          ; JSON true
((string= final-string "null")   'cl:null)  ; JSON null (alias)
```

**Status**: PENDING
