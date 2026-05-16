# US-015-G: Return hash table for mappings

## Description
Convert parsed mappings to hash table data structure with string keys.

## Tasks
1. Convert alist/plist of key-value pairs to hash table
2. Use `equal` test for string keys (YAML keys are strings)
3. Handle duplicate keys (error? overwrite? spec says later overrides)
4. Export `parse-block-mapping` function properly

## Test Cases
1. **Hash table type** → Result should be `hash-table` type
2. **String keys** → Keys should be strings, not symbols
3. **Duplicate keys** → `"key: val1\nkey: val2"` → second overrides first
4. **Key retrieval** → `(gethash "key" result)` should return value
5. **Empty mapping** → `""` → empty hash table?

## Dependencies
- US-015-F: Parse multiple key-value pairs
- US-009: Distinguish null vs false (for empty values)

## Implementation Notes
- YAML mappings are unordered collections
- Hash table with `:test 'equal` is appropriate
- Later: consider ordered hash table for round-trip
- Keys can be any scalar, but always converted to string for lookup

## Edge Cases
- Numeric keys → `"42: value"` → key should be string "42"
- Boolean/null keys → `"true: value"` → key should be string "true"
- Empty hash table representation
- Nested mappings (future story)