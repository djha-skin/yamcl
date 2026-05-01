# US-025: Parse literal block scalars (|)

## Description
Parse multi-line strings using literal block scalar syntax.

## YAML Examples
```yaml
|\n  line1\n  line2\n  line3
```

## Test Cases
1. **Preserves newlines**
1. **Handles indentation**

## Dependencies
- US-003: Skip Whitespace
- US-010: Parse double-quoted strings

## Implementation Notes
- Pipe character starts literal block
- Preserves line breaks exactly
- Indentation stripped from each line

## Edge Cases
- Empty block
- Single line
- Trailing spaces
- Mixed indentation

