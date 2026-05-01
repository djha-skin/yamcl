# US-004: Handle Document Markers

## Description
Parse YAML document markers: start marker (`---`) and end marker (`...`).

## YAML Examples
```yaml
---  # Document start
key: value
...  # Document end

---  # Multiple documents
document1: content
...
---
document2: content
```

## Test Cases
1. **Document start marker**: `---` at beginning of stream
2. **Document end marker**: `...` at end of document
3. **Multiple documents**: `---\ndoc1\n...\n---\ndoc2\n...`
4. **Marker with whitespace**: `--- \n` (with trailing space)
5. **Marker in content**: `key: ---` should NOT be treated as marker
6. **Partial marker**: `--` or `..` should NOT be treated as markers

## Dependencies
- US-001: Parse Line Comments (markers can have comments)
- US-003: Skip Whitespace (markers can have surrounding whitespace)

## Implementation Notes
- Document start marker: three dashes `---`
- Document end marker: three dots `...`
- Markers must appear at beginning of line or after whitespace
- Markers can be followed by comments
- Multiple documents in one stream should be parsed separately
- Return `+eof+` when encountering `...` marker
- Need to handle case where document has no explicit markers

## Edge Cases
- Markers in middle of line: `key: --- value`
- Markers inside quoted strings: `"---"`
- Markers with extra characters: `----` or `....`
- Empty document: `---\n...`
- Document with only comments: `--- # comment\n...`