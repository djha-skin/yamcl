# REGR-001: API - Streams Only (No String Arguments)

**Created**: 2026-04-11

**Issue**: `parse-from` and `generate-to` currently take strings as arguments,
but should only accept streams per the NRDL design.

**Required Changes**:
1. Change `parse-from` to accept only streams
2. Change `generate-to` to accept only streams
3. Create `parse-from-string` wrapper using `with-input-from-string`
4. Create `generate-to-string` wrapper using `with-output-to-string`

**Reference**: NRDL `parse-from` and `generate-to` in `../nrdl/cl/main.lisp`

**Status**: PENDING
