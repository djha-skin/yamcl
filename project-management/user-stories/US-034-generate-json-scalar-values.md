# US-034: Generate JSON scalar values

## Description
Generate YAML/JSON output for scalar values.

## YAML Examples
```yaml
42 → 42
"hello" → "hello"
t → true
nil → false
```

## Test Cases
1. **Round-trip for scalars**
1. **Proper escaping**

## Dependencies
- US-009: Distinguish null vs false
- US-013: Handle escape sequences

## Implementation Notes
- Inverse of parsing
- cl:null → null
- nil → false
- t → true
- Numbers as-is
- Strings escaped

## Edge Cases
- Special floats: NaN, Infinity
- Large integers
- Unicode strings

