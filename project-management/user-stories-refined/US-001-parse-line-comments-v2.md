# US-001: Parse Line Comments

## Description
Parse YAML comments starting with `#` that continue to the end of the line. Comments should be ignored during parsing.

**YAML 1.2.2 Spec Reference**: Section 5.4 "Comments"

## Priority: Critical (Foundation)
**Estimated Implementation Time**: 2-4 hours  
**Category**: Basic parsing

## Concrete Test Cases with Expected Outputs

### Test 1: Simple Comment
```yaml
# A comment
key: value
```
**Expected Lisp Output**: `(("key" . "value"))`

### Test 2: Comment with Whitespace
```yaml
  # Indented comment
  key: value
```
**Expected Lisp Output**: `(("key" . "value"))`

### Test 3: Multiple Comments
```yaml
# First
# Second
value: 42
```
**Expected Lisp Output**: `(("value" . 42))`

### Test 4: Comment at Document End
```yaml
key: value
# End comment
```
**Expected Lisp Output**: `(("key" . "value"))`

### Test 5: Empty Comment
```yaml
#
key: value
```
**Expected Lisp Output**: `(("key" . "value"))`

## Error Cases with Expected Behavior

### Error 1: Hash in Quoted String
```yaml
key: "value # not a comment"
```
**Expected**: Parse as string `"value # not a comment"`
**Error if**: Hash is treated as comment start

### Error 2: Comment in Flow Style
```yaml
{key: value # not a comment in flow style}
```
**Expected**: Parse error or treat `#` as comment (spec ambiguous)
**YAML Spec**: Comments not allowed in flow style

### Error 3: Comment After Document End
```yaml
---
# Comment after document end
...
```
**Expected**: Ignore comment, treat as end of stream

## Implementation Details

### Pseudo-code Function
```lisp
(defun skip-comments (stream)
  "Skip # and everything until end of line."
  (when (char= (peek-char nil stream) #\#)
    (read-char stream) ; consume #
    (loop for ch = (read-char stream nil :eof)
          until (or (eq ch :eof)
                    (char= ch #\Newline)
                    (char= ch #\Return)))))
```

### Integration Points
- Call `skip-whitespace-and-comments` at start of each parsing step
- Handle both LF (`\n`) and CRLF (`\r\n`) line endings
- Must work with `+eof+` constant for end-of-file detection

### Performance Requirements
- O(n) time for comment skipping
- Should not allocate memory for comment content
- Minimal overhead per comment

## Edge Cases and Specifications

1. **Comment containing backslash escapes**: Should be ignored entirely
2. **Unicode characters in comments**: Should be skipped correctly (UTF-8 aware)
3. **Comments with trailing whitespace**: Should skip whitespace too
4. **Tab after hash**: `#\tcomment` should work
5. **Multiple hash characters**: `## Double hash` should still be comment
6. **Comment at EOF without newline**: Should not cause error

## Dependencies
- None (foundational feature)

## Acceptance Criteria
1. All 5 test cases pass with exact expected outputs
2. Error cases handled as specified
3. Integration with other parsing functions works
4. Performance meets requirements
5. Handles all edge cases correctly

## YAML Test Suite References
Manually identified tests that exercise comment parsing:
- **3MYT**: Tests comments in various positions
- **98YD**: Tests comments with special characters
- **X4QW**: Tests comments in block sequences

## API Requirements
- Must use stream-based API: `(parse-from stream)`
- Wrapper function: `(parse-from-string string)`
- Comments should not affect line/column tracking for error messages

## Success Metrics
- **Test passed**: 5/5 basic tests
- **Errors handled**: 3/3 error cases
- **Performance**: < 1ms per 1000 lines of comments
- **Memory**: No allocations for comment content

## Notes for Implementation
1. Use `peek-char` to check for `#` without consuming
2. Use `read-char` in loop to skip until newline
3. Handle EOF case gracefully
4. Return `t` if comment was skipped, `nil` otherwise
5. Update line/column counters for error reporting