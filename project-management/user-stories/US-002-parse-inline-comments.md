# US-002: Parse Inline Comments

## Description
Parse comments that appear on the same line as YAML content, after valid YAML tokens.

## YAML Examples
```yaml
key: value  # inline comment after value
list:
  - item1  # comment after list item
  - item2
mapping: {key: value}  # comment after flow mapping
```

## Test Cases
1. **Comment after scalar**: `value: 42 # comment` → should parse `42`
2. **Comment after mapping**: `key: value # comment` → should parse mapping
3. **Comment after sequence item**: 
   ```yaml
   - item1 # comment
   - item2
   ```
   → should parse sequence items correctly
4. **Comment after flow collection**: `[a, b] # comment` → should parse the array
5. **Multiple inline comments**: 
   ```yaml
   key1: value1 # comment1
   key2: value2 # comment2
   ```
   → should parse both mappings

## Dependencies
- US-001: Parse Line Comments (shares comment parsing logic)

## Implementation Notes
- Inline comments are comments that appear after valid YAML content on the same line
- Need to distinguish between `#` inside quoted strings (not a comment) and `#` starting a comment
- Comments should be ignored during tokenization
- The parser should skip to the next line or EOF after a comment

## Edge Cases
- Comment immediately after value with no space: `value#comment`
- Comment after empty value: `key: # comment`
- Comment in middle of multi-line string (should NOT be comment)
- Comment characters in URLs or other special values
- Comments with emoji or special Unicode