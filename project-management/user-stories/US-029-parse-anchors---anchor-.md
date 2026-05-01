# US-029: Parse anchors (&anchor)

## Description
Parse YAML anchors for node reuse.

## YAML Examples
```yaml
&anchor value
key: &name value
```

## Test Cases
1. **&anchor creates anchor**
1. **Can reference later**

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- Ampersand followed by name
- Anchors can be on any node
- Store for alias resolution

## Edge Cases
- Duplicate anchor names
- Anchor on empty node
- Complex anchor names

