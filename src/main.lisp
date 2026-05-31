;;;; src/main.lisp
;;;; yamcl - YAML Ain't Markup Language -- Common Lisp

(defpackage
  #:com.djhaskin.yamcl
  (:use :cl)
  (:export
   ;; Parsing
   #:parse-from
   #:parse-from-string
   ;; Generation
   #:generate-to
   #:generate-to-string)
  (:local-nicknames
   (#:utils #:com.djhaskin.yamcl/utils)
   (#:scalars #:com.djhaskin.yamcl/scalars)
   (#:blocks #:com.djhaskin.yamcl/blocks)))

(cl:in-package :com.djhaskin.yamcl)

;;; Parsing

(defun parse-value (lookahead &optional (indent 0))
  "Parse a YAML value from LOOKAHEAD at the given INDENT level.
   Skip comments and whitespace, then try:
   1. Document markers (---, ...)
   2. Scalar-first approach: read a scalar, check for colon after
   3. If colon follows => it's a mapping key
   4. If not => return the scalar as-is"
  (scalars:skip-whitespace-and-comments-lookahead lookahead)
  (let ((ch (utils:lookahead-peek-chr lookahead 0)))
    (cond
      ((or (null ch) (eq ch utils:+eof+))
       utils:+eof+)
      ;; Document start marker (---)
      ((and (char= ch #\-)
            (let ((ch1 (utils:lookahead-peek-chr lookahead 1))
                  (ch2 (utils:lookahead-peek-chr lookahead 2)))
              (and (characterp ch1) (char= ch1 #\-)
                   (characterp ch2) (char= ch2 #\-))))
       (utils:lookahead-read-chr lookahead)  ;; first -
       (utils:lookahead-read-chr lookahead)  ;; second -
       (utils:lookahead-read-chr lookahead)  ;; third -
       (parse-value lookahead indent))
      ;; Document end marker (...)
      ((and (char= ch #\.)
            (let ((ch1 (utils:lookahead-peek-chr lookahead 1))
                  (ch2 (utils:lookahead-peek-chr lookahead 2)))
              (and (characterp ch1) (char= ch1 #\.)
                   (characterp ch2) (char= ch2 #\.))))
       (utils:lookahead-read-chr lookahead)  ;; first .
       (utils:lookahead-read-chr lookahead)  ;; second .
       (utils:lookahead-read-chr lookahead)  ;; third .
       utils:+eof+)
      ;; Block sequence entry (- space or - eol)
      ((and (char= ch #\-)
            (let ((ch1 (utils:lookahead-peek-chr lookahead 1)))
              (and (characterp ch1)
                   (or (char= ch1 #\Space)
                       (char= ch1 #\Newline)
                       (char= ch1 #\Return)))))
       (blocks:parse-block-sequence lookahead indent
                                    #'parse-value))
      ;; Flow sequence ([a, b, c])
      ((char= ch #\[)
       (blocks:parse-flow-sequence lookahead))
      ;; Flow mapping ({key: value})
      ((char= ch #\{)
       (blocks:parse-flow-mapping lookahead))
      ;; Literal block scalar (|)
      ((char= ch #\|)
       (blocks:parse-literal-block-scalar lookahead))
      ;; Folded block scalar (>)
      ((char= ch #\>)
       (blocks:parse-folded-block-scalar lookahead))
      ;; Scalar-first: read the scalar, then check for mapping
      (t
       (let ((scalar (scalars:parse-scalar-lookahead lookahead)))
         (if (eq scalar utils:+eof+)
             utils:+eof+
             (or (blocks:parse-mapping-from-key lookahead scalar indent)
                 scalar)))))))

(defun parse-from (source)
  "Parse a YAML value from SOURCE.
SOURCE must be a stream.
Returns the parsed value or +eof+ at end of input."
  (let ((lookahead (utils:new-lookahead-stream source :buffer-size 16)))
    (let ((result (parse-value lookahead)))
      ;; Skip trailing whitespace and comments
      (scalars:skip-whitespace-and-comments-lookahead lookahead)
      ;; After parsing, allow document markers
      (unless (eq result utils:+eof+)
        (let ((next-ch (utils:lookahead-peek-chr lookahead 0)))
          (unless (or (null next-ch)
                      (eq next-ch utils:+eof+)
                      (char= next-ch #\-)
                      (char= next-ch #\.))
            (error 'utils:extraction-error
                   :expected "end of input or document marker"
                   :got next-ch))))
      (utils:unread-all lookahead)
      result)))

(defun parse-from-string (string)
  "Parse a YAML value from STRING.
Convenience wrapper around parse-from."
  (with-input-from-string (stream string)
    (parse-from stream)))

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
                   (push (string ch) result))))
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