# US-015: Parse simple block mappings (key: value)

## Description
Parse basic key-value pairs in block style.

## YAML Examples
```yaml
key: value
name: John
age: 30
```

## Test Cases
1. **key: value → #("key" . "value")**

## Dependencies
- US-003: Skip Whitespace
- US-009: Distinguish null vs false

## Implementation Notes
- Key followed by colon and space
- Value can be any scalar
- Returns hash table or alist

## Edge Cases
- No space after colon: key:value
- Empty value: key:
- Multiline key?

