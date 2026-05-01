# US-038: Generate flow collections

## Description
Generate flow-style sequences and mappings.

## YAML Examples
```yaml
(a b) → [a, b]
#("a" . "b") → {a: b}
```

## Test Cases
1. **Flow output**
1. **Compact representation**

## Dependencies
- US-034: Generate JSON scalar values
- US-021: Parse flow sequences
- US-022: Parse flow mappings

## Implementation Notes
- Lists to [] arrays
- Hash tables to {} objects
- Compact single-line format

## Edge Cases
- Empty collections
- Nested flow
- When to choose flow vs block

