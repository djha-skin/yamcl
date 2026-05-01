# US-031: Parse tags (!!type)

## Description
Parse explicit type tags in YAML.

## YAML Examples
```yaml
!!str 123
!!int "42"
!!bool true
```

## Test Cases
1. **Tags influence parsing**
1. **Standard tags supported**

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- Exclamation marks indicate tag
- Standard tags: !!str, !!int, !!bool, etc.
- Custom tags possible

## Edge Cases
- Unknown tags
- Conflicting tags
- Tag shorthand: !local

