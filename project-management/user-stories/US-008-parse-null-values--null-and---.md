# US-008: Parse null values (null and ~)

## Description
Parse null values using null keyword or ~ shorthand.

## YAML Examples
```yaml
null: null
tilde: ~
empty: 
null-in-array: [null, ~]
```

## Test Cases
1. **null → cl:null**
1. **~ → cl:null**
1. **NULL → error**

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- null and ~ both map to cl:null symbol
- Case-sensitive: null not NULL
- Empty value in mapping also represents null?

## Edge Cases
- NULL (uppercase)
- Null (mixed case)
-  ~~ (double tilde)

