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
  (is char= (yamcl::peek-chr "hello") #\h)
  (is eq (yamcl::peek-chr "") :eof))

(define-test read-chr-string-test
  :parent yamcl-suite
  "Test read-chr on string input."
  (is char= (yamcl::read-chr "hello") #\h)
  (is eq (yamcl::read-chr "") :eof))

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
  (with-input-from-string (s "# This is a comment")
    (is eq (yamcl::extract-comment s) :eof))
  (with-input-from-string (s (format nil "Comment~%next line"))
    (is char= (yamcl::extract-comment s) #\n)))

(define-test skip-whitespace-and-comments-test
  :parent yamcl-suite
  "Test skipping whitespace and comments."
  (is char= (yamcl::skip-whitespace-and-comments "  hello") #\h)
  (is char= (yamcl::skip-whitespace-and-comments
             (format nil "# comment~%hello")) #\h)
  (is char= (yamcl::skip-whitespace-and-comments
             (format nil "  # comment~%hello")) #\h)
  (is eq (yamcl::skip-whitespace-and-comments "   ") :eof)
  (is eq (yamcl::skip-whitespace-and-comments "") :eof))

;;; -------------------------------------------------------
;;; parse-from Tests (TODO: expand as features are added)
;;; -------------------------------------------------------

(define-test parse-from-empty-test
  :parent yamcl-suite
  "Test parsing empty input."
  (is equal (yamcl:parse-from "") nil)
  (is equal (yamcl:parse-from "   ") nil)
  (is equal (yamcl:parse-from "# just a comment") nil))

(define-test parse-from-placeholder-test
  :parent yamcl-suite
  "Test that parse-from currently signals extraction-error
for non-empty content (placeholder behavior)."
  (is eq (nth-value 1 (ignore-errors (yamcl:parse-from "hello")))
      'yamcl::extraction-error))

;;; -------------------------------------------------------
;;; generate-to Tests (TODO: expand as features are added)
;;; -------------------------------------------------------

(define-test generate-to-placeholder-test
  :parent yamcl-suite
  "Test that generate-to currently outputs placeholder."
  (let ((result (yamcl:generate-to
                  (make-string-output-stream)
                  nil)))
    (true (search "# YAML generation not yet implemented" result))))

(define-test generate-to-string-output-test
  :parent yamcl-suite
  "Test generate-to with string output."
  (let ((result (yamcl:generate-to "" nil)))
    (true (stringp result))))
