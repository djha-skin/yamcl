# Contributing to yamcl

This document is for human and AI developers working on this project.

## Code Style and Conventions

- **Line Length**: No files—Lisp, Markdown, or Roswell scripts—should
  exceed **80 characters** per line.
- **Trailing Whitespace**: Stick to this rule. Please do not commit files
  with trailing whitespace in them.
- **ASDF System**: Use the reverse-domain ASDF package name
  (`com.djhaskin.yamcl`).
- **Dependencies**: Managed via **OCICL**. We do not use Quicklisp.
- **Testing**: Use **Parachute** for unit tests.

## Package Structure

The library is contained in a single package:

- `com.djhaskin.yamcl` — The main library package

## REPL Interaction

The Lisp instance should be started using `ros run` in the designated
REPL pane of the tmux session.

Specific workflow details for AI agents are located in `AGENTS.md`.

## Building the Program

The library is an ASDF system. Load it with:

```lisp
(asdf:load-system "com.djhaskin.yamcl")
```

Run tests with:

```lisp
(asdf:test-system "com.djhaskin.yamcl")
```

## Tooling

This section describes the libraries and build tools used in `yamcl`.

### Roswell

[Roswell](https://github.com/roswell/roswell) (`ros`) is the Common
Lisp implementation manager and script runner used for this project.

**Important**: Always invoke `ros` with the `+Q` flag to disable
Quicklisp. We do not use Quicklisp. Omitting `+Q` may cause Quicklisp
to interfere with OCICL-managed dependencies.

```
ros +Q run          # Start a REPL without Quicklisp
```

### OCICL

[OCICL](https://github.com/ocicl/ocicl) is the dependency manager for
this project. It is a modern alternative to Quicklisp that distributes
ASDF systems as OCI-compliant container image artifacts.

**We do not use Quicklisp.** Do not add Quicklisp-based loading to
any file in this project.

### Parachute

[Parachute](https://shinmera.github.io/parachute/) is the testing
framework used in the `tests/` directory.

Tests are defined with `parachute:define-test` and assertions use
macros like `parachute:is`, `parachute:true`, `parachute:false`,
and `parachute:fail`.

**Running tests** from the REPL:

```lisp
(asdf:test-system "com.djhaskin.yamcl")
```

### Testing Workflow (TDD)

We practice Test-Driven Development:

1. **Tests First**: Write a failing test in `tests/main.lisp`
2. **Implement**: Add code in `src/main.lisp` to make the test pass
3. **Refactor**: Clean up code while keeping tests passing

## API Reference

### Main Functions

- `parse-from (stream)` — Parse YAML from a stream or string
- `generate-to (stream value &key pretty-indent json-mode)` — Render
  YAML to a stream or string

### Constants

- `+eof+` — End-of-file marker (`:eof`)

### Conditions

- `extraction-error` — Signaled on parse errors

## YAML Support Roadmap

See `ROADMAP.md` for the full feature breakdown and implementation order.
