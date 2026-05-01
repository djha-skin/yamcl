# US-040: Generate with anchors and aliases

## Description
Generate YAML with anchors and aliases for repeated nodes.

## YAML Examples
```yaml
Repeated structure uses &anchor and *alias
```

## Test Cases
1. **Anchors generated**
1. **Aliases used for duplicates**

## Dependencies
- US-034: Generate JSON scalar values
- US-029: Parse anchors
- US-030: Parse aliases

## Implementation Notes
- Detect duplicate structures
- Generate anchors
- Use aliases for repeats
- Prevent circular references

## Edge Cases
- Self-referential structures
- When not to use anchors
- Anchor naming

