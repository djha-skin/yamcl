# US-018: Parse nested block sequences

## Description
Parse sequences containing other sequences.

## YAML Examples
```yaml
-\n  - nested\n  - items
- - deeply\n    - nested
```

## Test Cases
1. **Nested sequences work**

## Dependencies
- US-017: Parse simple block sequences

## Implementation Notes
- Indentation determines nesting
- Child items indented relative to parent dash

## Edge Cases
- Inconsistent indentation
- Mixed with mappings
- Empty nested sequences

