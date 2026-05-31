;;;; tests/main.lisp
;;;; yamcl - YAML Ain't Markup Language -- Common Lisp
;;;; Test suite organized by user stories

(cl:defpackage :com.djhaskin.yamcl/tests
  (:use :cl :com.djhaskin.yamcl :com.djhaskin.yamcl/utils)
  (:import-from :org.shirakumo.parachute
                :define-test
                :true
                :false
                :fail
                :is
                :isnt
                :of-type
                :finish
                :skip
                :test)
  (:export :run-all-tests
           :yamcl-tests
           :phase-1-foundation
           :us-001-parse-line-comments
           :us-002-parse-inline-comments
           :us-003-skip-whitespace
           :us-004-handle-document-markers
           :us-005-parse-integer-numbers
           :us-006-parse-float-numbers
           :us-007-parse-boolean-true-false
           :us-008-parse-null-values
           :us-009-distinguish-null-vs-false
           :us-010-parse-double-quoted-strings
           :us-011-parse-single-quoted-strings
           :us-012-parse-bareword-strings
           :us-013-handle-escape-sequences-double-quoted
           :us-014-handle-escape-sequences-single-quoted
           :us-015-parse-simple-block-mappings
           :us-016-parse-nested-block-mappings
           :us-017-parse-simple-block-sequences
           :us-018-parse-nested-block-sequences
           :us-019-parse-mixed-mappings-and-sequences
           :us-020-handle-indentation-in-block-collections))

(cl:in-package :com.djhaskin.yamcl/tests)

;;; Top-level test suite
(define-test yamcl-tests
  "Top-level test suite for yamcl.")

;;; Phase 1: Foundation Tests

(define-test phase-1-foundation
  :parent yamcl-tests
  "Phase 1: Comments, whitespace, and basic scalar parsing.")

(define-test us-001-parse-line-comments
  :parent phase-1-foundation
  "US-001: Parse Line Comments"
  ;; Test 1: Comment before scalar
  (is eql (parse-from-string (format nil "# comment~%123")) 123
      "Comment before number should be ignored")

  ;; Test 2: Multiple comments
  (is eql (parse-from-string (format nil "# first~%# second~%456")) 456
      "Multiple comments should be ignored")

  ;; Test 3: Comment with whitespace
  (is eql (parse-from-string (format nil "   # indented comment~%789")) 789
      "Indented comments should be ignored")

  ;; Test 4: Empty comment
  (is eql (parse-from-string (format nil "#~%42")) 42
      "Empty comment should be ignored")

  ;; Test 5: Comment after scalar (inline comment)
  (is eql (parse-from-string "999 # inline comment") 999
      "Inline comment should be ignored")

  ;; Test 6: Comment at EOF
  (is eq (parse-from-string "# just a comment") +eof+
      "Just a comment should return EOF"))

(define-test us-002-parse-inline-comments
  :parent phase-1-foundation
  "US-002: Parse Inline Comments"
  ;; Test 1: Comment after number
  (is = (parse-from-string "42 # comment") 42
      "Comment after number should be ignored")

  ;; Test 2: Comment after negative number
  (is = (parse-from-string "-100 # negative") -100
      "Comment after negative number should be ignored")

  ;; Test 3: Multiple spaces before comment
  (is = (parse-from-string "999    # spaced comment") 999
      "Multiple spaces before comment should work")

  ;; Test 4: Tab before comment
  (is = (parse-from-string "123	# tab comment") 123
      "Tab before comment should work")

  ;; Test 5: Comment with special characters
  (is = (parse-from-string "777 # !@#$%^&*()") 777
      "Special characters in comment should be ignored")

  ;; Test 6: Comment at EOF (no newline)
  (is = (parse-from-string "888#no space") 888
      "Comment without space should work")

  ;; Test 7: Empty value with comment
  (is eq (parse-from-string "# just a comment") +eof+
      "Just a comment should return EOF"))

(define-test us-003-skip-whitespace
  :parent phase-1-foundation
  "US-003: Skip Whitespace"
  ;; Test 1: Leading spaces
  (is = (parse-from-string "    42") 42
      "Leading spaces should be skipped")

  ;; Test 2: Leading tabs
  (is = (parse-from-string "		100") 100
      "Leading tabs should be skipped")

  ;; Test 3: Trailing spaces
  (is = (parse-from-string "999    ") 999
      "Trailing spaces should be skipped")

  ;; Test 4: Mixed whitespace
  (is = (parse-from-string "	 777	 ") 777
      "Mixed spaces and tabs should be skipped")

  ;; Test 5: Newlines (CR, LF, CRLF)
  (is = (parse-from-string (format nil "~C42" #\Newline)) 42
      "LF newline should be skipped")

  (is = (parse-from-string (format nil "~C100" #\Return)) 100
      "CR newline should be skipped")

  (is = (parse-from-string (format nil "~C~C999" #\Return #\Newline)) 999
      "CRLF newline should be skipped")

  ;; Test 6: Multiple newlines
  (is = (parse-from-string (format nil "~C~C~C123" #\Newline #\Newline #\Newline)) 123
      "Multiple newlines should be skipped")

  ;; Test 7: Whitespace with comments
  (is = (parse-from-string "  456   # comment with spaces  ") 456
      "Whitespace with comments should be handled"))

(define-test us-004-handle-document-markers
  :parent phase-1-foundation
  "US-004: Handle Document Markers"
  ;; Test 1: Document start marker
  (is eq (parse-from-string "---") +eof+
      "Document start marker should return EOF for empty document")
  
  ;; Test 2: Document with content after start marker
  (is = (parse-from-string "--- 42") 42
      "Content after document start should parse")
  
  ;; Test 3: Document end marker
  (is eq (parse-from-string "...") +eof+
      "Document end marker should return EOF")
  
  ;; Test 4: Multiple documents
  (with-input-from-string (stream (format nil "--- 42~%...~%--- 99"))
    (is = (parse-from stream) 42 "First document should parse")
    (is eq (parse-from stream) +eof+ "End marker should return EOF")
    (is = (parse-from stream) 99 "Second document should parse"))
  
  ;; Test 5: Marker with whitespace
  (is = (parse-from-string "---    100") 100
      "Marker with trailing spaces should work")
  
  ;; Test 6: Marker with comment
  (is = (parse-from-string (format nil "--- # comment~%200")) 200
      "Marker with comment should work")
  
  ;; Test 7: Partial marker should cause an error
  (skip "Partial dash marker should cause error (not implemented yet)")
  
  ;; Test 8: Marker in middle of content (should not be treated as marker)
  (skip "Plain scalars (unquoted strings) not implemented yet (US-012)")
  
  ;; Test 9: Empty document
  (with-input-from-string (stream (format nil "---~%..."))
    (is eq (parse-from stream) +eof+ "Empty document should return EOF"))
  
  ;; Test 10: Document with only comments
  (with-input-from-string (stream (format nil "--- # comment~%..."))
    (is eq (parse-from stream) +eof+ "Document with only comments should return EOF")))

(define-test us-005-parse-integer-numbers
  :parent phase-1-foundation
  "US-005: Parse Integer Numbers"
  ;; Test 1: Positive integers
  (is = (parse-from-string "42") 42
      "Positive integer should parse")

  ;; Test 2: Negative integers
  (is = (parse-from-string "-42") -42
      "Negative integer should parse")

  ;; Test 3: Zero
  (is = (parse-from-string "0") 0
      "Zero should parse")

  ;; Test 4: Large numbers
  (is = (parse-from-string "1000000") 1000000
      "Large number should parse")

  ;; Test 5: Octal notation
  (is = (parse-from-string "0o52") 42 "Octal should parse")

  ;; Test 6: Hexadecimal notation
  (is = (parse-from-string "0x2A") 42 "Hexadecimal should parse")

  ;; Test 7: Binary notation
  (is = (parse-from-string "0b101010") 42 "Binary should parse")

  ;; Test 8: With underscores
  (is = (parse-from-string "1_000_000") 1000000 "Underscores should be ignored")

  ;; Test 9: Leading zeros (should be decimal, not octal)
  (is = (parse-from-string "0012") 12
      "Leading zeros should be decimal")

  ;; Additional tests for edge cases
  ;; Test 10: Hex with lowercase
  (is = (parse-from-string "0x2a") 42 "Hexadecimal lowercase should parse")

  ;; Test 11: Hex with mixed case
  (is = (parse-from-string "0xDeAdBeEf") 3735928559 "Hex mixed case should parse")

  ;; Test 12: Very large integer
  (is = (parse-from-string "999999999999999999999999") 999999999999999999999999
      "Very large integer should parse")

  ;; Test 13: Binary with underscores
  (is = (parse-from-string "0b1010_1010") 170 "Binary with underscores should parse")

  ;; Test 14: Octal with underscores
  (is = (parse-from-string "0o7_7_7") 511 "Octal with underscores should parse"))

(define-test us-006-parse-float-numbers
  :parent phase-1-foundation
  "US-006: Parse Float Numbers"
  ;; Test 1: Simple float
  (is = (parse-from-string "3.14") 3.14
      "Simple float should parse")

  ;; Test 2: Negative float
  (is = (parse-from-string "-3.14") -3.14
      "Negative float should parse")

  ;; Test 3: Exponent notation
  (is = (parse-from-string "6.02e23") 6.02e23
      "Exponent notation should parse")

  ;; Test 4: Negative exponent
  (is = (parse-from-string "1.6e-19") 1.6e-19
      "Negative exponent should parse")

  ;; Test 5: Capital E
  (is = (parse-from-string "3.0E8") 3.0e8
      "Capital E should parse")

  ;; Test 6: With underscores
  (is = (parse-from-string "1_000.5") 1000.5
      "Float with underscores should parse")

  ;; Test 7: Positive infinity
  (is eq (parse-from-string ".inf") :positive-infinity
      ".inf should parse to :positive-infinity keyword")

  ;; Test 8: Positive infinity with explicit plus
  (is eq (parse-from-string "+.inf") :positive-infinity
      "+.inf should parse to :positive-infinity keyword")

  ;; Test 9: Negative infinity
  (is eq (parse-from-string "-.inf") :negative-infinity
      "-.inf should parse to :negative-infinity keyword")

  ;; Test 10: Not a number
  (is eq (parse-from-string ".nan") :not-a-number
      ".nan should parse to :not-a-number keyword")

  ;; Test 11: No leading digit
  (is = (parse-from-string ".5") 0.5
      "No leading digit should parse as 0.5")

  ;; Test 12: Trailing decimal point (should be integer)
  (is = (parse-from-string "3.") 3
      "Trailing decimal point should parse as integer")

  ;; Test 13: Very small number
  (is = (parse-from-string "1.0e-30") 1.0e-30
      "Very small number should parse")

  ;; Test 14: Very large number (but not overflow)
  (is = (parse-from-string "1.0e30") 1.0e30
      "Very large number should parse")

  ;; Test 15: Zero with decimal
  (is = (parse-from-string "0.0") 0.0
      "Zero with decimal should parse as float")

  ;; Test 16: Leading/trailing zeros
  (is = (parse-from-string "0003.1400") 3.14
      "Leading/trailing zeros should parse correctly")

  ;; Test 17: Case variations for special values (should work case-insensitively)
  (is eq (parse-from-string ".INF") :positive-infinity
      ".INF should parse to :positive-infinity keyword (case-insensitive)")
  (is eq (parse-from-string ".Inf") :positive-infinity
      ".Inf should parse to :positive-infinity keyword (case-insensitive)")
  (is eq (parse-from-string "-.INF") :negative-infinity
      "-.INF should parse to :negative-infinity keyword (case-insensitive)")
  (is eq (parse-from-string ".NAN") :not-a-number
      ".NAN should parse to :not-a-number keyword (case-insensitive)"))

(define-test us-007-parse-boolean-true-false
  :parent phase-1-foundation
  "US-007: Parse Boolean true/false"
  ;; Test 1: true → t
  (is eql t (parse-from-string "true")
      "'true' should parse to t")
  
  ;; Test 2: false → nil
  (is eql nil (parse-from-string "false")
      "'false' should parse to nil")
  
  ;; Test 3: TRUE → t (case-insensitive per YAML Core Schema)
  (is eql t (parse-from-string "TRUE")
      "Uppercase TRUE should parse to t (case-insensitive)")
  
  ;; Test 4: True → t (case-insensitive per YAML Core Schema)
  (is eql t (parse-from-string "True")
      "Mixed case True should parse to t (case-insensitive)")
  
  ;; Test 5: False → nil (case-insensitive per YAML Core Schema)
  (is eql nil (parse-from-string "False")
      "Mixed case False should parse to nil (case-insensitive)")
  
  ;; Test 6: FALSE → nil (case-insensitive per YAML Core Schema)
  (is eql nil (parse-from-string "FALSE")
      "Uppercase FALSE should parse to nil (case-insensitive)")
  
  ;; Test 7: trUE should parse as string (weird casing, not a reserved word)
  (is string= "trUE" (parse-from-string "trUE")
      "'trUE' (weird casing) should parse as string, not boolean")
  
  ;; Test 8: Inside double quotes should be string, not boolean
  (skip "String vs boolean distinction - implement after US-010 is no longer skipped"))

(define-test us-008-parse-null-values
  :parent phase-1-foundation
  "US-008: Parse Null Values (null and ~)"
  ;; Test 1: null → cl:null
  (is eq 'cl:null (parse-from-string "null")
      "'null' should parse to cl:null symbol")
  
  ;; Test 2: ~ → cl:null
  (is eq 'cl:null (parse-from-string "~")
      "Tilde should parse to cl:null symbol")
  
  ;; Test 3: NULL → cl:null (case-insensitive per YAML Core Schema)
  (is eq 'cl:null (parse-from-string "NULL")
      "Uppercase NULL should parse to cl:null (case-insensitive)")
  
  ;; Test 4: Null → cl:null (case-insensitive per YAML Core Schema)
  (is eq 'cl:null (parse-from-string "Null")
      "Mixed case Null should parse to cl:null (case-insensitive)")
  
  ;; Test 5: ~~ should parse as string (not null)
  (is string= "~~" (parse-from-string "~~")
      "Double tilde '~~' should parse as string, not null")
  
  ;; Test 6: Empty value handling
  (skip "Empty value handling - may be different story"))

(define-test us-009-distinguish-null-vs-false
  :parent phase-1-foundation
  "US-009: Distinguish null vs false (cl:null vs nil)"
  ;; Test 1: false → nil
  (is eql nil (parse-from-string "false")
      "'false' should parse to nil (CL's false)")
  
  ;; Test 2: null → cl:null
  (is eq 'cl:null (parse-from-string "null")
      "'null' should parse to cl:null symbol")
  
  ;; Test 3: ~ → cl:null
  (is eq 'cl:null (parse-from-string "~")
      "Tilde should parse to cl:null symbol")
  
  ;; Test 4: nil ≠ cl:null
  (isnt eq nil 'cl:null
      "nil and cl:null should be different")
  
  ;; Test 5: Equality test
  (false (eq nil (parse-from-string "null"))
      "nil should not be eq to parsed null")
  
  ;; Test 6: Equality test for false
  (true (eq nil (parse-from-string "false"))
      "nil should be eq to parsed false"))

(define-test us-010-parse-double-quoted-strings
  :parent phase-1-foundation
  "US-010: Parse Double-Quoted Strings"
  ;; Test 1: Simple double-quoted string
  (is string= "hello" (parse-from-string "\"hello\"")
      "Simple double-quoted string should parse")
  
  ;; Test 2: Empty double-quoted string
  (is string= "" (parse-from-string "\"\"")
      "Empty double-quoted string should parse")
  
  ;; Test 3: Double-quoted string with spaces
  (is string= "string with spaces" (parse-from-string "\"string with spaces\"")
      "Double-quoted string with spaces should parse")
  
  ;; Test 4: Quote inside string (escaped)
  (skip "Escaped quotes - implement in US-013")
  
  ;; Test 5: Unclosed double quote should error
  (test-parse-fails "\"unclosed"
      "Unclosed double quote should cause error")
  
  ;; Test 6: Escape sequences (basic)
  (skip "Escape sequences - implement in US-013")
  
  ;; Test 7: Multiline string
  (skip "Multiline strings - different story"))

(define-test us-011-parse-single-quoted-strings
  :parent phase-1-foundation
  "US-011: Parse Single-Quoted Strings"
  ;; Test 1: Simple single-quoted string
  (is string= "hello" (parse-from-string "'hello'")
      "Simple single-quoted string should parse")
  
  ;; Test 2: Empty single-quoted string
  (is string= "" (parse-from-string "''")
      "Empty single-quoted string should parse")
  
  ;; Test 3: Single-quoted string with spaces
  (is string= "string with spaces" (parse-from-string "'string with spaces'")
      "Single-quoted string with spaces should parse")
  
  ;; Test 4: Single quote escape (doubled single quote)
  (is string= "it's quoted" (parse-from-string "'it''s quoted'")
      "Doubled single quote should escape to single quote")
  
  ;; Test 5: Multiple escaped single quotes
  (is string= "can't stop won't stop" (parse-from-string "'can''t stop won''t stop'")
      "Multiple escaped single quotes should work")
  
  ;; Test 6: No other escapes in single-quoted strings
  (is string= "\\n remains as backslash-n" (parse-from-string "'\\n remains as backslash-n'")
      "Backslash-n should not be interpreted as newline in single-quoted strings")
  
  ;; Test 7: Single quotes inside double quotes (should not be escaped)
  (skip "Mixed quotes test - implement after US-010 is no longer skipped")
  
  ;; Test 8: Unclosed single quote should error
  (test-parse-fails "'unclosed"
      "Unclosed single quote should cause error"))

(define-test us-012-parse-bareword-strings
  :parent phase-1-foundation
  "US-012: Parse Bareword Strings (Plain Scalars)"
  ;; Test 1: Simple bareword
  (is string= "hello" (parse-from-string "hello")
      "'hello' should parse as string")
  
  ;; Test 2: Bareword with dash
  (is string= "hello-world" (parse-from-string "hello-world")
      "'hello-world' should parse as string")
  
  ;; Test 3: Bareword with underscore
  (is string= "hello_world" (parse-from-string "hello_world")
      "'hello_world' should parse as string")
  
  ;; Test 4: CamelCase
  (is string= "CamelCase" (parse-from-string "CamelCase")
      "'CamelCase' should parse as string")
  
  ;; Test 5: Starts with underscore
  (is string= "_private" (parse-from-string "_private")
      "'_private' should parse as string")
  
  ;; Test 6: Mixed alphanumeric with dash and underscore
  (is string= "test-123_abc" (parse-from-string "test-123_abc")
      "'test-123_abc' should parse as string")
  
  ;; Test 7: true, false, null should NOT parse as barewords (they're reserved)
  (is eql t (parse-from-string "true")
      "'true' should parse as boolean t, not string")
  (is eql nil (parse-from-string "false")
      "'false' should parse as boolean nil, not string")
  (is eq 'cl:null (parse-from-string "null")
      "'null' should parse as cl:null, not string")
  (is eq 'cl:null (parse-from-string "~")
      "'~~' should parse as cl:null, not string")
  
  ;; Test 8: Case variations according to YAML Core Schema
  ;; According to YAML 1.2.2 Core Schema, these are valid boolean/null values:
  (is eql t (parse-from-string "True")
      "'True' (mixed case) should parse as boolean t according to YAML Core Schema")
  (is eql nil (parse-from-string "FALSE")
      "'FALSE' (all caps) should parse as boolean nil according to YAML Core Schema")
  (is eq 'cl:null (parse-from-string "Null")
      "'Null' (mixed case) should parse as cl:null according to YAML Core Schema")
  
  ;; Test 9: Starts with number (edge case)
  ;; TODO: Decide if 123abc should be bareword or error
  ;; For now, test current behavior
  (skip "Decide if 123abc should be bareword or error"))

(define-test us-013-handle-escape-sequences-double-quoted
  :parent phase-1-foundation
  "US-013: Handle Escape Sequences in Double-Quoted Strings"
  ;; Test 1: \n → newline
  (is string= (format nil "line1~%line2") (parse-from-string "\"line1\\nline2\"")
      "\\n should parse to newline character")
  
  ;; Test 2: \t → tab
  (is string= (format nil "tab~Cseparated" #\Tab) (parse-from-string "\"tab\\tseparated\"")
      "\\t should parse to tab character")
  
  ;; Test 3: \" → "
  (is string= "quote\"inside" (parse-from-string "\"quote\\\"inside\"")
      "\\\" should parse to double quote character")
  
  ;; Test 4: \\ → \
  (is string= "backslash\\here" (parse-from-string "\"backslash\\\\here\"")
      "\\\\ should parse to backslash character")
  
  ;; Test 5: \/ → / (optional according to JSON RFC)
  (is string= "path/name" (parse-from-string "\"path\\/name\"")
      "\\/ should parse to forward slash character")
  
  ;; Test 6: \b → backspace
  (is string= (format nil "back~Cspace" #\Backspace) (parse-from-string "\"back\\bspace\"")
      "\\b should parse to backspace character")
  
  ;; Test 7: \f → form feed
  (is string= (format nil "form~Cfeed" #\Page) (parse-from-string "\"form\\ffeed\"")
      "\\f should parse to form feed character")
  
  ;; Test 8: \r → carriage return
  (is string= (format nil "carriage~Creturn" #\Return) (parse-from-string "\"carriage\\rreturn\"")
      "\\r should parse to carriage return character")
  
  ;; Test 9: Unicode escape \uXXXX
  (is string= "€" (parse-from-string "\"\\u20AC\"")
      "\\u20AC should parse to Euro sign")
  
  ;; Test 10: Invalid escape should error
  (false (parse-succeeds-p "\"\\x\"")
         "Invalid escape sequence \\x should cause error")
  
  ;; Test 11: Incomplete Unicode escape should error
  (false (parse-succeeds-p "\"\\u20A\"")
         "Incomplete Unicode escape should cause error")
  
  ;; Test 12: Unicode escape with lowercase hex should work
  (is string= "€" (parse-from-string "\"\\u20ac\"")
      "Lowercase hex in Unicode escape should parse")
  
  ;; Test 13: Multiple escape sequences in same string
  (is string= (format nil "line~%with~Ctab~Cand quote\"end" #\Tab #\Backspace)
      (parse-from-string "\"line\\nwith\\ttab\\band quote\\\"end\"")
      "Multiple escape sequences should parse correctly"))

(define-test us-014-handle-escape-sequences-single-quoted
  :parent phase-1-foundation
  "US-014: Handle Escape Sequences in Single-Quoted Strings"
  ;; Test 1: Empty single-quoted string
  (is string= "" (parse-from-string "''")
      "Empty single-quoted string should parse to empty string")
  
  ;; Test 2: Simple single-quoted string
  (is string= "simple" (parse-from-string "'simple'")
      "'simple' should parse as string")
  
  ;; Test 3: Single quote escape: '' → '
  (is string= "'" (parse-from-string "''''")
      "'''' (two single quotes) should parse as single quote character")
  
  ;; Test 4: Escaped single quote in string
  (is string= "it's quoted" (parse-from-string "'it''s quoted'")
      "'' should escape to ' in single-quoted strings")
  
  ;; Test 5: Multiple escaped single quotes
  (is string= "can't stop won't stop" (parse-from-string "'can''t stop won''t stop'")
      "Multiple '' escapes should work")
  
  ;; Test 6: Backslash-n remains literal
  (is string= "\\n" (parse-from-string "'\\n'")
      "\\n should remain as literal backslash-n in single-quoted strings")
  
  ;; Test 7: Backslash-t remains literal
  (is string= "\\t" (parse-from-string "'\\t'")
      "\\t should remain as literal backslash-t in single-quoted strings")
  
  ;; Test 8: Other escape sequences remain literal
  (is string= "\\r\\f\\b\\\"" (parse-from-string "'\\r\\f\\b\\\"'")
      "Other escape sequences should remain literal in single-quoted strings")
  
  ;; Test 9: Unicode escape remains literal
  (is string= "\\u20AC" (parse-from-string "'\\u20AC'")
      "Unicode escapes should remain literal in single-quoted strings")
  
  ;; Test 10: Mixed content with escapes
  (is string= "it's a test\\nwith multiple\\tcharacters" (parse-from-string "'it''s a test\\nwith multiple\\tcharacters'")
      "Mixed content with '' escapes and literal backslashes should parse correctly"))

;;; Phase 2: Block Collections Tests

(define-test phase-2-block-collections
  :parent yamcl-tests
  "Phase 2: Block-style mappings and sequences")

(define-test us-015-parse-simple-block-mappings
  :parent phase-2-block-collections
  "US-015: Parse simple block mappings"

  ;; Basic key-value pair
  (let ((result (parse-from-string "key: value")))
    (is equal "value" (gethash "key" result)
        "key: value should parse to hash table with key 'key' and value 'value'")
    (true (typep result 'hash-table)
          "Should return a hash table"))

  ;; Multiple key-value pairs
  (let ((result (parse-from-string "name: John
age: 30
city: Boston")))
    (is equal "John" (gethash "name" result) "name should be John")
    (is equal 30 (gethash "age" result) "age should be 30")
    (is equal "Boston" (gethash "city" result) "city should be Boston"))

  ;; Different scalar types as values
  (let ((result (parse-from-string "boolean: true
null: null
number: 42
string: hello")))
    (true (gethash "boolean" result) "boolean should be true")
    (is eq 'cl:null (gethash "null" result) "null should be cl:null")
    (is = 42 (gethash "number" result) "number should be 42")
    (is string= "hello" (gethash "string" result) "string should be 'hello'"))

  ;; Test with quotes
  (let ((result (parse-from-string "'quoted key': \"quoted value\"")))
    (is string= "quoted value" (gethash "quoted key" result)
        "Quoted key and value should parse correctly"))

  ;; Error case: missing space after colon (should fail according to YAML spec)
  (false (parse-succeeds-p "key:value")
         "key:value (no space) should fail to parse")

  ;; Empty value
  (let ((result (parse-from-string "key:")))
    (is eq 'cl:null (gethash "key" result)
        "key: (empty value) should parse to null")
    (true (typep result 'hash-table)
          "Should still return a hash table with null value")))

(define-test us-016-parse-nested-block-mappings
  :parent phase-2-block-collections
  "US-016: Parse nested block mappings"

  ;; Test 1: Basic one-level nesting
  (let ((result (parse-from-string (format nil "outer:~%  inner: value"))))
    (true (typep result 'hash-table) "Result should be a hash table")
    (let ((inner (gethash "outer" result)))
      (true (typep inner 'hash-table) "Nested value should be a hash table")
      (is equal "value" (gethash "inner" inner)
          "Inner key should have value 'value'")))

  ;; Test 2: Two-level nesting
  (let ((result (parse-from-string (format nil "a:~%  b:~%    c: value"))))
    (true (typep result 'hash-table) "Result should be a hash table")
    (let ((a-val (gethash "a" result)))
      (true (typep a-val 'hash-table) "a's value should be a hash table")
      (let ((b-val (gethash "b" a-val)))
        (true (typep b-val 'hash-table) "b's value should be a hash table")
        (is equal "value" (gethash "c" b-val)
            "c's value should be 'value'"))))

  ;; Test 3: Nested with multiple siblings
  (let ((result (parse-from-string (format nil "outer:~%  a: 1~%  b: 2"))))
    (true (typep result 'hash-table) "Result should be a hash table")
    (let ((inner (gethash "outer" result)))
      (true (typep inner 'hash-table) "Nested value should be a hash table")
      (is = 1 (gethash "a" inner) "a should be 1")
      (is = 2 (gethash "b" inner) "b should be 2")))

  ;; Test 4: Nested and sibling entries mixed
  (let ((result (parse-from-string (format nil "outer:~%  inner: value~%other: 42"))))
    (true (typep result 'hash-table) "Result should be a hash table")
    (let ((inner (gethash "outer" result)))
      (true (typep inner 'hash-table) "Nested value should be a hash table")
      (is equal "value" (gethash "inner" inner) "inner should be 'value'"))
    (is = 42 (gethash "other" result) "other should be 42"))

  ;; Test 5: Nested with typed scalars
  (let ((result (parse-from-string (format nil "config:~%  enabled: true~%  count: 99~%  name: test"))))
    (true (typep result 'hash-table) "Result should be a hash table")
    (let ((inner (gethash "config" result)))
      (true (typep inner 'hash-table) "Nested value should be a hash table")
      (is eql t (gethash "enabled" inner) "enabled should be true")
      (is = 99 (gethash "count" inner) "count should be 99")
      (is string= "test" (gethash "name" inner) "name should be 'test'")))

  ;; Test 6: Deep nesting with three levels and siblings at each level
  (let ((result (parse-from-string (format nil "level1:~%  level2:~%    level3: deep~%    also: value~%  top: sibling"))))
    (true (typep result 'hash-table) "Result should be a hash table")
    (let ((l1 (gethash "level1" result)))
      (true (typep l1 'hash-table) "level1's value should be a hash table")
      (let ((l2 (gethash "level2" l1)))
        (true (typep l2 'hash-table) "level2's value should be a hash table")
        (is equal "deep" (gethash "level3" l2) "level3 should be 'deep'")
        (is equal "value" (gethash "also" l2) "also should be 'value'"))
      (is equal "sibling" (gethash "top" l1) "top should be 'sibling'"))))

(define-test us-017-parse-simple-block-sequences
  :parent phase-2-block-collections
  "US-017: Parse simple block sequences (- item)"

  ;; Test 1: Single item
  (let ((result (parse-from-string (format nil "- a"))))
    (true (typep result 'list) "Result should be a list")
    (is equal '("a") result
        "Single item sequence should parse"))

  ;; Test 2: Two items
  (let ((result (parse-from-string (format nil "- a~%- b"))))
    (is equal '("a" "b") result
        "Two-item sequence should parse"))

  ;; Test 3: Numbers
  (let ((result (parse-from-string (format nil "- 42~%- 100"))))
    (is equal '(42 100) result
        "Numeric items should parse"))

  ;; Test 4: Mixed types
  (let ((result (parse-from-string (format nil "- 42~%- hello~%- true"))))
    (is equal '(42 "hello" t) result
        "Mixed type items should parse"))

  ;; Test 5: Three items
  (let ((result (parse-from-string (format nil "- a~%- b~%- c"))))
    (is equal '("a" "b" "c") result
        "Three-item sequence should parse"))

  ;; Test 6: Single item with newline
  (let ((result (parse-from-string (format nil "- a~%"))))
    (is equal '("a") result
        "Single item with trailing newline should parse"))

  ;; Test 7: Single item no newline
  (let ((result (parse-from-string "- a")))
    (is equal '("a") result
        "Single item without newline should parse"))

  ;; Test 8: Boolean items
  (let ((result (parse-from-string (format nil "- true~%- false"))))
    (is equal '(t nil) result
        "Boolean items should parse")))

(define-test us-018-parse-nested-block-sequences
  :parent phase-2-block-collections
  "US-018: Parse nested block sequences"
  ;; Test 1: Simple nesting - item is a sub-sequence
  (let ((result (parse-from-string (format nil "-~%  - nested"))))
    (is equal '(("nested")) result
        "Single nested item should parse"))

  ;; Test 2: Nesting with multiple sub-items
  (let ((result (parse-from-string (format nil "-~%  - a~%  - b"))))
    (is equal '(("a" "b")) result
        "Multiple nested items should parse"))

  ;; Test 3: Inline nesting
  (let ((result (parse-from-string (format nil "- - a~%  - b"))))
    (is equal '(("a" "b")) result
        "Inline nested dash should parse"))

  ;; Test 4: Mixed scalar and sequence items
  (let ((result (parse-from-string (format nil "- 42~%-~%  - a~%  - b"))))
    (is equal '(42 ("a" "b")) result
        "Mixed scalar and sequence items should parse"))

  ;; Test 5: Deep nesting
  (let ((result (parse-from-string (format nil "-~%  -~%    - deep"))))
    (is equal '((("deep"))) result
        "Three levels of nesting should parse"))

  ;; Test 6: Multiple top-level items with nesting
  (let ((result (parse-from-string (format nil "-~%  - a~%-~%  - b"))))
    (is equal '(("a") ("b")) result
        "Multiple top-level nested items should parse"))

  ;; Test 7: Nesting with different scalar types
  (let ((result (parse-from-string (format nil "-~%  - 42~%  - true~%  - null"))))
    (is equal '((42 t cl:null)) result
        "Nested items with different types should parse"))

  ;; Test 8: Nesting with string values
  (let ((result (parse-from-string (format nil "-~%  - \"quoted\"~%  - 'single'"))))
    (is equal '(("quoted" "single")) result
        "Nested items with quoted strings should parse")))

(define-test us-019-parse-mixed-mappings-and-sequences
  :parent phase-2-block-collections
  "US-019: Parse mixed mappings and sequences"
  ;; Test 1: Mapping with sequence value
  (let ((result (parse-from-string (format nil "items:~%  - a~%  - b"))))
    (is equal '("a" "b") (gethash "items" result)
        "Mapping with sequence value should parse"))

  ;; Test 2: Sequence with mapping item
  (let ((result (parse-from-string (format nil "- key: value"))))
    (is equal "value" (gethash "key" (first result))
        "Sequence with mapping item should parse"))

  ;; Test 3: Mapping with nested mapping and sequence
  (let ((result (parse-from-string (format nil "config:~%  name: test~%  items:~%    - a~%    - b"))))
    (let ((config (gethash "config" result)))
      (is equal "test" (gethash "name" config)
          "Nested mapping value should parse")
      (is equal '("a" "b") (gethash "items" config)
          "Nested sequence value should parse")))

  ;; Test 4: Multiple mapping keys with sequence values
  (let ((result (parse-from-string (format nil "first:~%  - x~%second:~%  - y"))))
    (is equal '("x") (gethash "first" result)
        "First sequence should parse")
    (is equal '("y") (gethash "second" result)
        "Second sequence should parse"))

  ;; Test 5: Sequence containing mappings
  (let ((result (parse-from-string (format nil "- name: alice~%  age: 30~%- name: bob~%  age: 25"))))
    (is equal "alice" (gethash "name" (first result))
        "First mapping name should parse")
    (is equal 30 (gethash "age" (first result))
        "First mapping age should parse")
    (is equal "bob" (gethash "name" (second result))
        "Second mapping name should parse")
    (is equal 25 (gethash "age" (second result))
        "Second mapping age should parse"))

  ;; Test 6: Mapping value is a list of mappings
  (let ((result (parse-from-string (format nil "users:~%  - name: alice~%  - name: bob"))))
    (let ((users (gethash "users" result)))
      (is equal "alice" (gethash "name" (first users))
          "First user should parse")
      (is equal "bob" (gethash "name" (second users))
          "Second user should parse"))))

(define-test us-020-handle-indentation-in-block-collections
  :parent phase-2-block-collections
  "US-020: Handle indentation in block collections"

  ;; --- Mapping indentation ---

  ;; Test 1: 2-space indent nesting
  (let ((result (parse-from-string (format nil "outer:~%  inner: value"))))
    (is equal "value"
        (gethash "inner" (gethash "outer" result))
        "2-space indent nesting should work"))

  ;; Test 2: Dedent ends mapping scope
  (let ((result (parse-from-string (format nil "a:~%  b: 1~%c: 2"))))
    (is equal 1 (gethash "b" (gethash "a" result))
        "Nested value should parse")
    (is equal 2 (gethash "c" result)
        "Dedent to column 0 should start new mapping"))

  ;; Test 3: Same indent continues mapping
  (let ((result (parse-from-string (format nil "a:~%  b: 1~%  c: 2"))))
    (let ((a (gethash "a" result)))
      (is equal 1 (gethash "b" a)
          "First nested key should parse")
      (is equal 2 (gethash "c" a)
          "Second nested key at same indent should be sibling")))

  ;; Test 4: 4-space indent nesting
  (let ((result (parse-from-string (format nil "key:~%    deep: value"))))
    (is equal "value"
        (gethash "deep" (gethash "key" result))
        "4-space indent nesting should work"))

  ;; Test 5: Deeply nested mapping
  (let ((result (parse-from-string
                  (format nil "a:~%  b:~%    c:~%      d: value"))))
    (is equal "value"
        (gethash "d"
                 (gethash "c"
                          (gethash "b"
                                   (gethash "a" result))))
        "Four levels of mapping nesting should work"))

  ;; --- Sequence indentation ---

  ;; Test 6: All sequence entries at same indent
  (let ((result (parse-from-string (format nil "- a~%- b~%- c"))))
    (is equal '("a" "b" "c") result
        "All sequence entries at indent 0 should work"))

  ;; Test 7: Sequence entries with varying content types
  (let ((result (parse-from-string
                  (format nil "- first~%- 42~%- true~%- null"))))
    (is equal "first" (first result) "String item")
    (is equal 42 (second result) "Number item")
    (is equal t (third result) "Boolean item")
    (is eq 'cl:null (fourth result) "Null item"))

  ;; Test 8: Indented sequence under mapping
  (let ((result (parse-from-string
                  (format nil "items:~%  - a~%  - b~%  - c"))))
    (is equal '("a" "b" "c")
        (gethash "items" result)
        "Indented sequence under mapping should work"))

  ;; Test 9: Mixed nesting - mapping containing sequence
  ;; containing mapping
  (let ((result (parse-from-string
                  (format nil "users:~%  - name: alice~%    age: 30~%  - name: bob~%    age: 25"))))
    (let ((users (gethash "users" result)))
      (is equal "alice"
          (gethash "name" (first users))
          "First user name")
      (is equal 30
          (gethash "age" (first users))
          "First user age")
      (is equal "bob"
          (gethash "name" (second users))
          "Second user name")
      (is equal 25
          (gethash "age" (second users))
          "Second user age")))

  ;; Test 10: Deep indent (20 spaces)
  (let ((result (parse-from-string
                  (format nil "a:~%                    deep: value"))))
    (is equal "value"
        (gethash "deep" (gethash "a" result))
        "Very deep indent should work"))

  ;; --- Edge cases ---

  ;; Test 11: Empty value then dedent
  (let ((result (parse-from-string
                  (format nil "a:~%b: 2"))))
    (is eq 'cl:null (gethash "a" result)
        "Empty value should be null")
    (is equal 2 (gethash "b" result)
        "Siblings at same indent should parse"))

  ;; Test 12: Mapping at indent 0 after sequence
  (let ((result (parse-from-string
                  (format nil "- a~%- b"))))
    (is equal '("a" "b") result
        "Two-item sequence at indent 0")))

;;; Phase 3: Advanced Features Tests

(define-test phase-3-advanced-features
  :parent yamcl-tests
  "Phase 3: Multi-line strings and YAML-specific features"
  (skip "Phase not started"))

;;; Phase 4: Generation Tests

(define-test phase-4-generation
  :parent yamcl-tests
  "Phase 4: Render YAML from Lisp data structures"
  (skip "Phase not started"))

;;; Helper functions for testing

(defun test-parse-from-string (yaml-string expected &optional (test-name "parse"))
  "Test that parsing YAML-STRING produces EXPECTED."
  (is equal expected (parse-from-string yaml-string) test-name))

(defun test-parse-fails (yaml-string &optional (test-name "should fail"))
  "Test that parsing YAML-STRING fails with extraction-error."
  (handler-case 
      (progn
        (parse-from-string yaml-string)
        (fail test-name))
    (extraction-error () t)))

(defun parse-succeeds-p (yaml-string)
  "Return T if parsing YAML-STRING succeeds, NIL if it fails with extraction-error."
  (handler-case
      (progn (parse-from-string yaml-string) t)
    (extraction-error () nil)))

(defun test-roundtrip (value &optional (test-name "roundtrip"))
  "Test that VALUE can be serialized and deserialized."
  (let ((yaml (generate-to-string value)))
    (is equal value (parse-from-string yaml) test-name)))

;;; Current implementation tests

(define-test lookahead-stream-utilities
  :parent yamcl-tests
  "Tests for lookahead-stream utilities"
  (skip "Test infrastructure needs fixing - focusing on user stories for now"))

(define-test current-implementation
  :parent yamcl-tests
  "Tests for current implementation (to be migrated to story tests)"
  ;; Basic smoke test
  (is = 1 1 "Smoke test should pass")

  ;; Test that +eof+ constant exists
  (is eql :eof +eof+ "+eof+ should be :eof")

  ;; Test that +null+ constant exists
  (is eql 'cl:null +null+ "+null+ should be cl:null")

  ;; Test basic API functions exist (just check they don't error)
  (finish (parse-from (make-string-input-stream "")))
  (finish (parse-from-string ""))
  (finish (generate-to (make-string-output-stream) nil))
  (finish (generate-to-string nil)))

;;; Lookahead stream utilities

;;; Lookahead stream utilities

;;; Lookahead stream utilities

;;; Lookahead stream utilities

;;; Lookahead stream utilities

(define-test lookahead-stream-tests
  :parent yamcl-tests
  "Tests for lookahead-stream utilities."
  (let* ((str "abc")
         (stream (make-string-input-stream str))
         (lookahead (new-lookahead-stream stream :buffer-size 3)))
    (declare (ignore lookahead))
    (true (typep lookahead 'lookahead-stream)
     "Should create lookahead-stream"))
  (let* ((str "abc")
         (stream (make-string-input-stream str))
         (lookahead (new-lookahead-stream stream :buffer-size 3)))
    (is eql #\a (lookahead-read-chr lookahead) "Should read 'a'")
    (is eql #\b (lookahead-read-chr lookahead) "Should read 'b'")
    (is eql #\c (lookahead-read-chr lookahead) "Should read 'c'")
    (is eql +eof+ (lookahead-read-chr lookahead)
     "Should return +eof+ after end"))
  (let* ((str "abcdef")
         (stream (make-string-input-stream str))
         (lookahead (new-lookahead-stream stream :buffer-size 3)))
    (is eql #\a (lookahead-peek-chr lookahead 0) "Peek 0 should be 'a'")
    (is eql #\b (lookahead-peek-chr lookahead 1) "Peek 1 should be 'b'")
    (is eql #\c (lookahead-peek-chr lookahead 2) "Peek 2 should be 'c'")
    (lookahead-read-chr lookahead)
    (is eql #\b (lookahead-peek-chr lookahead 0)
     "After read, peek 0 should be 'b'")
    (is eql #\c (lookahead-peek-chr lookahead 1)
     "After read, peek 1 should be 'c'")
    (is eql #\d (lookahead-peek-chr lookahead 2)
     "After read, peek 2 should be 'd'"))
  (let* ((str "abc")
         (stream (make-string-input-stream str))
         (lookahead (new-lookahead-stream stream :buffer-size 2)))
    (skip "Need proper error assertion for buffer overflow"))
  (let* ((str "abcdef")
         (stream (make-string-input-stream str))
         (lookahead (new-lookahead-stream stream :buffer-size 3)))
    (is eql #\a (lookahead-read-chr lookahead))
    (is eql #\b (lookahead-read-chr lookahead))
    (unread-all lookahead)
    (is eql +eof+ (lookahead-read-chr lookahead)
     "After unread-all, buffer should be empty"))
  (let* ((stream (make-string-input-stream ""))
         (lookahead (new-lookahead-stream stream :buffer-size 3)))
    (is eql +eof+ (lookahead-read-chr lookahead)
     "Empty stream should return +eof+"))
  (let* ((str "ab")
         (stream (make-string-input-stream str))
         (lookahead (new-lookahead-stream stream :buffer-size 1)))
    (is eql #\a (lookahead-read-chr lookahead))
    (is eql #\b (lookahead-read-chr lookahead))
    (is eql +eof+ (lookahead-read-chr lookahead))))

;;; Test runner

(defun run-all-tests ()
  "Run all yamcl tests."
  (test 'yamcl-tests))