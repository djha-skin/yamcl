# yamcl Roadmap - User Story Completion Tracker

This roadmap tracks the completion of 40 user stories for yamcl (YAML Ain't Markup Language -- Common Lisp). Stories are organized by phase and tested with the Test-Driven Development (TDD) approach.

## Current Status
**Last Updated**: $(date)
**Total Stories**: 40
**Completed**: 1/40 (2.5%)
**In Progress**: 0
**Not Started**: 39

## Completion Summary

### Phase 1: Foundation (14 stories)
*Comments, whitespace, and basic scalar parsing*

- [x] **US-001**: Parse Line Comments (COMPLETED - All tests pass)
- [ ] **US-002**: Parse Inline Comments  
- [ ] **US-003**: Skip Whitespace
- [ ] **US-004**: Handle Document Markers
- [ ] **US-005**: Parse Integer Numbers (PARTIAL - Octal notation fails)
- [ ] **US-006**: Parse Float Numbers
- [ ] **US-007**: Parse Boolean true/false
- [ ] **US-008**: Parse Null Values (null and ~)
- [ ] **US-009**: Distinguish null vs false (cl:null vs nil)
- [ ] **US-010**: Parse Double-Quoted Strings
- [ ] **US-011**: Parse Single-Quoted Strings
- [ ] **US-012**: Parse Bareword Strings (Plain Scalars)
- [ ] **US-013**: Handle Escape Sequences in Double-Quoted Strings
- [ ] **US-014**: Handle Escape Sequences in Single-Quoted Strings

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
- [ ] **US-039**: Generate Multi-line Strings
- [ ] **US-040**: Generate with Anchors and Aliases

## Detailed Status

### Completed Stories

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

### In Progress Stories

#### US-005: Parse Integer Numbers
- **Status**: PARTIAL ⚠️
- **Tests**: 6/9 passing
- **Failing**: Octal notation (`0o52`)
- **Passing**: Decimal integers, negative numbers, zero, large numbers, leading zeros
- **Pending**: Hexadecimal, binary, underscores in numbers

### Not Started Stories
All other stories (US-002 through US-040) are not yet implemented. Test stubs exist in `tests/main.lisp` but are marked as "skip".

## Test Results Summary

### Phase 1 Tests (Foundation)
- **US-001**: 6/6 tests pass ✅
- **US-002**: 0 tests (skipped)
- **US-003**: 0 tests (skipped) 
- **US-004**: 0 tests (skipped)
- **US-005**: 6/9 tests pass ⚠️ (octal notation fails)
- **US-006 through US-014**: 0 tests (skipped)

### YAML Test Suite
- **Total Tests**: 402
- **Passed**: 219 (54.5%)
- **Failed**: 183 (45.5%)
- **Skipped**: 0

## Implementation Notes

### Completed Features
1. **Comment parsing**: Handles `#` to end of line, multiple comments, inline comments
2. **Basic number parsing**: Integers (decimal), negative numbers
3. **API structure**: Stream-based parsing with `parse-from` and `generate-to`

### Known Issues
1. **Octal notation**: `0o52` fails to parse (should be 42 in decimal)
2. **Hex/binary notation**: Not implemented
3. **Number underscores**: Not implemented (`1_000_000`)
4. **Float numbers**: Not implemented
5. **Boolean parsing**: Not implemented
6. **Null/false distinction**: Not implemented (critical for YAML/JSON compatibility)
7. **String parsing**: Not implemented (quoted or bareword)

### Design Decisions
- **Stream-based API**: `parse-from` and `generate-to` take streams only
- **String wrappers**: `parse-from-string` and `generate-to-string` for convenience
- **Null representation**: `cl:null` symbol for YAML/JSON null (distinct from `nil`)
- **Escape handling**: RFC 8259 section 7 escapes planned for US-013

## Next Priority Stories

### Critical Foundation (Must Complete)
1. **US-009**: Distinguish null vs false (cl:null vs nil) - Essential for JSON compatibility
2. **US-005**: Complete integer number parsing (octal, hex, binary)
3. **US-006**: Parse float numbers
4. **US-007**: Parse boolean true/false
5. **US-008**: Parse null values (null and ~)

### String Support (Next Wave)
6. **US-010**: Parse double-quoted strings
7. **US-011**: Parse single-quoted strings  
8. **US-012**: Parse bareword strings
9. **US-013**: Handle escape sequences
10. **US-014**: Escape sequences in single quotes

## Getting Started

### For Contributors
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