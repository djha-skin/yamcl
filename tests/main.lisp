;;;; tests/main.lisp
;;;; yamcl - YAML Ain't Markup Language -- Common Lisp
;;;; Test suite organized by user stories

(cl:defpackage :com.djhaskin.yamcl/tests
  (:use :cl :com.djhaskin.yamcl)
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
  (:export :run-all-tests))

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
  (skip "Not implemented"))

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
  
  ;; Test 5: Octal notation (currently fails - to be implemented)
  (is = (parse-from-string "0o52") 42 "Octal should parse")
  
  ;; Test 6: Hexadecimal notation (currently fails - to be implemented)
  (skip "Hexadecimal notation not implemented yet")
  ;; (is = (parse-from-string "0x2A") 42 "Hexadecimal should parse")
  
  ;; Test 7: Binary notation (currently fails - to be implemented)
  (skip "Binary notation not implemented yet")
  ;; (is = (parse-from-string "0b101010") 42 "Binary should parse")
  
  ;; Test 8: With underscores (currently fails - to be implemented)
  (skip "Underscores in numbers not implemented yet")
  ;; (is = (parse-from-string "1_000_000") 1000000 "Underscores should be ignored")
  
  ;; Test 9: Leading zeros (should be decimal, not octal)
  (is = (parse-from-string "0012") 12
      "Leading zeros should be decimal"))

(define-test us-006-parse-float-numbers
  :parent phase-1-foundation
  "US-006: Parse Float Numbers"
  (skip "Not implemented"))

(define-test us-007-parse-boolean-true-false
  :parent phase-1-foundation
  "US-007: Parse Boolean true/false"
  (skip "Not implemented"))

(define-test us-008-parse-null-values
  :parent phase-1-foundation
  "US-008: Parse Null Values (null and ~)"
  (skip "Not implemented"))

(define-test us-009-distinguish-null-vs-false
  :parent phase-1-foundation
  "US-009: Distinguish null vs false (cl:null vs nil)"
  (skip "Not implemented"))

(define-test us-010-parse-double-quoted-strings
  :parent phase-1-foundation
  "US-010: Parse Double-Quoted Strings"
  (skip "Not implemented"))

(define-test us-011-parse-single-quoted-strings
  :parent phase-1-foundation
  "US-011: Parse Single-Quoted Strings"
  (skip "Not implemented"))

(define-test us-012-parse-bareword-strings
  :parent phase-1-foundation
  "US-012: Parse Bareword Strings (Plain Scalars)"
  (skip "Not implemented"))

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
  "Test that parsing YAML-STRING fails."
  (fail test-name))

(defun test-roundtrip (value &optional (test-name "roundtrip"))
  "Test that VALUE can be serialized and deserialized."
  (let ((yaml (generate-to-string value)))
    (is equal value (parse-from-string yaml) test-name)))

;;; Current implementation tests

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

;;; Test runner

(defun run-all-tests ()
  "Run all yamcl tests."
  (test 'yamcl-tests))