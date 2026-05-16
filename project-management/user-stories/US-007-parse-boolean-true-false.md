# US-007: Parse boolean true-false

## Description
Parse boolean values true and false from YAML according to the YAML 1.2.2 Core Schema.

## YAML Examples
```yaml
true: true
false: false
mixed: [true, false, True, FALSE]
```

## Test Cases
1. **true → t** (lowercase)
1. **True → t** (mixed case)
1. **TRUE → t** (uppercase)
1. **false → nil** (lowercase)
1. **False → nil** (mixed case)
1. **FALSE → nil** (uppercase)

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- Case-insensitive per YAML 1.2.2 Core Schema: accepts true, True, TRUE, false, False, FALSE
- Returns CL booleans: t and nil
- Distinct from strings "true"/"false" (quoted strings remain strings)

## Edge Cases
- trUE (weird casing) - should parse as string, not boolean
- inside quoted strings: "true" remains string
- Edge cases from spec example: Booleans: [ true, True, false, FALSE ]