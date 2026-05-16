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
           :us-012-parse-bareword-strings))

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
  
  ;; Test 3: TRUE → error (case-sensitive)
  (test-parse-fails "TRUE"
      "Uppercase TRUE should cause error (case-sensitive)")
  
  ;; Test 4: False → error (case-sensitive)
  (test-parse-fails "False"
      "Mixed case False should cause error (case-sensitive)")
  
  ;; Test 5: Inside double quotes should be string, not boolean
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
  
  ;; Test 3: NULL → error (case-sensitive)
  (test-parse-fails "NULL"
      "Uppercase NULL should cause error (case-sensitive)")
  
  ;; Test 4: Null → error (case-sensitive)
  (test-parse-fails "Null"
      "Mixed case Null should cause error (case-sensitive)")
  
  ;; Test 5: ~~ → error (double tilde)
  (test-parse-fails "~~"
      "Double tilde should cause error")
  
  ;; Test 6: Empty value should be null? (YAML spec ambiguity)
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
  
  ;; Test 8: Case variations of reserved words should be barewords
  (is string= "True" (parse-from-string "True")
      "'True' (capital T) should parse as string")
  (is string= "FALSE" (parse-from-string "FALSE")
      "'FALSE' (all caps) should parse as string")
  (is string= "Null" (parse-from-string "Null")
      "'Null' (capital N) should parse as string")
  
  ;; Test 9: Starts with number (edge case)
  ;; TODO: Decide if 123abc should be bareword or error
  ;; For now, test current behavior
  (skip "Decide if 123abc should be bareword or error"))

(define-test us-013-handle-escape-sequences-double-quoted
  :parent phase-1-foundation
  "US-013: Handle Escape Sequences in Double-Quoted Strings"
  (skip "Not implemented"))

(define-test us-014-handle-escape-sequences-single-quoted
  :parent phase-1-foundation
  "US-014: Handle Escape Sequences in Single-Quoted Strings"
  (skip "Not implemented"))

;;; Phase 2: Block Collections Tests

(define-test phase-2-block-collections
  :parent yamcl-tests
  "Phase 2: Block-style mappings and sequences"
  (skip "Phase not started"))

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