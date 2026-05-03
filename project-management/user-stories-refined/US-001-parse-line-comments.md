# US-001: Parse Line Comments

## Description
Parse YAML comments starting with `#` that continue to the end of the line. Comments should be ignored during parsing.

**YAML 1.2.2 Spec Reference**: Section 5.4 "Comments"

## Priority: High (Foundational)
**Estimated Implementation Time**: 2-4 hours

## YAML Examples with Expected Lisp Output

### Example 1: Full-line comment
```yaml
# This is a comment
key: value
```
**Expected Lisp Output**: `(("key" . "value"))`

### Example 2: Comment with indentation
```yaml
  # Indented comment
  key: value
```
**Expected Lisp Output**: `(("key" . "value"))`

### Example 3: Multiple consecutive comments
```yaml
# First comment
# Second comment
value: 42
```
**Expected Lisp Output**: `(("value" . 42))`

## Test Cases with Concrete Input/Output

### Test 1: Basic comment parsing
**Input YAML**: `"# comment\nkey: value"`
**Expected Output**: `(("key" . "value"))`
**Test Type**: Positive

### Test 2: Comment at EOF
**Input YAML**: `"key: value\n# EOF comment"`
**Expected Output**: `(("key" . "value"))`
**Test Type**: Positive

### Test 3: Empty comment
**Input YAML**: `"#\nvalue: 42"`
**Expected Output**: `(("value" . 42))`
**Test Type**: Positive

### Test 4: Comment with special characters
**Input YAML**: `"# !@#$%^&*()\nkey: value"`
**Expected Output**: `(("key" . "value"))`
**Test Type**: Positive

## Error Cases

### Error 1: Unterminated comment (should not error)
**Input YAML**: `"# Comment at EOF without newline"`
**Expected Behavior**: Parse as empty document, no error

### Error 2: Hash in quoted string (should NOT be comment)
**Input YAML**: `"key: \"value # not a comment\""`
**Expected Output**: `(("key" . "value # not a comment"))`
**Error if**: Treats `#` as comment

## Implementation Notes

### Key Functions
- `skip-comments`: Skip `#` and everything until end of line
- `skip-whitespace-and-comments`: Combined whitespace and comment skipping
- Integration with `peek-char` and `read-char` in parsing loop

### Pseudo-code
```lisp
(defun skip-comments (stream)
  (when (char= (peek-char nil stream) #\#)
    (read-char stream) ; consume #
    (loop for ch = (read-char stream nil :eof)
          until (or (eq ch :eof)
                    (char= ch #\Newline)
                    (char= ch #\Return)))))
```

### Integration Points
- Call `skip-whitespace-and-comments` at start of each parsing step
- Ensure it handles both LF (`\n`) and CRLF (`\r\n`) line endings
- Must work with `+eof+` constant for end-of-file detection

## Edge Cases with Expected Behavior

1. **Comment containing backslash escapes**: Should be ignored entirely
2. **Unicode characters in comments**: Should be skipped correctly
3. **Comments with trailing whitespace**: Should skip whitespace too
4. **Comment in middle of quoted string**: Should NOT trigger comment parsing
5. **Multiple comment characters**: `## Double hash` should still be comment
6. **Tab after hash**: `#\tcomment` should work
7. **Mixed line endings**: Should handle `\n`, `\r`, `\r\n`

## Dependencies
- None (foundational feature)

## Success Criteria
1. All test cases pass with expected outputs
2. Error cases handled appropriately
3. Integration with other parsing functions works
4. Performance: O(n) time for comment skipping

## YAML Test Suite References
- **229Q**: Tests basic comment parsing
- **2SXE**: Tests comments with special characters
- **3RLN**: Tests comments in various contexts

## API Considerations
- Must use stream-based API: `(parse-from stream)`
- Wrapper function: `(parse-from-string string)`
- Comments should not affect line/column tracking for error messages