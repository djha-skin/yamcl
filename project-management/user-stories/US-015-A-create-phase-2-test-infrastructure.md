# US-015-A: Create phase-2 test infrastructure

## Description
Create the test infrastructure for phase 2 (block collections) before implementing any block parsing functionality.

## Tasks
1. Create `tests/blocks.lisp` file with package definition
2. Create `phase-2-block-collections` test suite in `tests/main.lisp` 
3. Update ASDF system `com.djhaskin.yamcl/tests` to include `blocks.lisp` file
4. Ensure `asdf:test-system` still runs all phase-1 tests successfully

## Test Cases
1. **Test file creation** → Verify `tests/blocks.lisp` exists with proper package
2. **ASDF integration** → Verify system loads without errors
3. **Backward compatibility** → Verify all phase-1 tests still pass

## Dependencies
- None (foundational infrastructure)

## Implementation Notes
- Use `defpackage` pattern matching other test files
- Add `(:file "blocks")` to test system components
- Keep `phase-2-block-collections` test suite empty initially (skip all tests)

## Edge Cases
- Ensure no circular dependencies with existing code
- Verify package exports are minimal and precise