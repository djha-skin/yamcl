# US-014: Handle escape sequences in single-quoted strings

## Description
Parse limited escape sequences in single-quoted strings.

## YAML Examples
```yaml
'it\'s quoted'
'line1\nline2'
'simple'
```

## Test Cases
1. **'' → '**
1. **\n → \n (literal)**
1. **other escapes literal**

## Dependencies
- US-011: Parse single-quoted strings

## Implementation Notes
- Only '' escapes to '
- All other characters are literal
- \n remains backslash-n

## Edge Cases
- '''' → ''
- '''s → 's
- Mixed with double quotes

