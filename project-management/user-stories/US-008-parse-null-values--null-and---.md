# US-008: Parse null values (null and ~)

## Description
Parse null values using null keyword or ~ shorthand according to YAML 1.2.2 Core Schema.

## YAML Examples
```yaml
null: null
tilde: ~
empty: 
null-in-array: [null, Null, NULL, ~]
```

## Test Cases
1. **null → cl:null** (lowercase)
1. **Null → cl:null** (mixed case)
1. **NULL → cl:null** (uppercase)
1. **~ → cl:null**

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- Case-insensitive per YAML 1.2.2 Core Schema: accepts null, Null, NULL, ~
- All map to cl:null symbol
- Empty value in mapping also represents null (different story)

## Edge Cases
- ~~ (double tilde) - should parse as string "~~"
- Edge cases from spec example: A null: null, Also a null: # Empty, Not a null: ""