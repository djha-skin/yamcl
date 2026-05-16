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
2. **hello-world → "hello-world"**
3. **hello_world → "hello_world"**
4. **CamelCase → "CamelCase"**
5. **_private → "_private"**
6. **test-123_abc → "test-123_abc"**

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- Most common string form in YAML
- Can't start with indicator characters
- Can contain alphanumerics, dashes, underscores
- Must NOT be recognized as reserved words (true/True/TRUE, false/False/FALSE, null/Null/NULL, ~)

## Edge Cases
- Starts with number: 123abc (should be string)
- Looks like reserved word with mixed case not in YAML Core Schema: trUE, fAlSe, nUlL (should be string)
- Special characters: ~~ (two tildes - should be string)

## YAML Core Schema Compliance
According to YAML 1.2.2 Core Schema (Section 10.2.1.2):
- Boolean values: true, True, TRUE, false, False, FALSE
- Null values: null, Null, NULL, ~
These are NOT bareword strings - they should be parsed as their respective boolean/null values.

Bareword strings are unquoted scalars that do NOT match the above patterns.