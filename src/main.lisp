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
   :char-queue-chars))

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

;;; Input/Output

(defun peek-chr (source)
  "Peek at the next character in SOURCE without consuming it.
SOURCE can be a stream, string, list, or char-queue.
Returns +eof+ at end of input."
  (etypecase source
    (stream
     (let ((ch (peek-char nil source nil +eof+)))
       (if (eq ch +eof+) +eof+ ch)))
    (string
     (let ((ch (char source 0)))
       (if (eq ch #\NULL) +eof+ ch)))
    (list
     (if source (car source) +eof+))
    (char-queue
     (cq-peek source))))

(defun read-chr (source)
  "Read and return the next character from SOURCE, consuming it.
SOURCE can be a stream, string, list, or char-queue.
Returns +eof+ at end of input."
  (etypecase source
    (stream
     (let ((ch (read-char source nil +eof+)))
       (if (eq ch +eof+) +eof+ ch)))
    (string
     (let ((ch (char source 0)))
       (if (eq ch #\NULL)
           +eof+
           (subseq source 1))))
    (list
     (if source (pop source) +eof+))
    (char-queue
     (cq-pop source))))

;;; Helper Functions

(defun blankspace-p (ch)
  "Check if character is a blankspace (space or tab)."
  (or (char= ch #\Space) (char= ch #\Tab)))

(defun whitespace-p (ch)
  "Check if character is any whitespace."
  (when (characterp ch)
    (or (char= ch #\Newline)
        (char= ch #\Return)
        (char= ch #\Tab)
        (char= ch #\Space)
        (blankspace-p ch))))

(defun build-string (list)
  "Build a string from a list of characters, reversing the list."
  (coerce (reverse list) 'string))

;;; Comment Handling

(defun extract-comment (source)
  "Extract a comment from SOURCE starting with #.
Returns the comment text as a string without the leading #.
Leaves SOURCE positioned after the newline or end of input."
  (let ((acc nil)
        (ch (peek-chr source)))
    (loop while (and (characterp ch)
                     (not (char= ch #\Newline))
                     (not (eq ch +eof+)))
          do (push ch acc)
             (read-chr source)
             (setf ch (peek-chr source)))
    (build-string acc)))

(defun skip-whitespace-and-comments (source)
  "Skip blankspaces, newlines, and comments in SOURCE.
Returns the first non-skipped character (peeked)."
  (let ((ch (peek-chr source)))
    (loop while (or (blankspace-p ch)
                    (char= ch #\Newline)
                    (char= ch #\,)
                    (char= ch #\#))
          do (cond
               ((or (blankspace-p ch) (char= ch #\,))
                (read-chr source))
               ((char= ch #\Newline)
                (read-chr source))
               ((char= ch #\#)
                (read-chr source)
                (extract-comment source)))
             (setf ch (peek-chr source)))
    ch))

;;; JSON Scalar Parsing

(defun parse-boolean (source)
  "Parse a boolean value (true/false) from SOURCE.
Returns T or NIL."
  (let* ((acc nil)
         (ch (read-chr source)))
    (push ch acc)
    (loop repeat 3
          do (setf ch (read-chr source))
             (push ch acc))
    (let ((word (build-string acc)))
      (cond
        ((string= word "true") t)
        ((string= word "false") nil)
        (t
         (error 'extraction-error
                :format "Expected boolean, got: ~A"
                :args (list word)))))))

(defun parse-null (source)
  "Parse a null value from SOURCE.
Returns +null+ for null/~.
Returns NIL for false."
  (let* ((acc nil)
         (ch (peek-chr source)))
    (cond
      ;; Check for false first
      ((char= ch #\f)
       (read-chr source)
       (loop repeat 4
             do (push (read-chr source) acc))
       (let ((word (build-string acc)))
         (if (string= word "false")
             nil
             (error 'extraction-error
                    :format "Expected null or false, got: ~A"
                    :args (list word)))))
      ;; Check for null
      ((char= ch #\n)
       (read-chr source)
       (loop repeat 3
             do (push (read-chr source) acc))
       (let ((word (build-string acc)))
         (if (string= word "null")
             +null+
             (error 'extraction-error
                    :format "Expected null, got: ~A"
                    :args (list word)))))
      ;; Check for YAML ~ (null)
      ((char= ch #\~)
       (read-chr source)
       +null+)
      (t
       (error 'extraction-error
              :format "Expected null, false, or ~, got: ~A"
              :args (list ch))))))

(defun parse-number (source)
  "Parse a number from SOURCE.
Handles integers and floats with optional exponent.
Returns the parsed number as a numeric type."
  (let ((acc nil)
        (ch (peek-chr source)))
    ;; Handle optional sign
    (when (or (char= ch #\-) (char= ch #\+))
      (push ch acc)
      (read-chr source)
      (setf ch (peek-chr source)))
    ;; Parse digits before decimal/exponent
    (loop while (digit-char-p ch)
          do (push ch acc)
             (read-chr source)
             (setf ch (peek-chr source)))
    ;; Handle decimal point
    (when (char= ch #\.)
      (push ch acc)
      (read-chr source)
      (setf ch (peek-chr source))
      (loop while (digit-char-p ch)
            do (push ch acc)
               (read-chr source)
               (setf ch (peek-chr source))))
    ;; Handle exponent
    (when (or (char= ch #\e) (char= ch #\E))
      (push ch acc)
      (read-chr source)
      (setf ch (peek-chr source))
      (when (or (char= ch #\-) (char= ch #\+))
        (push ch acc)
        (read-chr source)
        (setf ch (peek-chr source)))
      (loop while (digit-char-p ch)
            do (push ch acc)
               (read-chr source)
               (setf ch (peek-chr source))))
    (let ((num-str (build-string acc)))
      (cond
        ((position #\. num-str) (read-from-string num-str))
        ((position #\e num-str) (read-from-string num-str))
        ((position #\E num-str) (read-from-string num-str))
        (t (let ((int-val (parse-integer num-str)))
             (if (or (>= int-val 536870912)
                     (<= int-val -536870913))
                 (coerce int-val 'double-float)
                 int-val)))))))

(defun parse-hex-digit (ch)
  "Parse a single hex digit character.
Returns the numeric value (0-15) or signals an error."
  (cond
    ((char<= #\0 ch #\9) (- (char-code ch) (char-code #\0)))
    ((char<= #\a ch #\f) (+ 10 (- (char-code ch) (char-code #\a))))
    ((char<= #\A ch #\F) (+ 10 (- (char-code ch) (char-code #\A))))
    (t (error 'extraction-error
              :format "Invalid hex digit: ~A"
              :args (list ch)))))

(defun parse-unicode-codepoint (source)
  "Parse a \\uXXXX sequence from SOURCE.
Returns the Unicode code point as an integer."
  (let ((ch1 (read-chr source))
        (ch2 (read-chr source))
        (ch3 (read-chr source))
        (ch4 (read-chr source)))
    (unless (and (characterp ch1) (characterp ch2)
                 (characterp ch3) (characterp ch4))
      (error 'extraction-error
             :format "Incomplete unicode escape sequence"
             :args nil))
    (+ (ash (parse-hex-digit ch1) 12)
       (ash (parse-hex-digit ch2) 8)
       (ash (parse-hex-digit ch3) 4)
       (parse-hex-digit ch4))))

(defun parse-string (source)
  "Parse a double-quoted string from SOURCE.
Handles JSON escape sequences per RFC 8259 Section 7."
  (read-chr source) ;; consume opening quote
  (let ((acc nil)
        (ch (peek-chr source)))
    (loop while (and (characterp ch)
                     (not (char= ch #\")))
          do (cond
               ((char= ch #\\)
                (read-chr source) ;; consume backslash
                (setf ch (read-chr source))
                (case ch
                  (#\" (push #\" acc))
                  (#\\ (push #\\ acc))
                  (#\/ (push #\/ acc))
                  (#\b (push #\Backspace acc))
                  (#\f (push #\Page acc))
                  (#\n (push #\Newline acc))
                  (#\r (push #\Return acc))
                  (#\t (push #\Tab acc))
                  (#\u
                   (let ((codepoint (parse-unicode-codepoint source)))
                     (cond
                       ;; High surrogate (D800-DBFF) followed by low surrogate (DC00-DFFF)
                       ((and (>= codepoint #xD800) (<= codepoint #xDBFF))
                        (let ((ch2 (read-chr source)))
                          (unless (char= ch2 #\\)
                            (error 'extraction-error
                                   :format "Invalid unicode escape: expected low surrogate"
                                   :args nil))
                          (let ((ch3 (read-chr source)))
                            (unless (char= ch3 #\u)
                              (error 'extraction-error
                                     :format "Invalid unicode escape: expected u"
                                     :args nil)))
                        (let ((low-surrogate (parse-unicode-codepoint source)))
                          (unless (and (>= low-surrogate #xDC00)
                                       (<= low-surrogate #xDFFF))
                            (error 'extraction-error
                                   :format "Invalid unicode escape: expected low surrogate"
                                   :args nil))
                          (setf codepoint
                                (+ #x10000
                                   (ash (- codepoint #xD800) 10)
                                   (- low-surrogate #xDC00)))))
                       ;; Unpaired surrogate
                       ((or (and (>= codepoint #xD800) (<= codepoint #xDFFF))
                            (> codepoint #x10FFFF))
                        (error 'extraction-error
                               :format "Invalid unicode codepoint: ~X"
                               :args (list codepoint))))
                     (loop for i from 0 below (ceiling (log (1+ codepoint) 256))
                           do (push (code-char (mod (ash codepoint (* -8 i)) 256))
                                    acc))))
                  (t
                   (error 'extraction-error
                          :format "Invalid escape sequence: \\~A"
                          :args (list ch)))))
               (t
                (push ch acc)
                (read-chr source)))
          (setf ch (peek-chr source)))
    (read-chr source) ;; consume closing quote
    (build-string acc)))

(defun parse-scalar (source)
  "Parse a scalar value from SOURCE.
Detects and delegates to specific parsers."
  (skip-whitespace-and-comments source)
  (let ((ch (peek-chr source)))
    (cond
      ((eq ch +eof+) +eof+)
      ((or (char= ch #\")
           (char= ch #\'))
       (parse-string source))
      ((digit-char-p ch)
       (parse-number source))
      ((or (char= ch #\-)
           (char= ch #\+))
       (parse-number source))
      ((char= ch #\t)
       (parse-boolean source))
      ((or (char= ch #\f)
           (char= ch #\n)
           (char= ch #\~))
       (parse-null source))
      (t
       (error 'extraction-error
              :format "Unexpected character: ~A"
              :args (list ch))))))

;;; API - Stream-based

(defun parse-from (source)
  "Parse a YAML scalar value from SOURCE.
SOURCE must be a stream.
Returns the parsed value or +eof+ at end of input.
Handles comments, whitespace, booleans, null, numbers, and strings."
  (let ((ch (peek-chr source)))
    (if (eq ch +eof+)
        +eof+
        (parse-scalar source))))

(defun parse-from-string (string)
  "Parse a YAML scalar value from STRING.
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
