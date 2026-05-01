# US-039: Generate multi-line strings

## Description
Generate block scalars for multi-line strings.

## YAML Examples
```yaml
line1\nline2 → |\n  line1\n  line2
```

## Test Cases
1. **Literal blocks**
1. **Folded blocks**

## Dependencies
- US-034: Generate JSON scalar values
- US-025: Parse literal block scalars
- US-026: Parse folded block scalars

## Implementation Notes
- Choose | or > based on content
- Handle indentation
- Chomping modes

## Edge Cases
- Empty string
- Very long lines
- When to use block vs quoted

