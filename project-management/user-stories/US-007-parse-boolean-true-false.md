# US-007: Parse boolean true-false

## Description
Parse boolean values true and false from YAML.

## YAML Examples
```yaml
true: true
false: false
mixed: [true, false]
```

## Test Cases
1. **true → t**
1. **false → nil**
1. **TRUE → error (case-sensitive)**

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- Case-sensitive: true-false not TRUE/FALSE
- Returns CL booleans: t and nil
- Distinct from strings "true"/"false"

## Edge Cases
- TRUE, FALSE (uppercase)
- True, False (mixed case)
- trUE (weird casing)
- inside strings: "true"

