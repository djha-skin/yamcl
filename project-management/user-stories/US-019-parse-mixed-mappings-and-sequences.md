# US-019: Parse mixed mappings and sequences

## Description
Parse structures containing both mappings and sequences.

## YAML Examples
```yaml
list:\n  - item1\n  - item2
- key: value\n  num: 42
```

## Test Cases
1. **Mapping containing sequence**
1. **Sequence containing mapping**

## Dependencies
- US-015: Parse simple block mappings
- US-017: Parse simple block sequences

## Implementation Notes
- Complex nested structures
- YAML's power feature
- Return appropriate Lisp structures

## Edge Cases
- Deeply mixed
- Empty elements
- Alternating types

