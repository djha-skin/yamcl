# US-015-E: Handle whitespace around colon

## Description
Properly handle YAML whitespace rules around colon separator in mappings.

## Tasks
1. Research YAML 1.2.2 spec for whitespace rules around `:`
2. Implement proper whitespace handling: optional space after `:`, required separation before `:`
3. Handle comments between key and colon
4. Handle comments between colon and value

## Test Cases
1. **Space before colon optional?** → Check spec
2. **Space after colon optional** → `"key:value"` should parse
3. **Multiple spaces** → `"key:  value"` should parse
4. **Tabs as whitespace** → `"key:\tvalue"` should parse
5. **Comments after key** → `"key # comment\n: value"` should parse
6. **Comments after colon** → `"key: # comment\nvalue"` should parse

## Dependencies
- US-015-D: Parse key-value pair with scalars
- US-003: Skip whitespace
- US-004: Handle comments

## Implementation Notes
- Critical to get whitespace rules correct per YAML spec
- YAML is whitespace-sensitive language
- Colon handling differs between block vs flow context

## Edge Cases
- Empty lines between key and colon
- Empty lines between colon and value
- Mix of spaces and tabs
- Unicode whitespace characters