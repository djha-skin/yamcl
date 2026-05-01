# US-001: Parse Line Comments

## Description
Parse YAML comments starting with `#` that continue to the end of the line. Comments should be ignored during parsing.

## YAML Examples
```yaml
# This is a full-line comment
key: value  # This is an inline comment

# Multiple consecutive comments
# Should all be ignored
another: value
```

## Test Cases
1. **Full-line comment**: `# comment` → should be ignored, next token should be parsed
2. **Inline comment**: `key: value # comment` → should parse `key: value` and ignore the comment
3. **Multiple comments**: 
   ```yaml
   # first comment
   # second comment
   value: 42
   ```
   → should parse `value: 42`
4. **Empty comment**: `#` → should be ignored
5. **Comment with special characters**: `# !@#$%^&*()` → should be ignored

## Dependencies
- None (foundational feature)

## Implementation Notes
- Use `skip-whitespace-and-comments` function to handle comments
- Comments start with `#` and continue to end of line (`\n` or `\r\n`)
- Comments should be skipped during parsing, not stored
- Need to handle both CRLF and LF line endings

## Edge Cases
- Comment at EOF (no newline)
- Comment containing backslash escapes
- Comment in middle of quoted string (should NOT be treated as comment)
- Unicode characters in comments
- Comments with trailing whitespace