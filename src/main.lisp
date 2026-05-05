;;;; src/main.lisp
;;;; yamcl - YAML Ain't Markup Language -- Common Lisp

(cl:defpackage :com.djhaskin.yamcl
  (:use :cl)
  (:export
   ;; Parsing
   :parse-from
   :parse-from-string
   ;; Generation
   :generate-to
   :generate-to-string))

(cl:in-package :com.djhaskin.yamcl)

;;; Parsing (implemented in scalars.lisp)

(defun parse-from (source)
  "Parse a YAML scalar value from SOURCE.
SOURCE must be a stream.
Returns the parsed value or +eof+ at end of input.
Handles comments, whitespace, booleans, null, numbers, and strings."
  (uiop:symbol-call :com.djhaskin.yamcl/scalars :parse-from source))

(defun parse-from-string (string)
  "Parse a YAML scalar value from STRING.
Convenience wrapper around parse-from."
  (uiop:symbol-call :com.djhaskin.yamcl/scalars :parse-from-string string))

;;; Generation

(defun escape-character (ch)
  "Get the escape sequence for a character.
Returns (cons escaped-char . rest) or NIL if no escape needed."
  (case ch
    (#\" '("\\" . "\""))
    (#\\ '("\\" . "\\"))
    (#\Backspace '("\\" . "b"))
    (#\Page '("\\" . "f"))
    (#\Newline '("\\" . "n"))
    (#\Return '("\\" . "r"))
    (#\Tab '("\\" . "t"))
    (t nil)))

(defun escape-string (str)
  "Escape a string for JSON output.
Handles all characters that need escaping per RFC 8259."
  (let ((result nil))
    (loop for ch across str
          do (let ((escape (escape-character ch)))
               (if escape
                   (progn
                     (push (car escape) result)
                     (push (cdr escape) result))
                   (progn
                     (push (string ch) result)))))
    (apply #'concatenate 'string (reverse result))))

(defun generate-scalar (stream value)
  "Generate a scalar VALUE to STREAM.
Handles booleans, null, numbers, strings, and lists."
  (typecase value
    (null (format stream "false"))
    ((eql cl:null) (format stream "null"))
    (boolean (format stream "~:[false~;true~]" value))
    (number (format stream "~G" value))
    (string
     (write-char #\" stream)
     (write-string (escape-string value) stream)
     (write-char #\" stream))
    (list
     (write-char #\[ stream)
     (loop for (item . rest) on value
           do (generate-scalar stream item)
              (when rest (write-char #\, stream)))
     (write-char #\] stream))
    (t
     (write-char #\" stream)
     (write-string (escape-string (format nil "~A" value)) stream)
     (write-char #\" stream))))

(defun generate-to (sink value)
  "Generate YAML representation of VALUE to SINK (a stream).
Handles booleans, null, numbers, strings, and lists."
  (generate-scalar sink value))

(defun generate-to-string (value)
  "Generate YAML representation of VALUE to a string.
Convenience wrapper around generate-to."
  (with-output-to-string (stream)
    (generate-to stream value)))
