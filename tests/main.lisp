;;;; tests/main.lisp
;;;;
;;;; Unit tests for the yamcl library.

(defpackage #:com.djhaskin.yamcl/tests
  (:use #:cl)
  (:import-from
    #:org.shirakumo.parachute
    #:define-test #:true #:false #:fail #:is #:isnt #:of-type #:finish)
  (:import-from #:com.djhaskin.yamcl
    #:parse-from-string #:generate-to-string #:+null+ #:+eof+)
  (:local-nicknames
    (#:parachute #:org.shirakumo.parachute)
    (#:yamcl    #:com.djhaskin.yamcl)))

(in-package #:com.djhaskin.yamcl/tests)

(define-test yamcl-suite)

;;; Constants and Helpers

(define-test +eof+-test
  :parent yamcl-suite
  (is eq yamcl:+eof+ :eof))

(define-test peek-chr-string-test
  :parent yamcl-suite
  (let ((q (yamcl:make-char-queue :chars (coerce "hello" 'list))))
    (is char= (yamcl::peek-chr q) #\h))
  (let ((q (yamcl:make-char-queue :chars '())))
    (is eq (yamcl::peek-chr q) :eof)))

(define-test read-chr-string-test
  :parent yamcl-suite
  (let ((q (yamcl:make-char-queue :chars (coerce "hello" 'list))))
    (is char= (yamcl::read-chr q) #\h))
  (let ((q (yamcl:make-char-queue :chars '())))
    (is eq (yamcl::read-chr q) :eof)))

(define-test whitespace-p-test
  :parent yamcl-suite
  (true (yamcl::whitespace-p #\Space))
  (true (yamcl::whitespace-p #\Tab))
  (true (yamcl::whitespace-p #\Newline))
  (false (yamcl::whitespace-p #\a))
  (false (yamcl::whitespace-p nil))
  (false (yamcl::whitespace-p :eof)))

(define-test blankspace-p-test
  :parent yamcl-suite
  (true (yamcl::blankspace-p #\Space))
  (true (yamcl::blankspace-p #\Tab))
  (false (yamcl::blankspace-p #\Newline))
  (false (yamcl::blankspace-p #\a)))

(define-test build-string-test
  :parent yamcl-suite
  (is string= (yamcl::build-string '(#\h #\e #\l #\l #\o)) "hello")
  (is string= (yamcl::build-string '()) ""))

(define-test extract-comment-test
  :parent yamcl-suite
  (let ((q (yamcl:make-char-queue :chars (coerce "# comment" 'list))))
    (is eq (yamcl::extract-comment q) :eof))
  (let ((q (yamcl:make-char-queue
             :chars (coerce (format nil "# comment~%next") 'list))))
    (is char= (yamcl::extract-comment q) #\Newline)))

(define-test skip-whitespace-and-comments-test
  :parent yamcl-suite
  (let ((q (yamcl:make-char-queue :chars (coerce "  hello" 'list))))
    (is char= (yamcl::skip-whitespace-and-comments q) #\h))
  (let ((q (yamcl:make-char-queue
             :chars (coerce (format nil "# comment~%hello") 'list))))
    (is char= (yamcl::skip-whitespace-and-comments q) #\h))
  (let ((q (yamcl:make-char-queue :chars '())))
    (is eq (yamcl::skip-whitespace-and-comments q) :eof)))

;;; JSON Scalar Parsing Tests

(define-test parse-json-boolean-test
  :parent yamcl-suite
  (is eq (yamcl:parse-from-string "true") t)
  (is eq (yamcl:parse-from-string "false") nil)
  (is eq (yamcl:parse-from-string "true  ") t)
  (is eq (yamcl:parse-from-string "  false") nil))

(define-test parse-json-null-test
  :parent yamcl-suite
  ;; null and ~ both parse to the +null+ sentinel
  (is eq (yamcl:parse-from-string "null") +null+)
  (is eq (yamcl:parse-from-string "~") +null+)
  ;; +null+ is distinct from CL's nil
  (isnt eq (yamcl:parse-from-string "null") nil)
  (isnt eq (yamcl:parse-from-string "~") nil))

(define-test parse-json-integer-test
  :parent yamcl-suite
  (is = (yamcl:parse-from-string "0") 0)
  (is = (yamcl:parse-from-string "42") 42)
  (is = (yamcl:parse-from-string "-17") -17)
  (is = (yamcl:parse-from-string "  123  ") 123))

(define-test parse-json-float-test
  :parent yamcl-suite
  (is = (yamcl:parse-from-string "3.14") 3.14)
  (is = (yamcl:parse-from-string "-2.5") -2.5)
  (is = (yamcl:parse-from-string "1e10") 1e10)
  (is = (yamcl:parse-from-string "2.5E-3") 2.5e-3))

(define-test parse-yaml-special-floats-test
  :parent yamcl-suite
  ;; Positive infinity
  (is eq (yamcl:parse-from-string ".inf") ':+inf)
  (is eq (yamcl:parse-from-string "+.inf") ':+inf)
  (is eq (yamcl:parse-from-string ".Inf") ':+inf)
  (is eq (yamcl:parse-from-string "+.Inf") ':+inf)
  (is eq (yamcl:parse-from-string ".INF") ':+inf)
  (is eq (yamcl:parse-from-string "+.INF") ':+inf)
  ;; Negative infinity
  (is eq (yamcl:parse-from-string "-.inf") ':-inf)
  (is eq (yamcl:parse-from-string "-.Inf") ':-inf)
  (is eq (yamcl:parse-from-string "-.INF") ':-inf)
  ;; NaN
  (is eq (yamcl:parse-from-string ".nan") 'nan)
  (is eq (yamcl:parse-from-string "+.nan") 'nan)
  (is eq (yamcl:parse-from-string "-.nan") 'nan)
  (is eq (yamcl:parse-from-string ".NaN") 'nan)
  (is eq (yamcl:parse-from-string ".NAN") 'nan))

(define-test parse-invalid-number-test
  :parent yamcl-suite
  ;; Invalid number: . followed by non-digit non-special
  (fail (yamcl:parse-from-string "+.foo") 'yamcl::extraction-error)
  (fail (yamcl:parse-from-string "-.bar") 'yamcl::extraction-error)
  (fail (yamcl:parse-from-string "1.foo") 'yamcl::extraction-error)
  ;; Invalid: decimal point with no following digit
  (fail (yamcl:parse-from-string "1.") 'yamcl::extraction-error)
  (fail (yamcl:parse-from-string "1.e") 'yamcl::extraction-error))

(define-test parse-json-string-test
  :parent yamcl-suite
  (is string= (yamcl:parse-from-string "\"hello\"") "hello")
  (is string= (yamcl:parse-from-string "\"\"") "")
  (is string= (yamcl:parse-from-string "  \"world\"  ") "world"))

(define-test parse-json-string-escapes-test
  :parent yamcl-suite
  ;; Newline escape \n
  (is string= (yamcl:parse-from-string "\"hello\\nworld\"")
      (coerce '(#\h #\e #\l #\l #\o #\Newline #\w #\o #\r #\l #\d) 'string))
  ;; Tab escape \t
  (is string= (yamcl:parse-from-string "\"tab:\\there\"")
      (coerce '(#\t #\a #\b #\Tab #\h #\e #\r #\e) 'string))
  ;; Backslash escape \\
  (is string= (yamcl:parse-from-string "\"backslash: \\\\\"")
      (coerce '(#\b #\a #\c #\k #\s #\l #\a #\s #\h #\: #\Space #\\) 'string))
  ;; Quote escape \"
  (is string= (yamcl:parse-from-string "\"quote: \\\"\"")
      (coerce '(#\q #\u #\o #\t #\e #\: #\Space #\") 'string))
  ;; CR+LF escape \r\n
  (is string= (yamcl:parse-from-string "\"crlf:\\r\\n\"")
      (coerce '(#\c #\r #\l #\f #\: #\Return #\Newline) 'string))
  ;; Form feed escape \f
  (is string= (yamcl:parse-from-string "\"ff:\\f\"")
      (coerce '(#\f #\f #\: #\Page) 'string))
  ;; Backspace escape \b
  (is string= (yamcl:parse-from-string "\"bs:\\b\"")
      (coerce '(#\b #\s #\: #\Backspace) 'string))
  ;; Unicode escapes
  (is string= (yamcl:parse-from-string "\"\\u0041\"") "A")
  (is string= (yamcl:parse-from-string "\"\\u03A9\"") "Ω")
  (is string= (yamcl:parse-from-string "\"\\u00E9\"") "é")
  ;; Solidus escape \/
  (is string= (yamcl:parse-from-string "\"path\\/file\"")
      (coerce '(#\p #\a #\t #\h #\/ #\f #\i #\l #\e) 'string)))

;;; generate-to Tests

(define-test generate-to-nil-test
  :parent yamcl-suite
  (is string= (yamcl:generate-to-string nil) "false"))

(define-test generate-to-cl-null-test
  :parent yamcl-suite
  (is string= (yamcl:generate-to-string +null+) "null"))

(define-test generate-to-true-test
  :parent yamcl-suite
  (is string= (yamcl:generate-to-string t) "true"))

(define-test generate-to-number-test
  :parent yamcl-suite
  (is string= (yamcl:generate-to-string 42) "42")
  (is string= (yamcl:generate-to-string 3.14) "3.14")
  (is string= (yamcl:generate-to-string -17) "-17"))

(define-test generate-to-string-test
  :parent yamcl-suite
  (is string= (yamcl:generate-to-string "hello") "\"hello\"")
  (is string= (yamcl:generate-to-string "") "\"\""))

(define-test generation-error-test
  :parent yamcl-suite
  ;; Attempting to generate unsupported types should signal generation-error
  (fail (yamcl:generate-to-string (cons 'a 'b)) 'yamcl::generation-error)
  (fail (yamcl:generate-to-string #'(lambda ())) 'yamcl::generation-error))

;;; Round-trip Tests

(define-test roundtrip-false-test
  :parent yamcl-suite
  (is eq (yamcl:parse-from-string (yamcl:generate-to-string nil)) nil))

(define-test roundtrip-true-test
  :parent yamcl-suite
  (is eq (yamcl:parse-from-string (yamcl:generate-to-string t)) t))

(define-test roundtrip-null-test
  :parent yamcl-suite
  (is eq (yamcl:parse-from-string (yamcl:generate-to-string +null+)) +null+))

(define-test roundtrip-number-test
  :parent yamcl-suite
  (is = (yamcl:parse-from-string (yamcl:generate-to-string 42)) 42)
  (is = (yamcl:parse-from-string (yamcl:generate-to-string 3.14)) 3.14))

(define-test roundtrip-string-test
  :parent yamcl-suite
  (is string= (yamcl:parse-from-string (yamcl:generate-to-string "hello")) "hello"))

;;; Null vs False Distinction Tests

(define-test null-vs-false-distinction-test
  :parent yamcl-suite
  (let ((parsed-null (yamcl:parse-from-string "null"))
        (parsed-false (yamcl:parse-from-string "false"))
        (parsed-tilde (yamcl:parse-from-string "~")))
    ;; Verify null and tilde both parse to +null+
    (is eq parsed-null +null+)
    (is eq parsed-tilde +null+)
    ;; Verify false parses to CL's nil
    (is eq parsed-false nil)
    ;; Verify they are distinguishable
    (isnt eq parsed-null parsed-false)
    (isnt eq parsed-tilde parsed-false)
    ;; Verify +null+ is truthy, nil is falsy
    (true parsed-null)
    (false parsed-false)))
