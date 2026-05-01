# US-030: Parse aliases (*alias)

## Description
Parse YAML aliases that reference anchors.

## YAML Examples
```yaml
*anchor
key: *name
```

## Test Cases
1. ***alias references anchor**
1. **Error if anchor not defined**

## Dependencies
- US-029: Parse anchors

## Implementation Notes
- Asterisk followed by anchor name
- Resolves to anchored value
- Circular reference detection

## Edge Cases
- Undefined alias
- Self-reference
- Nested aliases

