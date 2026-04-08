# Agent Workflow Notes

This document is exclusively for LLM contributors working on yamcl.

> **Important**: Please make sure to read `CONTRIBUTING.md` before
> starting any work on this project. It contains essential information
> about tooling, code style, and common workflows that apply to all
> contributors, including AI agents.

## Project Overview

yamcl (YAML Ain't Markup Language -- Common Lisp) is a pure Common
Lisp library for parsing and rendering YAML. It follows the YAML 1.2.2
specification.

## Core Rules

- **Line Length**: All `.lisp`, `.ros`, and `.md` files must adhere to
  a strict **80-character** limit.
- **No Quicklisp**: Use OCICL for all dependency management.
- **TDD**: Always write tests before implementing features.

## Design Decisions

- **Package naming**: Reverse-domain ASDF package name
  (`com.djhaskin.yamcl`).
- **Dependencies**: OCICL (not Quicklisp). Only `alexandria` and
  `parachute` for testing.
- **Testing**: Parachute library for Test-Driven Development (TDD).
- **EOF marker**: Uses `:eof` constant (same as nrdl project).

## Development Workflow (TDD)

1. **Read the Spec**: Study the YAML 1.2.2 specification
2. **Write Test**: Add a failing test in `tests/main.lisp`
3. **Run Tests**: Verify the test fails
4. **Implement**: Write code in `src/main.lisp` to pass the test
5. **Run Tests**: Verify the test passes
6. **Refactor**: Clean up code while keeping tests green

## REPL and Environment

The development environment is inside a **tmux** session with panes
for:

- **Lisp REPL/Running**: Invoke with the `cl-mcp` tool or the `tools/one-shot-lisp.ros`
  script
- **Goose CLI**: This session
- **Manual commands**: Shell pane

### Running Lisp

There are two good ways to interact with or run arbitrary lisp code:

1. Use `tools/one-shot-lisp.ros '(code)'` for one-off commands
2. Use the `cl-mcp` MCP tool

Example:

```bash 
tools/one-shot-lisp.ros '(format t "~A~%" (com.djhaskin.yamcl:+eof+))'
```

## YAML Implementation Approach

We follow the YAML 1.2.2 specification available at:
https://raw.githubusercontent.com/yaml/yaml-spec/refs/heads/main/spec/1.2.2/spec.md

### Implementation Order (from ROADMAP.md)

1. **Comments** — Parse `#` to end of line
2. **JSON Scalars** — Strings, numbers, booleans, null
3. **Block Key-Value Pairs** — Basic mapping
4. **Block Lists** — Basic sequences

After these basics:
5. Flow style collections
6. Multi-line strings
7. Anchors and aliases
8. Tags
9. Directives

## Key Data Types

The library represents YAML structures using standard Lisp types:

- **Mappings**: Hash tables with string keys
- **Sequences**: Lists
- **Scalars**: Strings, numbers, booleans, or `nil` (for null)

## Important Functions

- `parse-from` — Parse YAML input
- `generate-to` — Render YAML output
- `+eof+` — End-of-file marker (`:eof`)

## Project Vision

The goal is a complete, pure Common Lisp implementation of YAML 1.2.2
parsing and rendering, suitable for production use.
