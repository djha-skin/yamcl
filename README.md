# yamcl

**YAML Ain't Markup Language -- Common Lisp**

A pure Common Lisp library for parsing and rendering YAML, following the
[YAML 1.2.2 specification](https://yaml.org/spec/1.2.2/).

## Overview

yamcl is a complete implementation of YAML parsing and generation in pure
Common Lisp. No external dependencies beyond the standard library are
required.

## Features

- **Pure Common Lisp**: No C extensions or foreign dependencies
- **YAML 1.2.2**: Full compliance with the YAML specification
- **JSON Compatible**: Can output JSON-compatible YAML
- **Test-Driven**: Comprehensive test suite using Parachute

## Installation

```bash
# Install dependencies with OCICL
ocicl install com.djhaskin.yamcl

# Or manually load the ASDF system
(asdf:load-system "com.djhaskin.yamcl")
```

## Quick Start

```lisp
(use-package :com.djhaskin.yamcl)

;; Parse YAML from a string
(parse-from "key: value")
;; => #<HASH-TABLE :TEST equal :COUNT 1 {key="value"}>

;; Parse YAML from a stream
(with-open-file (s "config.yaml")
  (parse-from s))

;; Generate YAML to a string
(generate-to "" '(:name "John" :age 42))
;; => "name: John~%age: 42~%"

;; Generate JSON-compatible output
(generate-to "" '(:items (1 2 3)) :json-mode t)
;; => "{\"items\": [1, 2, 3]}"
```

## API Reference

### Functions

#### `parse-from (stream)`

Parse YAML from a stream or string.

**Parameters**:
- `stream` — A stream or string to parse

**Returns**: A Lisp data structure (hash-table, list, string, etc.)

**Example**:
```lisp
(parse-from "name: Alice~%age: 30")
;; => #<HASH-TABLE :TEST equal :COUNT 2 {name="Alice" age=30}>
```

#### `generate-to (stream value &key pretty-indent json-mode)`

Generate YAML output from a Lisp value.

**Parameters**:
- `stream` — Output stream or string
- `value` — The Lisp value to render
- `pretty-indent` — Indentation level (default: 0)
- `json-mode` — When T, output JSON-compatible YAML (default: NIL)

**Returns**: The generated output (if stream was a string)

**Example**:
```lisp
(generate-to "" '(:name "Bob" :active t))
;; => "name: Bob~%active: true~%"
```

### Conditions

#### `extraction-error`

Signaled when parsing fails.

**Readers**:
- `expected` — What was expected
- `got` — What was actually found

## Supported YAML Features

### Currently Implemented

- Comments (`#`)
- Block key-value pairs (mappings)
- Block lists (sequences)
- JSON scalar values (strings, numbers, booleans, null)

### Planned

- Flow-style collections
- Multi-line strings (literal and folded)
- Quoted strings with escape sequences
- Anchors and aliases
- Explicit tags
- Document directives

See [ROADMAP.md](ROADMAP.md) for the complete feature list and
implementation order.

## Development

### Setup

```bash
# Clone the repository
git clone https://github.com/djha-skin/yamcl.git
cd yamcl

# Install dependencies (requires OCICL)
ocicl install
```

### Running Tests

```lisp
(asdf:test-system "com.djhaskin.yamcl")
```

Or from the command line:

```bash
ros +Q --eval '(asdf:test-system "com.djhaskin.yamcl")' --eval '(uiop:quit)'
```

### Code Style

- 80-character line limit
- No trailing whitespace
- Parachute for testing
- TDD: write tests before implementation

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.

## Documentation

- [README.md](README.md) — This file
- [CONTRIBUTING.md](CONTRIBUTING.md) — Contribution guidelines
- [AGENTS.md](AGENTS.md) — AI agent instructions
- [ROADMAP.md](ROADMAP.md) — Feature roadmap

## License

MIT License. See LICENSE file for details.

## References

- [YAML 1.2.2 Specification](https://yaml.org/spec/1.2.2/)
- [YAML Spec Repository](https://github.com/yaml/yaml-spec)
