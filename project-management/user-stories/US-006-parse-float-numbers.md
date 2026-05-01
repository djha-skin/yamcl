# US-006: Parse Float Numbers

## Description
Parse floating-point numbers with decimal points and optional exponents.

## YAML Examples
```yaml
simple: 3.14
negative: -3.14
exponent: 3.0e8
negative_exponent: 3.0e-8
with_underscores: 1_000.5
special: .inf  # positive infinity
special_neg: -.inf  # negative infinity
not_a_number: .nan
```

## Test Cases
1. **Simple float**: `3.14` → `3.14`
2. **Negative float**: `-3.14` → `-3.14`
3. **Exponent notation**: `3.0e8` → `3.0e8`
4. **Negative exponent**: `3.0e-8` → `3.0e-8`
5. **Capital E**: `3.0E8` → `3.0e8`
6. **With underscores**: `1_000.5` → `1000.5`
7. **Positive infinity**: `.inf` → `+∞` (implementation-specific)
8. **Negative infinity**: `-.inf` → `-∞` (implementation-specific)
9. **NaN**: `.nan` → `NaN` (implementation-specific)
10. **No leading digit**: `.5` → `0.5`

## Dependencies
- US-005: Parse Integer Numbers (shares number parsing infrastructure)

## Implementation Notes
- Support decimal notation: `3.14`, `-3.14`
- Support scientific notation: `3.0e8`, `3.0E8`, `3.0e-8`
- Support underscores: `1_000.5`
- Special values: `.inf`, `-.inf`, `.nan`
- Should parse to Common Lisp floats (`float` type)
- Need to handle single and double precision
- Infinity and NaN representations are implementation-specific

## Edge Cases
- Very small/large numbers (overflow/underflow)
- `3.` (trailing decimal point)
- `.5` (no leading digit)
- `3e` (no exponent digits - error)
- Multiple decimal points: `3.14.15` (error)
- `+3.14` (explicit positive sign)
- Leading/trailing zeros: `0003.1400`