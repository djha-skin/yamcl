# US-003: Skip Whitespace

## Description
Properly handle and skip all forms of YAML whitespace during parsing.

## YAML Examples
```yaml
key:    value    # multiple spaces
    indented: value  # indentation spaces
key: "value with\t tab"
```

## Test Cases
1. **Spaces**: Skip one or more space characters (` `)
2. **Tabs**: Skip tab characters (`\t`)
3. **Newlines**: Handle CR (`\r`), LF (`\n`), and CRLF (`\r\n`)
4. **Mixed whitespace**: Skip combinations of spaces, tabs, and newlines
5. **Indentation**: Preserve indentation levels for block collections
6. **Trailing whitespace**: Skip whitespace at end of lines
7. **Leading whitespace**: Skip whitespace at beginning of document

## Dependencies
- None (foundational feature)

## Implementation Notes
- YAML recognizes space (` `) and tab (`\t`) as whitespace
- Line breaks: LF (`\n`), CR (`\r`), and CRLF (`\r\n`)
- Need `blankspace-p` function to identify space/tab
- Need `whitespace-p` function to identify all whitespace
- Indentation should be tracked for block collections (future stories)
- Whitespace inside quoted strings should NOT be skipped

## Edge Cases
- Zero-width spaces or other Unicode whitespace
- Multiple consecutive newlines
- Files with mixed line endings
- Tabs vs spaces for indentation (YAML prefers spaces)
- Whitespace at EOF
- Non-breaking spaces (should they be treated as whitespace?)