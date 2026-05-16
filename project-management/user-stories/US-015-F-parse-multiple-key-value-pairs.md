# US-015-F: Parse multiple key-value pairs

## Description
Parse multiple key-value pairs on separate lines (simple block mapping).

## Tasks
1. Implement `parse-block-mapping` function to handle multiple pairs
2. Parse until end of input or different indentation level (simplified: until EOF)
3. Handle blank lines between pairs
4. Return list of key-value pairs or similar structure

## Test Cases
1. **Two pairs** → `"key1: value1\nkey2: value2"` → list of two pairs
2. **Blank line between** → `"key1: value1\n\nkey2: value2"` → should parse
3. **Mixed indentation** → Future story (US-020)
4. **Trailing newline** → `"key: value\n"` → should parse
5. **No trailing newline** → `"key: value"` → should parse

## Dependencies
- US-015-D: Parse key-value pair with scalars
- US-015-E: Handle whitespace around colon

## Implementation Notes
- Start simple: parse until EOF
- Later: handle indentation levels (US-020)
- Consider using loop with lookahead to detect next key
- Return alist or plist for simplicity initially

## Edge Cases
- Empty mapping `{}` → not applicable for block style
- Single pair with trailing whitespace
- Windows vs Unix line endings