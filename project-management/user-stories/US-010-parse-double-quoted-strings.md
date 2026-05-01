# US-010: Parse double-quoted strings

## Description
Parse strings enclosed in double quotes.

## YAML Examples
```yaml
"simple string"
"string with spaces"
"line1\nline2"
```

## Test Cases
1. **"hello" → "hello"**
1. **"" → "" (empty string)**

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- Double quotes required
- Escape sequences handled in US-013
- Multiline strings need special handling

## Edge Cases
- Unclosed quotes
- Quotes inside string: "\""
- Empty string
- Only quotes: ""

