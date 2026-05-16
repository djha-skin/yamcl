# US-015-D: Parse key-value pair with scalars

## Description
Parse a simple key-value pair where both key and value are scalar values.

## Tasks
1. Implement `parse-simple-mapping` function
2. Parse key (scalar), colon, value (scalar)
3. Return cons cell `(key . value)` or similar simple structure
4. Handle optional whitespace around colon

## Test Cases
1. **Basic mapping** → `"key: value"` → `("key" . "value")`
2. **No space after colon** → `"key:value"` → `("key" . "value")` (per YAML spec)
3. **Different scalar types** → `"num: 42"` → `("num" . 42)`
4. **Quoted keys/values** → `"'key': \"value\""` → `("key" . "value")`
5. **Empty value** → `"key:"` → `("key" . cl:null)`

## Dependencies
- US-015-C: Parse colon token as separator
- US-012: Parse bareword strings
- US-010: Parse double-quoted strings  
- US-011: Parse single-quoted strings
- US-005: Parse integer numbers
- US-007: Parse boolean true/false
- US-008: Parse null values

## Implementation Notes
- Start with simplest possible return value (cons cell)
- Later stories will convert to hash table
- Focus on parsing mechanics, not data structure

## Edge Cases
- `key: ` (trailing space) - value should be `cl:null`
- Multibyte Unicode keys
- Escape sequences in quoted keys