# US-016: Parse nested block mappings

## Description
Parse mappings containing other mappings.

## YAML Examples
```yaml
outer:\n  inner: value
nested:\n  deeper:\n    key: value
```

## Test Cases
1. **a: b: c → nested mapping**

## Dependencies
- US-015: Parse simple block mappings

## Implementation Notes
- Indentation determines nesting
- Child indented more than parent
- Return nested structure

## Edge Cases
- Inconsistent indentation
- Empty nested mapping
- Very deep nesting

