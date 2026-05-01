# US-028: Handle indentation indicators

## Description
Handle explicit indentation specification in block scalars.

## YAML Examples
```yaml
|2\n    content
>1\n   folded
```

## Test Cases
1. **Explicit indent respected**
1. **Auto-detect when not specified**

## Dependencies
- US-025: Parse literal block scalars
- US-026: Parse folded block scalars

## Implementation Notes
- Number after | or > specifies indentation
- 0-9 allowed
- Indentation stripped from each line

## Edge Cases
- Indent 0
- Large indent
- Invalid indent indicator

