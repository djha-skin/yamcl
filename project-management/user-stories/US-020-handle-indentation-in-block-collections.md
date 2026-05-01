# US-020: Handle indentation in block collections

## Description
Properly handle indentation levels for block collections.

## YAML Examples
```yaml
key:\n  value
- item\n  nested: value
```

## Test Cases
1. **Indentation preserved**
1. **Dedent ends collection**

## Dependencies
- US-015: Parse simple block mappings
- US-017: Parse simple block sequences

## Implementation Notes
- Spaces (not tabs) for indentation
- Indentation level determines scope
- Same or less indentation ends current collection

## Edge Cases
- Tabs vs spaces
- Inconsistent indentation
- Zero indent
- Very deep indent

