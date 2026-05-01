# US-032: Parse directives (%YAML, %TAG)

## Description
Parse YAML directives for document configuration.

## YAML Examples
```yaml
%YAML 1.2
%TAG ! !foo:
%%TAG !yaml! tag:yaml.org,2002:
```

## Test Cases
1. **Directives parsed**
1. **Affect document parsing**

## Dependencies
- US-003: Skip Whitespace

## Implementation Notes
- Percent sign starts directive
- YAML version directive
- TAG directive for custom tags

## Edge Cases
- Unknown directives
- Multiple directives
- Directive in middle of document

