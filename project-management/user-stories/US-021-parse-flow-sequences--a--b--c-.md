# US-021: Parse flow sequences [a, b, c]

## Description
Parse sequences in flow style with brackets.

## YAML Examples
```yaml
[a, b, c]
[1, 2, 3]
["hello", true, null]
```

## Test Cases
1. **[] → empty list**
1. **[a] → ("a")**
1. **[a, b] → ("a" "b")**

## Dependencies
- US-003: Skip Whitespace
- US-009: Distinguish null vs false

## Implementation Notes
- JSON-like array syntax
- Comma-separated
- Returns list

## Edge Cases
- Trailing comma: [a,]
- No commas: [a b] error
- Empty: []
- Nested: [[a]]

