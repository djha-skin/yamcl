# US-022: Parse flow mappings {key: value}

## Description
Parse mappings in flow style with braces.

## YAML Examples
```yaml
{a: b, c: d}
{name: John, age: 30}
```

## Test Cases
1. **{} → empty hash**
1. **{a: b} → #("a" . "b")**

## Dependencies
- US-003: Skip Whitespace
- US-009: Distinguish null vs false

## Implementation Notes
- JSON-like object syntax
- Comma-separated key-value pairs
- Returns hash table

## Edge Cases
- Trailing comma: {a: b,}
- No colon: {a b} error
- Empty: {}
- Nested: {a: {b: c}}

