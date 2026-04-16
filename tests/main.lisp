;;;; tests/main.lisp
;;;; yamcl - YAML Ain't Markup Language -- Common Lisp

(cl:defpackage :com.djhaskin.yamcl/tests
  (:use :cl :com.djhaskin.yamcl :parachute))

(cl:in-package :com.djhaskin.yamcl/tests)

(defparameter *yamcl-suite* (testsuite "yamcl suite"))

;;; Test Helper Macros

(defmacro is-equal (form expected &rest args)
  "Test that FORM equals EXPECTED."
  `(is (equal ,form ,expected)
       ,(format nil "~S equals ~S" form expected)
       ,@args))

(defmacro is-eql (form expected &rest args)
  "Test that FORM is EQ to EXPECTED."
  `(is (eql ,form ,expected)
       ,(format nil "~S is eql to ~S" form expected)
       ,@args))

(defmacro signals-error (form &rest args)
  "Test that FORM signals an error."
  `(is (typep (nth-value 1 (ignore-errors ,form)) 'error)
       ,(format nil "~S signals an error" form)
       ,@args))

;;; Constants Tests

(deftest test-eof-constant (*yamcl-suite*)
  :documentation "Test the +eof+ constant"
  (is-eql +eof+ ':eof "The +eof+ constant should be ':eof"))

(deftest test-null-constant (*yamcl-suite*)
  :documentation "Test the +null+ constant"
  (is (eq +null+ 'cl:null) "The +null+ constant should be 'cl:null"))

;;; Helper Function Tests

(deftest test-blankspace-p (*yamcl-suite*)
  :documentation "Test blankspace-p function"
  (is-equal (mapcar #'blankspace-p '(#\Space #\Tab #\Newline #\a))
            '(t t nil nil)))

(deftest test-whitespace-p (*yamcl-suite*)
  :documentation "Test whitespace-p function"
  (is-equal (mapcar #'whitespace-p '(#\Space #\Tab #\Newline #\Return #\a #\NULL))
            '(t t t t nil nil)))

(deftest test-build-string (*yamcl-suite*)
  :documentation "Test build-string function"
  (is-equal (build-string '(#\a #\b #\c)) "abc"))

;;; Character Queue Tests

(deftest test-char-queue-basics (*yamcl-suite*)
  :documentation "Test basic char-queue operations"
  (let ((cq (make-char-queue)))
    (cq-append cq #\a)
    (cq-append cq #\b)
    (is (char= (cq-peek cq) #\a) "Peek should return first char")
    (is (char= (cq-pop cq) #\a) "Pop should return first char")
    (is (char= (cq-peek cq) #\b) "Peek should return second char")
    (is (char= (cq-pop cq) #\b) "Pop should return second char")
    (is (null (cq-peek cq)) "Peek should return nil on empty queue")
    (is (null (cq-pop cq)) "Pop should return nil on empty queue")))

(deftest test-char-queue-from-list (*yamcl-suite*)
  :documentation "Test char-queue initialized from list"
  (let ((cq (make-char-queue :chars '(#\x #\y #\z))))
    (is (char= (cq-pop cq) #\x) "First pop should return x")
    (is (char= (cq-pop cq) #\y) "Second pop should return y")
    (is (char= (cq-pop cq) #\z) "Third pop should return z")
    (is (null (cq-pop cq)) "Pop on empty should return nil")))

;;; Parsing Tests

(deftest test-parse-boolean-true (*yamcl-suite*)
  :documentation "Test parsing true"
  (is (parse-from-string "true") "Parsing 'true' should return T"))

(deftest test-parse-boolean-false (*yamcl-suite*)
  :documentation "Test parsing false"
  (is (null (parse-from-string "false")) "Parsing 'false' should return NIL"))

(deftest test-parse-null-null (*yamcl-suite*)
  :documentation "Test parsing null"
  (is (eq (parse-from-string "null") +null+) "Parsing 'null' should return +null+"))

(deftest test-parse-null-tilde (*yamcl-suite*)
  :documentation "Test parsing ~ as null"
  (is (eq (parse-from-string "~") +null+) "Parsing '~' should return +null+"))

(deftest test-parse-integer-positive (*yamcl-suite*)
  :documentation "Test parsing positive integers"
  (is-equal (parse-from-string "42") 42)
  (is-equal (parse-from-string "0") 0)
  (is-equal (parse-from-string "123456789") 123456789))

(deftest test-parse-integer-negative (*yamcl-suite*)
  :documentation "Test parsing negative integers"
  (is-equal (parse-from-string "-17") -17)
  (is-equal (parse-from-string "-1") -1)
  (is-equal (parse-from-string "-0") 0))

(deftest test-parse-float-basic (*yamcl-suite*)
  :documentation "Test parsing basic floats"
  (is-equal (parse-from-string "3.14") 3.14)
  (is-equal (parse-from-string "0.5") 0.5)
  (is-equal (parse-from-string "-1.5") -1.5))

(deftest test-parse-float-with-exponent (*yamcl-suite*)
  :documentation "Test parsing floats with exponent"
  (is-equal (parse-from-string "1e10") 1e10)
  (is-equal (parse-from-string "2.5E-3") 0.0025)
  (is-equal (parse-from-string "3.14e+2") 314.0))

(deftest test-parse-float-zero (*yamcl-suite*)
  :documentation "Test parsing zero as float"
  (is (floatp (parse-from-string "0.0")) "Zero with decimal should be float"))

(deftest test-parse-string-simple (*yamcl-suite*)
  :documentation "Test parsing simple strings"
  (is-equal (parse-from-string "\"hello\"") "hello")
  (is-equal (parse-from-string "\"world\"") "world")
  (is-equal (parse-from-string "\"\"") ""))

(deftest test-parse-string-escaped-quote (*yamcl-suite*)
  :documentation "Test parsing strings with escaped quotes"
  (is-equal (parse-from-string "\"hello\\\"world\"") "hello\"world")
  (is-equal (parse-from-string "\"say \\\"hi\\\"\"") "say \"hi\""))

(deftest test-parse-string-escaped-backslash (*yamcl-suite*)
  :documentation "Test parsing strings with escaped backslash"
  (is-equal (parse-from-string "\"hello\\\\world\"") "hello\\world"))

(deftest test-parse-string-escaped-slash (*yamcl-suite*)
  :documentation "Test parsing strings with escaped forward slash"
  (is-equal (parse-from-string "\"hello\\/world\"") "hello/world"))

(deftest test-parse-string-escaped-backspace (*yamcl-suite*)
  :documentation "Test parsing strings with escaped backspace"
  (is-equal (parse-from-string "\"hello\\bworld\"") "hello\bworld"))

(deftest test-parse-string-escaped-formfeed (*yamcl-suite*)
  :documentation "Test parsing strings with escaped formfeed"
  (is-equal (parse-from-string "\"hello\\fworld\"") "hello\fworld"))

(deftest test-parse-string-escaped-newline (*yamcl-suite*)
  :documentation "Test parsing strings with escaped newline"
  (is-equal (parse-from-string "\"hello\\nworld\"") "hello\nworld"))

(deftest test-parse-string-escaped-return (*yamcl-suite*)
  :documentation "Test parsing strings with escaped return"
  (is-equal (parse-from-string "\"hello\\rworld\"") "hello\rworld"))

(deftest test-parse-string-escaped-tab (*yamcl-suite*)
  :documentation "Test parsing strings with escaped tab"
  (is-equal (parse-from-string "\"hello\\tworld\"") "hello\tworld"))

(deftest test-parse-string-unicode-basic (*yamcl-suite*)
  :documentation "Test parsing strings with basic unicode escapes"
  (is-equal (parse-from-string "\"\\u0041\"") "A")
  (is-equal (parse-from-string "\"\\u0048\\u0065\\u006C\\u006C\\u006F\"") "Hello"))

(deftest test-parse-string-unicode-spanish (*yamcl-suite*)
  :documentation "Test parsing strings with unicode (Spanish)"
  (is-equal (parse-from-string "\"\\u00E1\"") "á"))

(deftest test-parse-string-unicode-japanese (*yamcl-suite*)
  :documentation "Test parsing strings with unicode (Japanese)"
  (is-equal (parse-from-string "\"\\u65E5\\u672C\\u8A9E\"") "日本語"))

(deftest test-parse-string-unicode-surrogate-pair (*yamcl-suite*)
  :documentation "Test parsing strings with surrogate pairs (emoji)"
  (is-equal (parse-from-string "\"\\uD83D\\uDE00\"") "😀"))

(deftest test-parse-string-complex (*yamcl-suite*)
  :documentation "Test parsing complex strings with multiple escapes"
  (is-equal (parse-from-string "\"Line1\\nLine2\\tTab\\\"Quote\\\\\"")
            (format nil "Line1~%Line2~CTab\"Quote\\" 9)))

;;; Generation Tests

(deftest test-generate-boolean-true (*yamcl-suite*)
  :documentation "Test generating true"
  (is-equal (generate-to-string t) "true"))

(deftest test-generate-boolean-false (*yamcl-suite*)
  :documentation "Test generating false"
  (is-equal (generate-to-string nil) "false"))

(deftest test-generate-null (*yamcl-suite*)
  :documentation "Test generating null"
  (is-equal (generate-to-string cl:null) "null"))

(deftest test-generate-integer (*yamcl-suite*)
  :documentation "Test generating integers"
  (is-equal (generate-to-string 42) "42")
  (is-equal (generate-to-string -17) "-17"))

(deftest test-generate-float (*yamcl-suite*)
  :documentation "Test generating floats"
  (is-equal (generate-to-string 3.14) "3.14"))

(deftest test-generate-string-simple (*yamcl-suite*)
  :documentation "Test generating simple strings"
  (is-equal (generate-to-string "hello") "\"hello\""))

(deftest test-generate-string-with-quote (*yamcl-suite*)
  :documentation "Test generating strings with quotes"
  (is-equal (generate-to-string "say \"hi\"") "\"say \\\"hi\\\"\""))

(deftest test-generate-string-with-backslash (*yamcl-suite*)
  :documentation "Test generating strings with backslash"
  (is-equal (generate-to-string "path\\to\\file") "\"path\\\\to\\\\file\""))

(deftest test-generate-string-with-newline (*yamcl-suite*)
  :documentation "Test generating strings with newline"
  (is-equal (generate-to-string "line1
line2") "\"line1\\nline2\""))

(deftest test-generate-string-with-tab (*yamcl-suite*)
  :documentation "Test generating strings with tab"
  (is-equal (generate-to-string "col1	col2") "\"col1\\tcol2\""))

;;; Error Tests

(deftest test-parse-invalid-boolean (*yamcl-suite*)
  :documentation "Test parsing invalid boolean"
  (signals-error (parse-from-string "tru"))
  (signals-error (parse-from-string "fals")))

(deftest test-parse-invalid-null (*yamcl-suite*)
  :documentation "Test parsing invalid null"
  (signals-error (parse-from-string "nul"))
  (signals-error (parse-from-string "n")))

(deftest test-parse-invalid-number (*yamcl-suite*)
  :documentation "Test parsing invalid number"
  (signals-error (parse-from-string "abc"))
  (signals-error (parse-from-string "-abc")))

(deftest test-parse-invalid-escape (*yamcl-suite*)
  :documentation "Test parsing invalid escape sequence"
  (signals-error (parse-from-string "\"hello\\qworld\"")))

(deftest test-parse-incomplete-unicode (*yamcl-suite*)
  :documentation "Test parsing incomplete unicode escape"
  (signals-error (parse-from-string "\"\\u004\"")))

;;; Roundtrip Tests

(deftest test-roundtrip-false (*yamcl-suite*)
  :documentation "Test that false roundtrips correctly"
  (let ((result (parse-from-string (generate-to-string nil))))
    (is (null result) "false should roundtrip to nil")))

(deftest test-roundtrip-null (*yamcl-suite*)
  :documentation "Test that null roundtrips correctly"
  (let ((result (parse-from-string (generate-to-string cl:null))))
    (is (eq result cl:null) "null should roundtrip to cl:null")))

(deftest test-roundtrip-string-with-quotes (*yamcl-suite*)
  :documentation "Test roundtrip with quoted string"
  (let ((original "say \"hi\"")
        (generated (generate-to-string original)))
    (is-equal (parse-from-string generated) original)))

(deftest test-roundtrip-string-with-backslash (*yamcl-suite*)
  :documentation "Test roundtrip with backslash"
  (let ((original "path\\to\\file")
        (generated (generate-to-string original)))
    (is-equal (parse-from-string generated) original)))

(deftest test-roundtrip-string-with-newline (*yamcl-suite*)
  :documentation "Test roundtrip with newline"
  (let ((original "line1
line2")
        (generated (generate-to-string original)))
    (is-equal (parse-from-string generated) original)))

;;; Run Tests

(defun run-tests ()
  "Run all tests and report results."
  (test '*yamcl-suite* :report t :style :pretty))
