# yamcl Roadmap - Story-Based Implementation

This roadmap organizes implementation around 40 user stories, progressing from
simple to complex YAML 1.2.2 features.

## Current Status
**Project Status**: Foundation established, ready for story-based implementation
**Tests Passing**: 0/40 stories implemented
**Last Updated**: $(date)

## Implementation Strategy

We follow Test-Driven Development (TDD):
1. Write failing tests for a story
2. Implement minimal code to pass tests
3. Refactor while keeping tests green
4. Move to next story

## Story Completion Tracking

### Phase 1: Foundation (14 stories)
*Comments, whitespace, and basic scalar parsing*

- [ ] **US-001**: Parse Line Comments
- [ ] **US-002**: Parse Inline Comments  
- [ ] **US-003**: Skip Whitespace
- [ ] **US-004**: Handle Document Markers
- [ ] **US-005**: Parse Integer Numbers
- [ ] **US-006**: Parse Float Numbers
- [ ] **US-007**: Parse Boolean true/false
- [ ] **US-008**: Parse Null Values (null and ~)
- [ ] **US-009**: Distinguish null vs false (cl:null vs nil) ⚠️ REGRESSION
- [ ] **US-010**: Parse Double-Quoted Strings
- [ ] **US-011**: Parse Single-Quoted Strings
- [ ] **US-012**: Parse Bareword Strings (Plain Scalars)
- [ ] **US-013**: Handle Escape Sequences in Double-Quoted Strings ⚠️ REGRESSION
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
- [ ] **US-035**: Generate Strings with Proper Escaping ⚠️ REGRESSION
- [ ] **US-036**: Generate Block Mappings
- [ ] **US-037**: Generate Block Sequences
- [ ] **US-038**: Generate Flow Collections
- [ ] **US-039**: Generate Multi-line Strings
- [ ] **US-040**: Generate with Anchors and Aliases

## Critical Regression Fixes

⚠️ **High Priority**: These stories fix known regressions:

1. **US-009**: null/false distinction (REGR-002)
   - `null` → `cl:null` (symbol)
   - `false` → `nil` (CL's nil)
   - Must be distinguishable

2. **US-013**: Escape sequences in parsing (REGR-003)
   - RFC 8259 Section 7 escapes
   - `\\`, `\"`, `\/`, `\b`, `\f`, `\n`, `\r`, `\t`, `\uXXXX`

3. **US-035**: Escape sequences in generation (REGR-004)
   - Inverse of US-013
   - Special characters escaped in output

4. **API Design**: All parsing/generation uses streams (REGR-001)
   - `parse-from` takes stream, not string
   - `generate-to` takes stream, not string
   - Wrapper functions for string convenience

## Implementation Priority

### Wave 1: Critical Foundation (Stories 1-9)
Essential for any YAML parsing. Must complete before meaningful tests.

### Wave 2: String Handling (Stories 10-14)
Complete string support with escape sequences.

### Wave 3: Basic Structures (Stories 15-20)
Enable real YAML document parsing.

### Wave 4: Advanced Features (Stories 21-33)
Full YAML 1.2.2 compliance.

### Wave 5: Generation (Stories 34-40)
Round-trip completeness.

## Testing Strategy

### Unit Tests
- Each story has dedicated tests
- Tests in `tests/main.lisp` organized by story
- Use Parachute test framework

### Integration Tests
- YAML Test Suite (`tests/fixtures/yaml-test-suite/`)
- Round-trip tests (parse → generate → parse)
- Edge case coverage

### Regression Tests
- Track known issues
- Prevent regressions
- Continuous validation

## Quality Gates

### Before Moving Between Phases:
1. All tests pass for current phase
2. Code review completed
3. Documentation updated
4. Performance benchmarks (where applicable)

### Before Story Completion:
1. Tests written and passing
2. Edge cases handled
3. Error conditions tested
4. API consistency verified

## Success Metrics

### Phase 1 Complete:
- Can parse basic YAML scalars
- Handle comments and whitespace
- Distinguish null vs false
- Proper escape sequence handling

### Phase 2 Complete:
- Can parse block and flow collections
- Handle nested structures
- Proper indentation handling

### Phase 3 Complete:
- Full YAML 1.2.2 parsing support
- Multi-line strings, anchors, tags, directives
- Multiple document support

### Phase 4 Complete:
- Complete round-trip support
- Generate valid YAML from any parsed structure
- All regression tests passing

## Getting Started

### For Implementers:
1. Pick next unimplemented story
2. Read story details in `project-management/user-stories/`
3. Write failing tests in `tests/main.lisp`
4. Implement in `src/` files
5. Verify tests pass
6. Update this roadmap with completion status

### Test Commands:
```bash
# Run all tests
tools/one-shot-lisp.ros '(asdf:test-system "com.djhaskin.yamcl")'

# Run specific test
tools/one-shot-lisp.ros '(fiveam:run! :com.djhaskin.yamcl/tests)'
```

## Notes

- **80-character line limit**: All `.lisp`, `.ros`, and `.md` files
- **OCICL only**: No Quicklisp dependencies
- **TDD required**: Write tests first
- **Stream-based API**: Follow REGR-001 requirements

See `CONTRIBUTING.md` for detailed development guidelines.