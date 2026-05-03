# US-009: Distinguish null vs false (cl:null vs nil)

## Description
Ensure null and false are distinguishable in parsed output. This is a **critical regression fix** (REGR-002).

**YAML 1.2.2 Spec Reference**: Section 10.3.2 "Null", Section 10.3.3 "Boolean"

## Priority: Critical (Regression Fix)
**Estimated Implementation Time**: 1-2 hours

## YAML Examples with Expected Lisp Output

### Example 1: Basic null and false
```yaml
false_value: false
null_value: null
tilde_null: ~
```
**Expected Lisp Output**: 
```lisp
(("false_value" . nil) 
 ("null_value" . cl:null)
 ("tilde_null" . cl:null))
```

### Example 2: Mixed in collections
```yaml
mixed: {false: false, null: null, true: true}
```
**Expected Lisp Output**:
```lisp
(("mixed" . (("false" . nil) ("null" . cl:null) ("true" . t))))
```

## Test Cases with Concrete Input/Output

### Test 1: false → nil
**Input YAML**: `"key: false"`
**Expected Output**: `(("key" . nil))`
**Critical Check**: `(eq (cdar result) nil)` must be true

### Test 2: null → cl:null
**Input YAML**: `"key: null"`
**Expected Output**: `(("key" . cl:null))`
**Critical Check**: `(eq (cdar result) 'cl:null)` must be true

### Test 3: ~ → cl:null  
**Input YAML**: `"key: ~"`
**Expected Output**: `(("key" . cl:null))`
**Critical Check**: `(eq (cdar result) 'cl:null)` must be true

### Test 4: Distinguishability test
**Input YAML**: 
```yaml
false: false
null: null
```
**Expected Output**: 
```lisp
(("false" . nil) ("null" . cl:null))
```
**Critical Check**: 
```lisp
(not (eq (cdr (assoc "false" result :test #'string=))
         (cdr (assoc "null" result :test #'string=))))
```

## Error Cases

### Error 1: Invalid boolean/null
**Input YAML**: `"key: falze"` (typo)
**Expected Behavior**: Parse as string "falze", not boolean false

### Error 2: Case sensitivity
**Input YAML**: `"key: FALSE"` (uppercase)
**Expected Behavior**: YAML 1.2 is case-sensitive, so parse as string "FALSE"

## Implementation Notes

### Critical Requirements
1. `false` → CL's `nil`
2. `null` → Symbol `cl:null` (out-of-band, invented for this purpose)
3. `~` → Symbol `cl:null`
4. `true` → CL's `t`

### Pseudo-code
```lisp
(defun parse-scalar-value (scalar-string)
  (cond
    ((string= scalar-string "false") nil)
    ((string= scalar-string "null") 'cl:null)
    ((string= scalar-string "~") 'cl:null)
    ((string= scalar-string "true") t)
    (t (parse-other-scalar scalar-string))))
```

### Integration Points
- Modify `parse-json-scalar` function in `src/scalars.lisp`
- Ensure `generate-to` handles the inverse mapping
- Update test expectations in `tests/scalars.lisp`

## Edge Cases with Expected Behavior

1. **White space around values**: `key:  false` should still parse as nil
2. **In sequences**: `[false, null, true]` → `(nil cl:null t)`
3. **As mapping keys**: `{false: value}` key should be string "false", not nil
4. **Nested**: `{key: {subkey: false}}` → nested nil
5. **With tags**: `!!bool false` should still be nil
6. **Empty string vs false**: `""` is string, not false

## Dependencies
- US-007: Parse boolean true-false
- US-008: Parse null values

## Success Criteria
1. All test cases pass with exact expected outputs
2. `nil` and `cl:null` are distinguishable `(not (eq nil 'cl:null))`
3. Round-trip works: parse → generate → parse produces identical results
4. Integration with existing regression tests passes

## YAML Test Suite References
- **2JQS**: Tests null values
- **3ALJ**: Tests boolean values  
- **4FJ6**: Tests null vs false distinction

## API Considerations
- **REGR-001**: Must use stream-based API
- **REGR-002**: This story directly addresses this regression
- Wrapper functions must preserve the distinction
- Error messages should be clear about parsing failures

## Testing Strategy

### Unit Tests
```lisp
(test distinguish-null-false
  (is (eq nil (parse-from-string "false")))
  (is (eq 'cl:null (parse-from-string "null")))
  (is (not (eq nil 'cl:null)))
  (is (not (eq (parse-from-string "false") 
               (parse-from-string "null")))))
```

### Round-trip Tests
```lisp
(test roundtrip-null-false
  (let ((data '(("false" . nil) ("null" . cl:null))))
    (is (equal data (parse-from-string (generate-to-string data))))))
```

### Regression Tests
```lisp
(test regr-002-fixed
  "Ensure REGR-002 is fixed: null and false distinguishable"
  (let* ((parsed (parse-from-string "false: false\nnull: null"))
         (false-val (cdr (assoc "false" parsed :test #'string=)))
         (null-val (cdr (assoc "null" parsed :test #'string=))))
    (is (eq nil false-val))
    (is (eq 'cl:null null-val))
    (is (not (eq false-val null-val)))))
```