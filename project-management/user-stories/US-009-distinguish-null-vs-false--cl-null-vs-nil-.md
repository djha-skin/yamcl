# US-009: Distinguish null vs false (cl:null vs nil)

## Description
Ensure null and false are distinguishable in parsed output.

## YAML Examples
```yaml
false: false
null: null
mixed: {false: false, null: null}
```

## Test Cases
1. **false → nil**
1. **null → cl:null**
1. **~ → cl:null**

## Dependencies
- US-007: Parse boolean true-false
- US-008: Parse null values

## Implementation Notes
- Critical regression fix
- false maps to CL's nil
- null and ~ map to cl:null symbol
- Must be distinguishable for round-trip

## Edge Cases
- Testing equality: (eq nil cl:null) → nil
- Serialization must preserve distinction

