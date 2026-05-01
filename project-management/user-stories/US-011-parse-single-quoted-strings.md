# US-011: Parse single-quoted strings

## Description
Parse strings enclosed in single quotes.

## YAML Examples
```yaml
'simple string'
'it\'s quoted'
'multiline\nstring'
```

## Test Cases
1. **'hello' → "hello"**
1. **'' → ""**

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- Single quotes required
- Fewer escapes than double-quoted
- '' escapes to '

## Edge Cases
- Unclosed quotes
- Empty string: ''
- Mixed quotes: ' " '

