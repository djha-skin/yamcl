#!/usr/bin/env sbcl --script

;; Generate user stories for yamcl project
;; This script creates markdown files for user stories US-007 through US-040

(defpackage :story-generator
  (:use :cl)
  (:export :generate-stories))

(in-package :story-generator)

(defparameter *stories*
  '((:id "US-007" :title "Parse boolean true-false"
     :description "Parse boolean values true and false from YAML."
     :examples ("true: true" "false: false" "mixed: [true, false]")
     :test-cases ("true → t" "false → nil" "TRUE → error (case-sensitive)")
     :dependencies ("US-003: Skip Whitespace")
     :notes ("Case-sensitive: true-false not TRUE/FALSE"
             "Returns CL booleans: t and nil"
             "Distinct from strings \"true\"/\"false\"")
     :edge-cases ("TRUE, FALSE (uppercase)" "True, False (mixed case)"
                  "trUE (weird casing)" "inside strings: \"true\""))

    (:id "US-008" :title "Parse null values (null and ~)"
     :description "Parse null values using null keyword or ~ shorthand."
     :examples ("null: null" "tilde: ~" "empty: " "null-in-array: [null, ~]")
     :test-cases ("null → cl:null" "~ → cl:null" "NULL → error")
     :dependencies ("US-003: Skip Whitespace")
     :notes ("null and ~ both map to cl:null symbol"
             "Case-sensitive: null not NULL"
             "Empty value in mapping also represents null?")
     :edge-cases ("NULL (uppercase)" "Null (mixed case)" " ~~ (double tilde)"))

    (:id "US-009" :title "Distinguish null vs false (cl:null vs nil)"
     :description "Ensure null and false are distinguishable in parsed output."
     :examples ("false: false" "null: null" "mixed: {false: false, null: null}")
     :test-cases ("false → nil" "null → cl:null" "~ → cl:null")
     :dependencies ("US-007: Parse boolean true-false" "US-008: Parse null values")
     :notes ("Critical regression fix"
             "false maps to CL's nil"
             "null and ~ map to cl:null symbol"
             "Must be distinguishable for round-trip")
     :edge-cases ("Testing equality: (eq nil cl:null) → nil"
                  "Serialization must preserve distinction"))

    (:id "US-010" :title "Parse double-quoted strings"
     :description "Parse strings enclosed in double quotes."
     :examples ("\"simple string\"" "\"string with spaces\"" "\"line1\\nline2\"")
     :test-cases ("\"hello\" → \"hello\"" "\"\" → \"\" (empty string)")
     :dependencies ("US-003: Skip Whitespace")
     :notes ("Double quotes required"
             "Escape sequences handled in US-013"
             "Multiline strings need special handling")
     :edge-cases ("Unclosed quotes" "Quotes inside string: \"\\\"\""
                  "Empty string" "Only quotes: \"\""))

    (:id "US-011" :title "Parse single-quoted strings"
     :description "Parse strings enclosed in single quotes."
     :examples ("'simple string'" "'it\\'s quoted'" "'multiline\\nstring'")
     :test-cases ("'hello' → \"hello\"" "'' → \"\"")
     :dependencies ("US-003: Skip Whitespace")
     :notes ("Single quotes required"
             "Fewer escapes than double-quoted"
             "'' escapes to '")
     :edge-cases ("Unclosed quotes" "Empty string: ''"
                  "Mixed quotes: ' \" '"))

    (:id "US-012" :title "Parse bareword strings (plain scalars)"
     :description "Parse unquoted strings that don't match other scalar patterns."
     :examples ("bareword" "with-dashes" "with_underscores" "CamelCase")
     :test-cases ("hello → \"hello\"" "hello-world → \"hello-world\"")
     :dependencies ("US-003: Skip Whitespace")
     :notes ("Most common string form in YAML"
             "Can't start with indicator characters"
             "Can contain alphanumerics, dashes, underscores")
     :edge-cases ("Starts with number: 123abc"
                  "Looks like boolean: true (should be string)"
                  "Reserved words"))

    (:id "US-013" :title "Handle escape sequences in double-quoted strings"
     :description "Parse escape sequences in double-quoted strings per JSON RFC."
     :examples ("\"line1\\nline2\"" "\"tab\\tseparated\"" "\"quote\\\"inside\"")
     :test-cases ("\\n → newline" "\\t → tab" "\\\" → \"" "\\\\ → \\")
     :dependencies ("US-010: Parse double-quoted strings")
     :notes ("RFC 8259 Section 7 escapes"
             "\\\", \\\\, \\/, \\b, \\f, \\n, \\r, \\t, \\uXXXX"
             "Critical regression fix")
     :edge-cases ("Invalid escape: \\x" "Unicode: \\u20AC"
                  "Surrogate pairs" "\\/ optional"))

    (:id "US-014" :title "Handle escape sequences in single-quoted strings"
     :description "Parse limited escape sequences in single-quoted strings."
     :examples ("'it\\'s quoted'" "'line1\\nline2'" "'simple'")
     :test-cases ("'' → '" "\\n → \\n (literal)" "other escapes literal")
     :dependencies ("US-011: Parse single-quoted strings")
     :notes ("Only '' escapes to '"
             "All other characters are literal"
             "\\n remains backslash-n")
     :edge-cases ("'''' → ''" "'''s → 's"
                  "Mixed with double quotes"))

    (:id "US-015" :title "Parse simple block mappings (key: value)"
     :description "Parse basic key-value pairs in block style."
     :examples ("key: value" "name: John" "age: 30")
     :test-cases ("key: value → #(\"key\" . \"value\")")
     :dependencies ("US-003: Skip Whitespace" "US-009: Distinguish null vs false")
     :notes ("Key followed by colon and space"
             "Value can be any scalar"
             "Returns hash table or alist")
     :edge-cases ("No space after colon: key:value"
                  "Empty value: key:" "Multiline key?"))

    (:id "US-016" :title "Parse nested block mappings"
     :description "Parse mappings containing other mappings."
     :examples ("outer:\\n  inner: value" "nested:\\n  deeper:\\n    key: value")
     :test-cases ("a: b: c → nested mapping")
     :dependencies ("US-015: Parse simple block mappings")
     :notes ("Indentation determines nesting"
             "Child indented more than parent"
             "Return nested structure")
     :edge-cases ("Inconsistent indentation" "Empty nested mapping"
                  "Very deep nesting"))

    (:id "US-017" :title "Parse simple block sequences (- item)"
     :description "Parse lists in block style starting with dash."
     :examples ("- item1\\n- item2" "- 42\\n- hello\\n- true")
     :test-cases ("- a → (\"a\")" "- a\\n- b → (\"a\" \"b\")")
     :dependencies ("US-003: Skip Whitespace")
     :notes ("Dash followed by space"
             "Returns list"
             "Can mix types")
     :edge-cases ("No space after dash: -item" "Empty item: -"
                  "Dash in middle of line"))

    (:id "US-018" :title "Parse nested block sequences"
     :description "Parse sequences containing other sequences."
     :examples ("-\\n  - nested\\n  - items" "- - deeply\\n    - nested")
     :test-cases ("Nested sequences work")
     :dependencies ("US-017: Parse simple block sequences")
     :notes ("Indentation determines nesting"
             "Child items indented relative to parent dash")
     :edge-cases ("Inconsistent indentation" "Mixed with mappings"
                  "Empty nested sequences"))

    (:id "US-019" :title "Parse mixed mappings and sequences"
     :description "Parse structures containing both mappings and sequences."
     :examples ("list:\\n  - item1\\n  - item2" "- key: value\\n  num: 42")
     :test-cases ("Mapping containing sequence" "Sequence containing mapping")
     :dependencies ("US-015: Parse simple block mappings" "US-017: Parse simple block sequences")
     :notes ("Complex nested structures"
             "YAML's power feature"
             "Return appropriate Lisp structures")
     :edge-cases ("Deeply mixed" "Empty elements"
                  "Alternating types"))

    (:id "US-020" :title "Handle indentation in block collections"
     :description "Properly handle indentation levels for block collections."
     :examples ("key:\\n  value" "- item\\n  nested: value")
     :test-cases ("Indentation preserved" "Dedent ends collection")
     :dependencies ("US-015: Parse simple block mappings" "US-017: Parse simple block sequences")
     :notes ("Spaces (not tabs) for indentation"
             "Indentation level determines scope"
             "Same or less indentation ends current collection")
     :edge-cases ("Tabs vs spaces" "Inconsistent indentation"
                  "Zero indent" "Very deep indent"))

    (:id "US-021" :title "Parse flow sequences [a, b, c]"
     :description "Parse sequences in flow style with brackets."
     :examples ("[a, b, c]" "[1, 2, 3]" "[\"hello\", true, null]")
     :test-cases ("[] → empty list" "[a] → (\"a\")" "[a, b] → (\"a\" \"b\")")
     :dependencies ("US-003: Skip Whitespace" "US-009: Distinguish null vs false")
     :notes ("JSON-like array syntax"
             "Comma-separated"
             "Returns list")
     :edge-cases ("Trailing comma: [a,]" "No commas: [a b] error"
                  "Empty: []" "Nested: [[a]]"))

    (:id "US-022" :title "Parse flow mappings {key: value}"
     :description "Parse mappings in flow style with braces."
     :examples ("{a: b, c: d}" "{name: John, age: 30}")
     :test-cases ("{} → empty hash" "{a: b} → #(\"a\" . \"b\")")
     :dependencies ("US-003: Skip Whitespace" "US-009: Distinguish null vs false")
     :notes ("JSON-like object syntax"
             "Comma-separated key-value pairs"
             "Returns hash table")
     :edge-cases ("Trailing comma: {a: b,}" "No colon: {a b} error"
                  "Empty: {}" "Nested: {a: {b: c}}"))

    (:id "US-023" :title "Parse nested flow collections"
     :description "Parse flow collections containing other flow collections."
     :examples ("[ [a, b], {c: d} ]" "{list: [1, 2], map: {x: y}}")
     :test-cases ("Nested works" "Mixed nesting works")
     :dependencies ("US-021: Parse flow sequences" "US-022: Parse flow mappings")
     :notes ("Arbitrary nesting"
             "Flow collections inside block collections"
             "Return appropriate nested structures")
     :edge-cases ("Deep nesting" "Mixed flow/block"
                  "Empty nested collections"))

    (:id "US-024" :title "Parse empty collections"
     :description "Parse empty sequences and mappings."
     :examples ("[]" "{}" "empty_seq:\\n" "empty_map:\\n")
     :test-cases ("[] → ()" "{} → #()" "key: → #(\"key\" . null)")
     :dependencies ("US-021: Parse flow sequences" "US-022: Parse flow mappings" "US-015: Parse simple block mappings")
     :notes ("Empty flow collections"
             "Empty block collections"
             "Empty value in mapping")
     :edge-cases ("[] vs {}" "Empty with whitespace"
                  "Multiple empties"))

    (:id "US-025" :title "Parse literal block scalars (|)"
     :description "Parse multi-line strings using literal block scalar syntax."
     :examples ("|\\n  line1\\n  line2\\n  line3")
     :test-cases ("Preserves newlines" "Handles indentation")
     :dependencies ("US-003: Skip Whitespace" "US-010: Parse double-quoted strings")
     :notes ("Pipe character starts literal block"
             "Preserves line breaks exactly"
             "Indentation stripped from each line")
     :edge-cases ("Empty block" "Single line"
                  "Trailing spaces" "Mixed indentation"))

    (:id "US-026" :title "Parse folded block scalars (>)"
     :description "Parse multi-line strings using folded block scalar syntax."
     :examples (">\\n  folded\\n  lines\\n  here")
     :test-cases ("Folds single newlines" "Preserves blank lines")
     :dependencies ("US-003: Skip Whitespace" "US-010: Parse double-quoted strings")
     :notes ("Greater-than starts folded block"
             "Single newlines become spaces"
             "Blank lines preserved as newlines")
     :edge-cases ("Empty block" "Leading/trailing newlines"
                  "Complex folding cases"))

    (:id "US-027" :title "Handle chomping modes (strip, clip, keep)"
     :description "Handle trailing newline behavior in block scalars."
     :examples ("|-  # strip\\n  content" "|+  # keep\\n  content\\n")
     :test-cases ("|- strips trailing newlines" "|+ keeps all newlines" "| clips")
     :dependencies ("US-025: Parse literal block scalars" "US-026: Parse folded block scalars")
     :notes ("Strip (-): remove trailing newlines"
             "Clip (default): single trailing newline"
             "Keep (+): keep all newlines")
     :edge-cases ("Empty with chomping" "Multiple trailing newlines"
                  "Chomping with indentation"))

    (:id "US-028" :title "Handle indentation indicators"
     :description "Handle explicit indentation specification in block scalars."
     :examples ("|2\\n    content" ">1\\n   folded")
     :test-cases ("Explicit indent respected" "Auto-detect when not specified")
     :dependencies ("US-025: Parse literal block scalars" "US-026: Parse folded block scalars")
     :notes ("Number after | or > specifies indentation"
             "0-9 allowed"
             "Indentation stripped from each line")
     :edge-cases ("Indent 0" "Large indent"
                  "Invalid indent indicator"))

    (:id "US-029" :title "Parse anchors (&anchor)"
     :description "Parse YAML anchors for node reuse."
     :examples ("&anchor value" "key: &name value")
     :test-cases ("&anchor creates anchor" "Can reference later")
     :dependencies ("US-003: Skip Whitespace")
     :notes ("Ampersand followed by name"
             "Anchors can be on any node"
             "Store for alias resolution")
     :edge-cases ("Duplicate anchor names" "Anchor on empty node"
                  "Complex anchor names"))

    (:id "US-030" :title "Parse aliases (*alias)"
     :description "Parse YAML aliases that reference anchors."
     :examples ("*anchor" "key: *name")
     :test-cases ("*alias references anchor" "Error if anchor not defined")
     :dependencies ("US-029: Parse anchors")
     :notes ("Asterisk followed by anchor name"
             "Resolves to anchored value"
             "Circular reference detection")
     :edge-cases ("Undefined alias" "Self-reference"
                  "Nested aliases"))

    (:id "US-031" :title "Parse tags (!!type)"
     :description "Parse explicit type tags in YAML."
     :examples ("!!str 123" "!!int \"42\"" "!!bool true")
     :test-cases ("Tags influence parsing" "Standard tags supported")
     :dependencies ("US-003: Skip Whitespace")
     :notes ("Exclamation marks indicate tag"
             "Standard tags: !!str, !!int, !!bool, etc."
             "Custom tags possible")
     :edge-cases ("Unknown tags" "Conflicting tags"
                  "Tag shorthand: !local"))

    (:id "US-032" :title "Parse directives (%YAML, %TAG)"
     :description "Parse YAML directives for document configuration."
     :examples ("%YAML 1.2" "%TAG ! !foo:" "%%TAG !yaml! tag:yaml.org,2002:")
     :test-cases ("Directives parsed" "Affect document parsing")
     :dependencies ("US-003: Skip Whitespace")
     :notes ("Percent sign starts directive"
             "YAML version directive"
             "TAG directive for custom tags")
     :edge-cases ("Unknown directives" "Multiple directives"
                  "Directive in middle of document"))

    (:id "US-033" :title "Handle multiple documents"
     :description "Parse stream containing multiple YAML documents."
     :examples ("---\\ndoc1\\n...\\n---\\ndoc2\\n...")
     :test-cases ("Multiple docs parsed" "Can iterate through docs")
     :dependencies ("US-004: Handle Document Markers")
     :notes ("--- starts document"
             "... ends document"
             "Return list or stream of documents")
     :edge-cases ("Empty documents" "No document markers"
                  "Mixed directives across docs"))

    (:id "US-034" :title "Generate JSON scalar values"
     :description "Generate YAML/JSON output for scalar values."
     :examples ("42 → 42" "\"hello\" → \"hello\"" "t → true" "nil → false")
     :test-cases ("Round-trip for scalars" "Proper escaping")
     :dependencies ("US-009: Distinguish null vs false" "US-013: Handle escape sequences")
     :notes ("Inverse of parsing"
             "cl:null → null" "nil → false" "t → true"
             "Numbers as-is" "Strings escaped")
     :edge-cases ("Special floats: NaN, Infinity"
                  "Large integers" "Unicode strings"))

    (:id "US-035" :title "Generate strings with proper escaping"
     :description "Generate string output with correct escaping for special characters."
     :examples ("\\n → \\\\n" "\" → \\\"" "control chars → \\uXXXX")
     :test-cases ("Escaping works" "Round-trip preserves string")
     :dependencies ("US-013: Handle escape sequences in double-quoted strings")
     :notes ("Critical regression fix"
             "RFC 8259 escaping"
             "Control characters escaped"
             "Unicode escapes")
     :edge-cases ("Already escaped sequences" "Mixed escaping"
                  "Invalid Unicode"))

    (:id "US-036" :title "Generate block mappings"
     :description "Generate block-style mappings from Lisp data structures."
     :examples ("#(\"a\" . \"b\") → a: b" "hash table → key: value")
     :test-cases ("Simple mapping" "Nested mapping")
     :dependencies ("US-034: Generate JSON scalar values" "US-015: Parse simple block mappings")
     :notes ("Hash tables or alists to YAML mappings"
             "Proper indentation"
             "Key sorting (optional)")
     :edge-cases ("Empty mapping" "Very wide mapping"
                  "Complex keys"))

    (:id "US-037" :title "Generate block sequences"
     :description "Generate block-style sequences from Lisp lists."
     :examples ("(a b c) → - a\\n- b\\n- c")
     :test-cases ("Simple list" "Nested list")
     :dependencies ("US-034: Generate JSON scalar values" "US-017: Parse simple block sequences")
     :notes ("Lists to YAML sequences"
             "Proper indentation"
             "Dash prefix for items")
     :edge-cases ("Empty list" "Very long list"
                  "Mixed types"))

    (:id "US-038" :title "Generate flow collections"
     :description "Generate flow-style sequences and mappings."
     :examples ("(a b) → [a, b]" "#(\"a\" . \"b\") → {a: b}")
     :test-cases ("Flow output" "Compact representation")
     :dependencies ("US-034: Generate JSON scalar values" "US-021: Parse flow sequences" "US-022: Parse flow mappings")
     :notes ("Lists to [] arrays"
             "Hash tables to {} objects"
             "Compact single-line format")
     :edge-cases ("Empty collections" "Nested flow"
                  "When to choose flow vs block"))

    (:id "US-039" :title "Generate multi-line strings"
     :description "Generate block scalars for multi-line strings."
     :examples ("line1\\nline2 → |\\n  line1\\n  line2")
     :test-cases ("Literal blocks" "Folded blocks")
     :dependencies ("US-034: Generate JSON scalar values" "US-025: Parse literal block scalars" "US-026: Parse folded block scalars")
     :notes ("Choose | or > based on content"
             "Handle indentation"
             "Chomping modes")
     :edge-cases ("Empty string" "Very long lines"
                  "When to use block vs quoted"))

    (:id "US-040" :title "Generate with anchors and aliases"
     :description "Generate YAML with anchors and aliases for repeated nodes."
     :examples ("Repeated structure uses &anchor and *alias")
     :test-cases ("Anchors generated" "Aliases used for duplicates")
     :dependencies ("US-034: Generate JSON scalar values" "US-029: Parse anchors" "US-030: Parse aliases")
     :notes ("Detect duplicate structures"
             "Generate anchors"
             "Use aliases for repeats"
             "Prevent circular references")
     :edge-cases ("Self-referential structures" "When not to use anchors"
                  "Anchor naming"))))

(defun format-list (items)
  (format nil "~{~A~^~%~}" items))

(defun sanitize-filename (str)
  "Remove problematic characters from filename."
  (let ((result (make-string-output-stream)))
    (loop for ch across str
          do (if (or (alphanumericp ch) (char= ch #\-) (char= ch #\_))
                 (write-char ch result)
                 (write-char #\- result)))
    (get-output-stream-string result)))

(defun generate-story (story)
  (let* ((id (getf story :id))
         (title (getf story :title))
         (description (getf story :description))
         (examples (getf story :examples))
         (test-cases (getf story :test-cases))
         (dependencies (getf story :dependencies))
         (notes (getf story :notes))
         (edge-cases (getf story :edge-cases))
         (filename (format nil "project-management/user-stories/~A-~A.md"
                          id (sanitize-filename (string-downcase title)))))
    (with-open-file (stream filename :direction :output :if-exists :supersede)
      (format stream "# ~A: ~A~%~%" id title)
      (format stream "## Description~%")
      (format stream "~A~%~%" description)
      (format stream "## YAML Examples~%")
      (format stream "```yaml~%")
      (dolist (ex examples)
        (format stream "~A~%" ex))
      (format stream "```~%~%")
      (format stream "## Test Cases~%")
      (dolist (tc test-cases)
        (format stream "1. **~A**~%" tc))
      (format stream "~%")
      (format stream "## Dependencies~%")
      (if dependencies
          (dolist (dep dependencies)
            (format stream "- ~A~%" dep))
          (format stream "- None~%"))
      (format stream "~%")
      (format stream "## Implementation Notes~%")
      (dolist (note notes)
        (format stream "- ~A~%" note))
      (format stream "~%")
      (format stream "## Edge Cases~%")
      (dolist (ec edge-cases)
        (format stream "- ~A~%" ec))
      (format stream "~%"))
    (format t "Generated ~A~%" filename)))

(defun generate-stories ()
  (dolist (story *stories*)
    (generate-story story)))

;; Run the generator
(generate-stories)