# US-035: Generate strings with proper escaping

## Description
Generate string output with correct escaping for special characters.

## YAML Examples
```yaml
\n → \\n
" → \"
control chars → \uXXXX
```

## Test Cases
1. **Escaping works**
1. **Round-trip preserves string**

## Dependencies
- US-013: Handle escape sequences in double-quoted strings

## Implementation Notes
- Critical regression fix
- RFC 8259 escaping
- Control characters escaped
- Unicode escapes

## Edge Cases
- Already escaped sequences
- Mixed escaping
- Invalid Unicode

