;;;; main.lisp -- Reference Implementation Parser for YAML in Common Lisp
;;;;
;;;; SPDX-FileCopyrightText: 2024 Daniel Jay Haskin
;;;; SPDX-License-Identifier: MIT
;;;;

(in-package #:cl-user)

(defpackage
  #:com.djhaskin.yamcl (:use #:cl)
  (:documentation
    "
    YAML Ain't Markup Language -- Common Lisp.

    A pure Common Lisp library for parsing and rendering YAML.
    ")
  (:import-from #:alexandria)
  (:export
    parse-from
    generate-to
    +eof+
    extraction-error))

(in-package #:com.djhaskin.yamcl)

(defconstant +eof+ :eof
  "End-of-file marker, used throughout the parser.")

(define-condition extraction-error (error)
  ((expected :initarg :expected :reader expected)
   (got :initarg :got :reader got))
  (:report
   (lambda (c s)
     (format s
             "Expected ~A; got ~A"
             (expected c)
             (got c)))))

(deftype streamable ()
  '(or stream string))

(deftype streamed ()
  '(or character (member :eof) null))

(defun peek-chr (strm)
  "Peek at the next character without consuming it."
  (declare (type streamable strm))
  (cond
    ((stringp strm)
     (if (= (length strm) 0)
       +eof+
       (char strm 0)))
    (t
     (peek-char nil strm nil +eof+ nil))))

(defun read-chr (strm)
  "Read and consume the next character."
  (declare (type streamable strm))
  (cond
    ((stringp strm)
     (if (= (length strm) 0)
       +eof+
       (prog1
         (char strm 0)
         (setf strm (subseq strm 1)))))
    (t
     (read-char strm nil +eof+ nil))))

(defun build-string (lst)
  "Build a string from a list of characters in reverse order."
  (declare (type list lst))
  (let* ((size (length lst))
         (building (make-string size)))
    (loop for l in lst
          for j from (- size 1) downto 0
          do (setf (elt building j) l))
    building))

(defun blankspace-p (chr)
  "Check if character is a blank space (space or tab)."
  (declare (type character chr))
  (or (char= chr #\Tab)
      (char= chr #\Space)))

(defun whitespace-p (chr)
  "Check if character is any whitespace."
  (declare (type streamed chr))
  (unless (null chr)
    (or (char= chr #\Newline)
        (char= chr #\Return)
        (char= chr #\Page)
        (blankspace-p chr))))

(defun extract-comment (strm)
  "Extract a comment from STRM. Comments start with # and
continue to the end of the line."
  (declare (type streamable strm))
  (loop with last-read = (read-chr strm)
        while (and (not (eq last-read +eof+))
                   (not (char= last-read #\Newline)))
        do (setf last-read (read-chr strm))
        finally (return last-read)))

(defun skip-whitespace-and-comments (strm)
  "Skip whitespace and comments, returning the first non-whitespace
character (without consuming it)."
  (declare (type streamable strm))
  (loop with next = (peek-chr strm)
        while (and (not (eq next +eof+))
                   (or (whitespace-p next)
                       (char= next #\#)))
        do (cond
             ((char= next #\#)
              (extract-comment strm))
             (t
              (read-chr strm)))
           (setf next (peek-chr strm))
        finally (return next)))

(defun parse-from (strm)
  "Parse a YAML document from STRM.

STRM can be a stream or a string.

Returns a parsed representation of the YAML document.

Currently supports:
- Comments (lines starting with #)
- Block key-value pairs (mappings)
- Block lists (sequences)
- JSON scalar values (strings, numbers, booleans, null)

The `:json-mode` parameter controls whether scalars are parsed
as JSON types (strings, numbers, booleans, null) or as generic
YAML strings.

Throws EXTRACTION-ERROR on parse failures."
  (declare (type streamable strm))
  (let ((first-char (skip-whitespace-and-comments strm)))
    (when (eq first-char +eof+)
      (return-from parse-from nil))
    ;; Placeholder: full implementation will follow TDD approach
    (error 'extraction-error
           :expected "valid YAML content"
           :got first-char)))

(defun generate-to (strm val &key (pretty-indent 0) json-mode)
  "Generate YAML output to STRM from VAL.

STRM can be a stream or a string (in which case a string-output-stream
is created).

VAL should be a Lisp data structure:
- Hash tables become YAML mappings
- Lists become YAML sequences
- Strings, numbers, booleans become scalar values

PRETTY-INDENT sets the indentation level (currently unused).
JSON-MODE controls output format:
- When T, generates JSON-compatible output
- When NIL, generates standard YAML

Returns the generated output as a string if STRM was a string."
  (declare (type streamable strm)
           (type (or null (integer 0 64)) pretty-indent)
           (type boolean json-mode))
  (let ((out (if (stringp strm)
                (make-string-output-stream)
                strm)))
    ;; Placeholder: full implementation will follow TDD approach
    (format out "# YAML generation not yet implemented~%")
    (when (stringp strm)
      (get-output-stream-string out))))
