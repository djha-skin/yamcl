# US-013: Handle escape sequences in double-quoted strings

## Description
Parse escape sequences in double-quoted strings per JSON RFC.

## YAML Examples
```yaml
"line1\nline2"
"tab\tseparated"
"quote\"inside"
```

## Test Cases
1. **\n → newline**
1. **\t → tab**
1. **\" → "**
1. **\\ → \**

## Dependencies
- US-010: Parse double-quoted strings

## Implementation Notes
- RFC 8259 Section 7 escapes
- \", \\, \/, \b, \f, \n, \r, \t, \uXXXX
- Critical regression fix

## Edge Cases
- Invalid escape: \x
- Unicode: \u20AC
- Surrogate pairs
- \/ optional

