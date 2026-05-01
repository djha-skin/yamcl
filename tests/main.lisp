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
  (skip "Not implemented"))

(define-test us-002-parse-inline-comments
  :parent phase-1-foundation
  "US-002: Parse Inline Comments"
  (skip "Not implemented"))

(define-test us-003-skip-whitespace
  :parent phase-1-foundation
  "US-003: Skip Whitespace"
  (skip "Not implemented"))

(define-test us-004-handle-document-markers
  :parent phase-1-foundation
  "US-004: Handle Document Markers"
  (skip "Not implemented"))

(define-test us-005-parse-integer-numbers
  :parent phase-1-foundation
  "US-005: Parse Integer Numbers"
  (skip "Not implemented"))

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
  
  ;; Test basic API functions exist
  (is functionp #'parse-from "parse-from should be a function")
  (is functionp #'parse-from-string "parse-from-string should be a function")
  (is functionp #'generate-to "generate-to should be a function")
  (is functionp #'generate-to-string "generate-to-string should be a function"))

;;; Test runner

(defun run-all-tests ()
  "Run all yamcl tests."
  (test 'yamcl-tests))