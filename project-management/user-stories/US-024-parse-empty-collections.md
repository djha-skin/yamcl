# US-024: Parse empty collections

## Description
Parse empty sequences and mappings.

## YAML Examples
```yaml
[]
{}
empty_seq:\n
empty_map:\n
```

## Test Cases
1. **[] → ()**
1. **{} → #()**
1. **key: → #("key" . null)**

## Dependencies
- US-021: Parse flow sequences
- US-022: Parse flow mappings
- US-015: Parse simple block mappings

## Implementation Notes
- Empty flow collections
- Empty block collections
- Empty value in mapping

## Edge Cases
- [] vs {}
- Empty with whitespace
- Multiple empties

