# US-015-C: Parse colon token as separator

## Description
Implement basic colon parsing as a separator token between key and value in mappings.

## Tasks
1. Create `parse-colon` function that consumes ":" character
2. Handle whitespace before and after colon (YAML spec: space after colon is optional)
3. Signal `extraction-error` if colon is missing
4. Integrate with `parse-scalar-lookahead` to stop at colon

## Test Cases
1. **Basic colon** → `parse-from-string ":"` should return `cl:null` (empty mapping?)
2. **Colon with spaces** → `parse-from-string " : "` should work
3. **Missing colon error** → `parse-from-string "key value"` should signal `extraction-error`
4. **Scalar stops at colon** → `parse-from-string "key:"` should parse "key" as scalar, colon as separator

## Dependencies
- US-015-A: Create phase-2 test infrastructure  
- US-015-B: Define blocks package and scaffolding
- US-012: Parse bareword strings (for key parsing)

## Implementation Notes
- Colon is a "separator" not a "token" in traditional lexer terms
- In YAML, `:` indicates mapping in block context
- Need to modify `parse-bareword-string` to stop at `:` (already done?)
- Whitespace after `:` is optional per YAML spec

## Edge Cases
- `::` (double colon) - not valid YAML
- `:key` (colon first) - not valid as mapping key
- Unicode colon variations