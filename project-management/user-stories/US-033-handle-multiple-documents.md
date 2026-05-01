# US-033: Handle multiple documents

## Description
Parse stream containing multiple YAML documents.

## YAML Examples
```yaml
---\ndoc1\n...\n---\ndoc2\n...
```

## Test Cases
1. **Multiple docs parsed**
1. **Can iterate through docs**

## Dependencies
- US-004: Handle Document Markers

## Implementation Notes
- --- starts document
- ... ends document
- Return list or stream of documents

## Edge Cases
- Empty documents
- No document markers
- Mixed directives across docs

