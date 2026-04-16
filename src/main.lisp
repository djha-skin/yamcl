;;;; src/main.lisp
;;;; yamcl - YAML Ain't Markup Language -- Common Lisp

(cl:defpackage :com.djhaskin.yamcl
  (:use :cl)
  (:export
   ;; Constants
   :+eof+
   :+null+
   ;; Parsing
   :parse-from
   :parse-from-string
   ;; Generation
   :generate-to
   :generate-to-string
   ;; Conditions
   :extraction-error
   :extraction-error-format
   :extraction-error-args
   ;; Structures
   :char-queue
   :char-queue-chars
   ;; Character queue operations
   :cq-append
   :cq-peek
   :cq-pop))

(cl:in-package :com.djhaskin.yamcl)

(define-condition extraction-error (error)
  ((format
    :initarg :format
    :reader extraction-error-format)
   (args
    :initarg :args
    :reader extraction-error-args
    :initform nil))
  (:report (lambda (condition stream)
             (format stream
                     (extraction-error-format condition)
                     (apply #'format nil
                            (extraction-error-args condition))))))

;;; Constants

(defconstant +eof+ ':eof)
(defconstant +null+ 'cl:null)

;;; Character Queue

(defstruct char-queue
  (chars nil :type list))

(defun cq-append (cq char)
  "Append a character to the end of a char-queue."
  (push char (char-queue-chars cq)))

(defun cq-peek (cq)
  "Peek at the next character without consuming it."
  (let ((chars (char-queue-chars cq)))
    (when chars
      (car chars))))

(defun cq-pop (cq)
  "Pop and return the next character."
  (pop (char-queue-chars cq)))

;;; Parsing (implemented in scalars.lisp)

(defun parse-from (source)
  "Parse a YAML scalar value from SOURCE.
SOURCE must be a stream.
Returns the parsed value or +eof+ at end of input.
Handles comments, whitespace, booleans, null, numbers, and strings."
  (funcall (find-symbol "PARSE-FROM" :com.djhaskin.yamcl/scalars) source))

(defun parse-from-string (string)
  "Parse a YAML scalar value from STRING.
Convenience wrapper around parse-from."
  (funcall (find-symbol "PARSE-FROM-STRING" :com.djhaskin.yamcl/scalars) string))



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
