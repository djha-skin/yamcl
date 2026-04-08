;;;; tests/main.lisp
;;;;
;;;; Unit tests for the yamcl library.
;;;;
;;;; Tests are organized by feature, following TDD principles:
;;;; 1. Write failing test
;;;; 2. Implement feature
;;;; 3. Tests pass

(defpackage #:com.djhaskin.yamcl/tests
  (:use #:cl)
  (:import-from
    #:org.shirakumo.parachute
    #:define-test
    #:true
    #:false
    #:fail
    #:is
    #:isnt
    #:of-type
    #:finish)
  (:import-from #:com.djhaskin.yamcl)
  (:local-nicknames
    (#:parachute #:org.shirakumo.parachute)
    (#:yamcl    #:com.djhaskin.yamcl)))

(in-package #:com.djhaskin.yamcl/tests)

;;; -------------------------------------------------------
;;; Top-level suite
;;; -------------------------------------------------------

(define-test yamcl-suite)

;;; -------------------------------------------------------
;;; Constants and Helpers
;;; -------------------------------------------------------

(define-test +eof+-test
  :parent yamcl-suite
  "Test that +eof+ is properly defined."
  (is eq yamcl:+eof+ :eof))

(define-test peek-chr-string-test
  :parent yamcl-suite
  "Test peek-chr on string input."
  (let ((q (yamcl:make-char-queue :chars (coerce "hello" 'list))))
    (is char= (yamcl::peek-chr q) #\h))
  (let ((q (yamcl:make-char-queue :chars '())))
    (is eq (yamcl::peek-chr q) :eof)))

(define-test read-chr-string-test
  :parent yamcl-suite
  "Test read-chr on string input."
  (let ((q (yamcl:make-char-queue :chars (coerce "hello" 'list))))
    (is char= (yamcl::read-chr q) #\h))
  (let ((q (yamcl:make-char-queue :chars '())))
    (is eq (yamcl::read-chr q) :eof)))

(define-test whitespace-p-test
  :parent yamcl-suite
  "Test whitespace detection."
  (true (yamcl::whitespace-p #\Space))
  (true (yamcl::whitespace-p #\Tab))
  (true (yamcl::whitespace-p #\Newline))
  (false (yamcl::whitespace-p #\a))
  (false (yamcl::whitespace-p nil))
  (false (yamcl::whitespace-p :eof)))

(define-test blankspace-p-test
  :parent yamcl-suite
  "Test blankspace detection (space and tab only)."
  (true (yamcl::blankspace-p #\Space))
  (true (yamcl::blankspace-p #\Tab))
  (false (yamcl::blankspace-p #\Newline))
  (false (yamcl::blankspace-p #\a)))

(define-test build-string-test
  :parent yamcl-suite
  "Test build-string helper."
  (is string= (yamcl::build-string '(#\h #\e #\l #\l #\o)) "hello")
  (is string= (yamcl::build-string '()) ""))

(define-test extract-comment-test
  :parent yamcl-suite
  "Test comment extraction."
  ;; Comment at end of stream returns :eof
  (let ((q (yamcl:make-char-queue :chars (coerce "# This is a comment" 'list))))
    (is eq (yamcl::extract-comment q) :eof))
  ;; Comment followed by more content returns the newline
  (let ((q (yamcl:make-char-queue :chars (coerce (format nil "# comment~%next line") 'list))))
    (is char= (yamcl::extract-comment q) #\Newline))
  ;; skip-whitespace-and-comments skips whitespace + comment and
  ;; returns the first non-whitespace char AFTER the comment
  (let ((q (yamcl:make-char-queue :chars (coerce (format nil "  # comment~%hello") 'list))))
    (is char= (yamcl::skip-whitespace-and-comments q) #\h)))

(define-test skip-whitespace-and-comments-test
  :parent yamcl-suite
  "Test skipping whitespace and comments."
  (let ((q1 (yamcl:make-char-queue :chars (coerce "  hello" 'list))))
    (is char= (yamcl::skip-whitespace-and-comments q1) #\h))
  (let ((q2 (yamcl:make-char-queue :chars (coerce (format nil "# comment~%hello") 'list))))
    (is char= (yamcl::skip-whitespace-and-comments q2) #\h))
  (let ((q3 (yamcl:make-char-queue :chars (coerce (format nil "  # comment~%hello") 'list))))
    (is char= (yamcl::skip-whitespace-and-comments q3) #\h))
  (let ((q4 (yamcl:make-char-queue :chars (coerce "   " 'list))))
    (is eq (yamcl::skip-whitespace-and-comments q4) :eof))
  (let ((q5 (yamcl:make-char-queue :chars '())))
    (is eq (yamcl::skip-whitespace-and-comments q5) :eof)))

;;; -------------------------------------------------------
;;; JSON Scalar Parsing Tests
;;; -------------------------------------------------------

(define-test parse-json-boolean-test
  :parent yamcl-suite
  "Test parsing JSON boolean values."
  (is eq (yamcl:parse-from "true") t)
  (is eq (yamcl:parse-from "false") nil)
  (is eq (yamcl:parse-from "true  ") t)  ; trailing whitespace
  (is eq (yamcl:parse-from "  false") nil))  ; leading whitespace

(define-test parse-json-null-test
  :parent yamcl-suite
  "Test parsing JSON null values."
  (is equal (yamcl:parse-from "null") nil)
  (is equal (yamcl:parse-from "null  ") nil)
  (is equal (yamcl:parse-from "~") nil)  ; YAML alias for null
  (is equal (yamcl:parse-from "~  ") nil))

(define-test parse-json-integer-test
  :parent yamcl-suite
  "Test parsing JSON integer values."
  (is = (yamcl:parse-from "0") 0)
  (is = (yamcl:parse-from "42") 42)
  (is = (yamcl:parse-from "-17") -17)
  (is = (yamcl:parse-from "  123  ") 123))

(define-test parse-json-float-test
  :parent yamcl-suite
  "Test parsing JSON float values."
  (is = (yamcl:parse-from "3.14") 3.14)
  (is = (yamcl:parse-from "-2.5") -2.5)
  (is = (yamcl:parse-from "1e10") 1e10)
  (is = (yamcl:parse-from "2.5E-3") 2.5e-3))

(define-test parse-json-string-test
  :parent yamcl-suite
  "Test parsing JSON string values."
  (is string= (yamcl:parse-from "\"hello\"") "hello")
  (is string= (yamcl:parse-from "\"\"") "")
  (is string= (yamcl:parse-from "  \"world\"  ") "world"))

;;; -------------------------------------------------------
;;; generate-to Tests (TODO: expand as features are added)
;;; -------------------------------------------------------

(define-test generate-to-placeholder-test
  :parent yamcl-suite
  "Test that generate-to currently outputs placeholder."
  (let ((result (get-output-stream-string (yamcl:generate-to
                                            (make-string-output-stream)
                                            nil))))
    (true (search "YAML generation" result))))

(define-test generate-to-string-output-test
  :parent yamcl-suite
  "Test generate-to returns a string-output-stream."
  (let ((result (yamcl:generate-to nil nil)))
    (true (streamp result))))
