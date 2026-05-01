# US-027: Handle chomping modes (strip, clip, keep)

## Description
Handle trailing newline behavior in block scalars.

## YAML Examples
```yaml
|-  # strip\n  content
|+  # keep\n  content\n
```

## Test Cases
1. **|- strips trailing newlines**
1. **|+ keeps all newlines**
1. **| clips**

## Dependencies
- US-025: Parse literal block scalars
- US-026: Parse folded block scalars

## Implementation Notes
- Strip (-): remove trailing newlines
- Clip (default): single trailing newline
- Keep (+): keep all newlines

## Edge Cases
- Empty with chomping
- Multiple trailing newlines
- Chomping with indentation

