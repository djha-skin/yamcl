# US-005: Parse Integer Numbers

## Description
Parse integer numbers in decimal format from YAML.

## YAML Examples
```yaml
positive: 42
negative: -42
zero: 0
large: 1000000
octal: 0o52    # decimal 42
hex: 0x2A      # decimal 42
binary: 0b101010 # decimal 42
```

## Test Cases
1. **Positive integers**: `42` → `42`
2. **Negative integers**: `-42` → `-42`
3. **Zero**: `0` → `0`
4. **Large numbers**: `1000000` → `1000000`
5. **Octal notation**: `0o52` → `42`
6. **Hexadecimal notation**: `0x2A` → `42`
7. **Binary notation**: `0b101010` → `42`
8. **With underscores**: `1_000_000` → `1000000`
9. **Leading zeros**: `0012` → `12` (decimal, not octal!)

## Dependencies
- US-003: Skip Whitespace (numbers can have surrounding whitespace)

## Implementation Notes
- YAML 1.2 uses same integer syntax as JSON (decimal only by default)
- Support decimal: `42`, `-42`, `0`
- Support underscores for readability: `1_000_000`
- Base indicators: `0o` (octal), `0x` (hex), `0b` (binary)
- Should parse to Common Lisp integers (`integer` type)
- Need to handle size limits (bignums vs fixnums)
- Leading zeros: `0012` is decimal 12, not octal (unlike YAML 1.1)

## Edge Cases
- Very large integers (bignums)
- Integer overflow (if not using bignums)
- `-0` (should be 0)
- Empty after sign: `-` (error)
- Multiple signs: `--42` or `+-42` (error)
- Numbers with decimal point (should be parsed as float in US-006)