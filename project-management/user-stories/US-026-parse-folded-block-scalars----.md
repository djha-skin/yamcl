# US-026: Parse folded block scalars (>)

## Description
Parse multi-line strings using folded block scalar syntax.

## YAML Examples
```yaml
>\n  folded\n  lines\n  here
```

## Test Cases
1. **Folds single newlines**
1. **Preserves blank lines**

## Dependencies
- US-003: Skip Whitespace
- US-010: Parse double-quoted strings

## Implementation Notes
- Greater-than starts folded block
- Single newlines become spaces
- Blank lines preserved as newlines

## Edge Cases
- Empty block
- Leading/trailing newlines
- Complex folding cases

