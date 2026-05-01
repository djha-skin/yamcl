# US-037: Generate block sequences

## Description
Generate block-style sequences from Lisp lists.

## YAML Examples
```yaml
(a b c) → - a\n- b\n- c
```

## Test Cases
1. **Simple list**
1. **Nested list**

## Dependencies
- US-034: Generate JSON scalar values
- US-017: Parse simple block sequences

## Implementation Notes
- Lists to YAML sequences
- Proper indentation
- Dash prefix for items

## Edge Cases
- Empty list
- Very long list
- Mixed types

