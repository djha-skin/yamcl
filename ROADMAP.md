# yamcl Roadmap

This document outlines the planned features and implementation order
for yamcl (YAML Ain't Markup Language -- Common Lisp).

## Current Status

The project is initialized with basic structure, ASDF system, and
placeholder implementations.

## Feature Implementation Order

Features are broken down into small, manageable chunks following TDD
principles. Each feature should have tests before implementation.

---

### Phase 1: Foundation

#### 1. Comments

**Status**: Not started

Parse comments (lines starting with `#`) and ignore them.

**YAML Examples**:
```yaml
# This is a comment
key: value  # inline comment
```

**Tests Needed**:
- Comment-only lines
- Comments after content
- Multiple consecutive comments

---

#### 2. JSON Scalar Values

**Status**: Not started

Parse JSON-compatible scalar values as native Lisp types.

**Types to Support**:
- Strings (double-quoted)
- Integers (decimal)
- Floats (with optional exponent)
- Booleans (`true`, `false`)
- Null (`null`, `~`)

**YAML Examples**:
```yaml
string: "hello"
integer: 42
float: 3.14
boolean-true: true
boolean-false: false
null-value: null
```

**Tests Needed**:
- Basic strings
- Integers (positive, negative, zero)
- Floats (decimal, scientific notation)
- Booleans
- Null values

---

#### 3. Bareword Strings

**Status**: Not started

Parse unquoted scalar strings (plain scalars).

**YAML Examples**:
```yaml
unquoted: this is a string
with-dashes: hello-world
with-underscores: hello_world
```

**Tests Needed**:
- Basic barewords
- Strings with hyphens
- Strings with underscores
- Edge cases

---

#### 4. Block Key-Value Pairs (Mappings)

**Status**: Not started

Parse block-style key-value pairs (mappings).

**YAML Examples**:
```yaml
key: value
another: 123
nested:
  inner: value
```

**Tests Needed**:
- Simple key-value pairs
- Nested mappings
- Deep nesting
- Mixed values

---

#### 5. Block Lists (Sequences)

**Status**: Not started

Parse block-style lists (sequences).

**YAML Examples**:
```yaml
- item1
- item2
- item3
```

**Tests Needed**:
- Simple lists
- Nested lists
- Mixed content lists

---

#### 6. Combined Mappings and Sequences

**Status**: Not started

Parse documents with both mappings and sequences.

**YAML Examples**:
```yaml
name: John
languages:
  - Lisp
  - Python
skills:
  coding: true
  debugging: false
```

**Tests Needed**:
- Mappings containing sequences
- Sequences containing mappings
- Complex nested structures

---

### Phase 2: Flow Style

#### 7. Flow Sequences

**Status**: Not started

Parse flow-style sequences `[item1, item2, item3]`.

**YAML Examples**:
```yaml
[one, two, three]
```

**Tests Needed**:
- Basic flow sequences
- Nested flow sequences
- Empty sequences

---

#### 8. Flow Mappings

**Status**: Not started

Parse flow-style mappings `{key: value}`.

**YAML Examples**:
```yaml
{key: value, another: 123}
```

**Tests Needed**:
- Basic flow mappings
- Nested flow mappings
- Empty mappings

---

### Phase 3: Multi-line Strings

#### 9. Literal Block Scalars

**Status**: Not started

Parse literal block scalars (using `|`).

**YAML Examples**:
```yaml
literal: |
  Line one
  Line two
  Line three
```

**Tests Needed**:
- Basic literal blocks
- Indentation handling
- Chomping modes (strip, clip, keep)

---

#### 10. Folded Block Scalars

**Status**: Not started

Parse folded block scalars (using `>`).

**YAML Examples**:
```yaml
folded: >
  This is a long
  paragraph that will
  be folded.
```

**Tests Needed**:
- Basic folded blocks
- Folding behavior
- Chomping modes

---

### Phase 4: Advanced Features

#### 11. Quoted Strings

**Status**: Not started

Parse single-quoted and escaped double-quoted strings.

**YAML Examples**:
```yaml
single: 'hello'
double: "hello\nworld"
escaped: "tab:\t newline:\n"
```

**Tests Needed**:
- Single-quoted strings
- Double-quoted strings
- Escape sequences

---

#### 12. Anchors and Aliases

**Status**: Not started

Support for YAML anchors (`&`) and aliases (`*`).

**YAML Examples**:
```yaml
anchor: &name "value"
alias: *name
```

**Tests Needed**:
- Basic anchors
- Alias references
- Nested anchors

---

#### 13. Tags

**Status**: Not started

Support for explicit type tags.

**YAML Examples**:
```yaml
string: !!str 123
int: !!int "42"
```

**Tests Needed**:
- Named tags
- Shorthand tags
- Custom tags

---

#### 14. Directives

**Status**: Not started

Support for YAML directives (`%YAML`, `%TAG`).

**YAML Examples**:
```yaml
%YAML 1.2
---
document: content
```

**Tests Needed**:
- YAML directive
- Document markers
- Multiple documents

---

### Phase 5: Generation (Rendering)

#### 15. Generate Basic YAML

**Status**: Not started

Render basic YAML from Lisp data structures.

**Tests Needed**:
- Generate scalars
- Generate mappings
- Generate sequences
- Pretty printing

---

#### 16. Generate Flow Style

**Status**: Not started

Render flow-style collections.

**Tests Needed**:
- Flow sequences
- Flow mappings
- Nested flow style

---

#### 17. Generate Block Scalars

**Status**: Not started

Render multi-line strings as block scalars.

**Tests Needed**:
- Literal blocks
- Folded blocks
- Chomping modes

---

#### 18. JSON Mode

**Status**: Not started

Generate JSON-compatible output.

**Tests Needed**:
- JSON output format
- No anchors/tags in JSON mode

---

## Completed Work

- [x] Project initialization
- [x] ASDF system setup
- [x] Basic package structure
- [x] Placeholder implementations

## Feature Checklist

### Foundation
- [ ] Comments
- [ ] JSON scalar values
- [ ] Bareword strings
- [ ] Block key-value pairs
- [ ] Block lists
- [ ] Combined structures

### Flow Style
- [ ] Flow sequences
- [ ] Flow mappings

### Multi-line Strings
- [ ] Literal block scalars
- [ ] Folded block scalars

### Advanced
- [ ] Quoted strings
- [ ] Anchors and aliases
- [ ] Tags
- [ ] Directives

### Generation
- [ ] Basic YAML generation
- [ ] Flow style generation
- [ ] Block scalar generation
- [ ] JSON mode generation
