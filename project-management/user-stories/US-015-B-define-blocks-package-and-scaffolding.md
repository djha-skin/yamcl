# US-015-B: Define blocks package and basic scaffolding

## Description
Define the blocks package in `src/blocks.lisp` with proper dependencies and basic function stubs.

## Tasks
1. Add `defpackage` for `com.djhaskin.yamcl/blocks` with proper `:use` and `:export`
2. Define function stubs for:
   - `parse-block-value`
   - `parse-block-mapping` 
   - `parse-block-sequence`
3. Ensure dependencies are properly declared (scalars, utils)

## Test Cases
1. **Package definition** → Verify package can be loaded
2. **Function stubs** → Verify functions exist (even if they error)
3. **System loading** → Verify `com.djhaskin.yamcl` system loads without errors

## Dependencies
- US-015-A: Create phase-2 test infrastructure

## Implementation Notes
- Package should `:use` `cl`, `com.djhaskin.yamcl/utils`, and import needed symbols from `com.djhaskin.yamcl/scalars`
- Export minimal set of functions needed for testing
- Function stubs should signal "not implemented" errors

## Edge Cases
- Circular package dependencies
- Missing symbol imports