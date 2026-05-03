# yamcl Roadmap - User Story Completion Tracker

This roadmap tracks the completion of 40 user stories for yamcl (YAML Ain't Markup Language -- Common Lisp). Stories are organized by phase and tested with the Test-Driven Development (TDD) approach.

## Current Status
**Last Updated**: 2024-12-19
**Total Stories**: 40
**Completed**: 4/40 (10.0%)
**In Progress**: 2
**Not Started**: 34

## Completion Summary

### Phase 1: Foundation (14 stories)
*Comments, whitespace, and basic scalar parsing*

- [x] **US-001**: Parse Line Comments (COMPLETED - 6/6 tests pass)
- [x] **US-002**: Parse Inline Comments (COMPLETED - 7/7 tests pass)  
- [x] **US-003**: Skip Whitespace (COMPLETED - 8/8 tests pass)
- [ ] **US-004**: Handle Document Markers (PARTIAL - 5/8 tests pass)
- [ ] **US-005**: Parse Integer Numbers (PARTIAL - 8/9 tests pass)
- [ ] **US-006**: Parse Float Numbers (NOT STARTED)
- [ ] **US-007**: Parse Boolean true/false (PARTIAL - basic parsing exists but not tested)
- [ ] **US-008**: Parse Null Values (null and ~) (PARTIAL - basic parsing exists but not tested)
- [ ] **US-009**: Distinguish null vs false (cl:null vs nil) (NOT STARTED)
- [ ] **US-010**: Parse Double-Quoted Strings (BASIC - simple parsing exists but not tested)
- [ ] **US-011**: Parse Single-Quoted Strings (NOT STARTED)
- [ ] **US-012**: Parse Bareword Strings (Plain Scalars) (NOT STARTED)
- [ ] **US-013**: Handle Escape Sequences in Double-Quoted Strings (NOT STARTED)
- [ ] **US-014**: Handle Escape Sequences in Single-Quoted Strings (NOT STARTED)

### Phase 2: Block Collections (10 stories)
*Block-style mappings and sequences*

- [ ] **US-015**: Parse Simple Block Mappings (key: value)
- [ ] **US-016**: Parse Nested Block Mappings
- [ ] **US-017**: Parse Simple Block Sequences (- item)
- [ ] **US-018**: Parse Nested Block Sequences
- [ ] **US-019**: Parse Mixed Mappings and Sequences
- [ ] **US-020**: Handle Indentation in Block Collections
- [ ] **US-021**: Parse Flow Sequences [a, b, c]
- [ ] **US-022**: Parse Flow Mappings {key: value}
- [ ] **US-023**: Parse Nested Flow Collections
- [ ] **US-024**: Parse Empty Collections

### Phase 3: Advanced Features (9 stories)
*Multi-line strings and YAML-specific features*

- [ ] **US-025**: Parse Literal Block Scalars (|)
- [ ] **US-026**: Parse Folded Block Scalars (>)
- [ ] **US-027**: Handle Chomping Modes (strip, clip, keep)
- [ ] **US-028**: Handle Indentation Indicators
- [ ] **US-029**: Parse Anchors (&anchor)
- [ ] **US-030**: Parse Aliases (*alias)
- [ ] **US-031**: Parse Tags (!!type)
- [ ] **US-032**: Parse Directives (%YAML, %TAG)
- [ ] **US-033**: Handle Multiple Documents

### Phase 4: Generation (7 stories)
*Render YAML from Lisp data structures*

- [ ] **US-034**: Generate JSON Scalar Values
- [ ] **US-035**: Generate Strings with Proper Escaping
- [ ] **US-036**: Generate Block Mappings
- [ ] **US-037**: Generate Block Sequences
- [ ] **US-038**: Generate Flow Collections
.
- [ ] **US-039**: Generate Multi-line Strings
- [ ] **US-040**: Generate with Anchors and Aliases

## Detailed Status

### Completed Stories (4)

#### US-001: Parse Line Comments
- **Status**: COMPLETED ✅
- **Tests**: 6/6 passing
- **Implementation**: `skip-whitespace-and-comments` in `src/scalars.lisp`
- **Coverage**:
  - Full-line comments: `# comment`
  - Multiple consecutive comments
  - Indented comments
  - Empty comments: `#`
  - Inline comments: `value # comment`
  - Comment at EOF

#### US-002: Parse Inline Comments
- **Status**: COMPLETED ✅
- **Tests**: 7/7 passing
- **Implementation**: `skip-whitespace-and-comments` in `src/scalars.lisp`
- **Coverage**:
  - Comment after number
  - Comment after negative number
  - Multiple spaces before comment
  - Tab before comment
  - Special characters in comment
  - Comment without space
  - Comment at EOF (no newline)

#### US-003: Skip Whitespace
- **Status**: COMPLETED ✅
- **Tests**: 8/8 passing
- **Implementation**: `skip-whitespace-and-comments` in `src/scalars.lisp`
- **Coverage**:
  - Leading spaces and tabs
  - Trailing spaces
  - Mixed whitespace
  - Newlines (CR, LF, CRLF)
  - Multiple newlines
  - Whitespace with comments

### In Progress Stories (2)

#### US-004: Handle Document Markers
- **Status**: PARTIAL ⚠️
- **Tests**: 5/8 passing
- **Failing Tests**:
  1. Test 4: Multiple documents (`--- 42\n...\n--- 99`) - parsing issues
  2. Test 6: Marker with comment (`--- # comment\n200`) - parser error
  3. Test 7: Partial marker (`-- 300`) - should parse as `- - 300` not `-300`
- **Passing**: Basic marker detection, empty documents, markers with whitespace
- **Implementation**: Document marker handling in `parse-from` in `src/scalars.lisp`
- **Issues**: Need to fix multiple document parsing and partial marker handling

#### US-005: Parse Integer Numbers
- **Status**: PARTIAL ⚠️
- **Tests**: 8/9 passing
- **Failing**: Octal notation (`0o52`) - fails to parse
- **Passing**: Decimal integers, negative numbers, zero, large numbers, leading zeros
- **Pending**: Hexadecimal, binary, underscores in numbers
- **Issues**: `parse-number` function needs to handle base indicators (`0o`, `0x`, `0b`)

### Partially Implemented (Not Tested)

#### US-007: Parse Boolean true/false
- **Status**: BASIC IMPLEMENTATION
- **Tests**: 0/0 (not tested)
- **Implementation**: `parse-boolean` function exists in `src/scalars.lisp`
- **Needs**: Test cases to be unskipped and verified

#### US-008: Parse Null Values (null and ~)
- **Status**: BASIC IMPLEMENTATION
- **Tests**: 0/0 (not tested)
- **Implementation**: `parse-null` function exists in `src/scalars.lisp`
- **Needs**: Test cases to be unskipped and verified
- **Note**: Returns `cl:null` for null/~ and `nil` for false

#### US-010: Parse Double-Quoted Strings
- **Status**: BASIC IMPLEMENTATION
- **Tests**: 0/0 (not tested)
- **Implementation**: `parse-string` function exists in `src/scalars.lisp`
- **Limitations**: No escape sequence handling
- **Needs**: Test cases to be unskipped and escape sequence support (US-013)

### YAML Test Suite Results
- **Total Tests**: 402
- **Passed**: 138 (34.3%)
- **Failed**: 264 (65.7%)
- **Skipped**: 0
- **Progress**: Foundation features handle basic scalar parsing, but many test suite tests require more complete YAML support

## Implementation Notes

### Design Decisions
- **Stream-based API**: `parse-from` and `generate-to` take streams only
- **String wrappers**: `parse-from-string` and `generate-to-string` for convenience
- **Null representation**: `cl:null` symbol for YAML/JSON null (distinct from `nil`)
- **Error handling**: `extraction-error` condition for parse failures

### Current Issues
1. **Document markers**: Need to fix multiple document parsing and partial markers
2. **Number parsing**: Need to support octal, hexadecimal, and binary notation
3. **Float parsing**: Not implemented (US-006)
4. **Escape sequences**: Not implemented (US-013, US-014)
5. **String types**: Only basic double-quote strings (no single quotes or barewords)
6. **Boolean/null testing**: Implemented but not tested

## Next Priority Stories

### Critical for Stories 4-6 (Current Assignment)
1. **US-004**: Fix document marker handling (multiple docs, comments, partial markers)
2. **US-005**: Complete integer parsing (octal notation)
3. **US-006**: Implement float number parsing (new implementation)

### Foundation Completion (Next)
4. **US-007**: Test boolean parsing
5. **US-008**: Test null value parsing
6. **US-009**: Ensure null/false distinction works correctly
7. **US-010**: Test and complete string parsing
8. **US-013**: Add escape sequence support

## Getting Started for Contributors

### Development Workflow (TDD)
1. Pick next unimplemented story from `project-management/user-stories/`
2. Read story requirements and test cases
3. Unskip tests in `tests/main.lisp` for that story
4. Implement feature in `src/` files following TDD
5. Run tests: `./tools/one-shot-lisp.ros '(asdf:test-system "com.djhaskin.yamcl")'`
6. Update this roadmap with completion status

### Development Guidelines
- **Line limit**: 80 characters for `.lisp`, `.ros`, and `.md` files
- **OCICL only**: No Quicklisp dependencies (managed by `~/.roswell/init.lisp`)
- **TDD required**: Write tests before implementation
- **Stream-based API**: Follow existing pattern

## Story Details
Each user story has detailed documentation in `project-management/user-stories/` with:
- Description and YAML examples
- Test cases
- Dependencies
- Implementation notes
- Edge cases

## References
- YAML 1.2.2 Specification: https://raw.githubusercontent.com/yaml/yaml-spec/refs/heads/main/spec/1.2.2/spec.md
- Project Documentation: `CONTRIBUTING.md`, `README.md`
- Test Structure: `tests/main.lisp`
- Source Code: `src/main.lisp`, `src/scalars.lisp`, `src/utils.lisp`