# US-017: Parse simple block sequences (- item)

## Description
Parse lists in block style starting with dash.

## YAML Examples
```yaml
- item1\n- item2
- 42\n- hello\n- true
```

## Test Cases
1. **- a → ("a")**
1. **- a\n- b → ("a" "b")**

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- Dash followed by space
- Returns list
- Can mix types

## Edge Cases
- No space after dash: -item
- Empty item: -
- Dash in middle of line

