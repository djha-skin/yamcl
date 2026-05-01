# US-012: Parse bareword strings (plain scalars)

## Description
Parse unquoted strings that don't match other scalar patterns.

## YAML Examples
```yaml
bareword
with-dashes
with_underscores
CamelCase
```

## Test Cases
1. **hello → "hello"**
1. **hello-world → "hello-world"**

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- Most common string form in YAML
- Can't start with indicator characters
- Can contain alphanumerics, dashes, underscores

## Edge Cases
- Starts with number: 123abc
- Looks like boolean: true (should be string)
- Reserved words

