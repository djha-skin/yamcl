# US-023: Parse nested flow collections

## Description
Parse flow collections containing other flow collections.

## YAML Examples
```yaml
[ [a, b], {c: d} ]
{list: [1, 2], map: {x: y}}
```

## Test Cases
1. **Nested works**
1. **Mixed nesting works**

## Dependencies
- US-021: Parse flow sequences
- US-022: Parse flow mappings

## Implementation Notes
- Arbitrary nesting
- Flow collections inside block collections
- Return appropriate nested structures

## Edge Cases
- Deep nesting
- Mixed flow/block
- Empty nested collections

