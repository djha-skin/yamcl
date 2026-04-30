;;;; src/scalars.lisp
;;;; yamcl - YAML scalar parsing

(defpackage #:com.djhaskin.yamcl/scalars
  (:use #:cl
        #:com.djhaskin.yamcl/utils)
  (:export
   #:parse-scalar
   #:parse-scalar-from-string
   #:parse-boolean
   #:parse-null
   #:parse-number
   #:parse-string
   #:peek-chr
   #:read-chr
   #:skip-whitespace-and-comments
   #:blankspace-p
   #:whitespace-p
   #:build-string))

(in-package #:com.djhaskin.yamcl/scalars)

;;; Simple stub implementations to get tests running

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

(defun peek-chr (source)
  "Peek at the next character in SOURCE without consuming it.
SOURCE must be a stream.
Returns +eof+ at end of input."
  (peek-char nil source nil +eof+ nil))

(defun read-chr (source)
  "Read and return the next character from SOURCE, consuming it.
SOURCE must be a stream.
Returns +eof+ at end of input."
  (read-char source nil +eof+ nil))

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
                ;; Skip comment
                (loop while (and (characterp (peek-chr source))
                                 (not (char= (peek-chr source) #\Newline)))
                      do (read-chr source))))
             (setf ch (peek-chr source)))
    ch))

(defun parse-boolean (source)
  "Parse a boolean value (true/false) from SOURCE.
Returns T or NIL."
  (let ((ch (peek-chr source)))
    (cond
      ((char= ch #\t)
       (read-chr source) ;; t
       (read-chr source) ;; r
       (read-chr source) ;; u
       (read-chr source) ;; e
       t)
      ((char= ch #\f)
       (read-chr source) ;; f
       (read-chr source) ;; a
       (read-chr source) ;; l
       (read-chr source) ;; s
       (read-chr source) ;; e
       nil)
      (t
       (error 'extraction-error
              :expected "true or false"
              :got ch)))))

(defun parse-null (source)
  "Parse a null value from SOURCE.
Returns +null+ for null/~.
Returns NIL for false."
  (let ((ch (peek-chr source)))
    (cond
      ((char= ch #\n)
       (read-chr source) ;; n
       (read-chr source) ;; u
       (read-chr source) ;; l
       (read-chr source) ;; l
       +null+)
      ((char= ch #\~)
       (read-chr source)
       +null+)
      ((char= ch #\f)
       (read-chr source) ;; f
       (read-chr source) ;; a
       (read-chr source) ;; l
       (read-chr source) ;; s
       (read-chr source) ;; e
       nil)
      (t
       (error 'extraction-error
              :expected "null, false, or ~"
              :got ch)))))

(defun parse-number (source)
  "Parse a number from SOURCE.
Handles integers and floats with optional exponent."
  (let ((buffer (make-string-output-stream)))
    (loop for ch = (peek-chr source)
          while (and (characterp ch)
                     (or (digit-char-p ch)
                         (char= ch #\.)
                         (char= ch #\-)
                         (char= ch #\+)
                         (char= ch #\e)
                         (char= ch #\E)))
          do (write-char (read-chr source) buffer))
    (let ((str (get-output-stream-string buffer)))
      (if (string= str "")
          (error 'extraction-error :expected "number" :got (peek-chr source))
          (read-from-string str)))))

(defun parse-string (source)
  "Parse a double-quoted string from SOURCE."
  (read-chr source) ;; consume opening quote
  (let ((buffer (make-string-output-stream)))
    (loop for ch = (peek-chr source)
          while (and (characterp ch)
                     (not (char= ch #\")))
          do (write-char (read-chr source) buffer))
    (read-chr source) ;; consume closing quote
    (get-output-stream-string buffer)))

(defun parse-scalar (source)
  "Parse a scalar value from SOURCE.
Detects and delegates to specific parsers."
  (skip-whitespace-and-comments source)
  (let ((ch (peek-chr source)))
    (cond
      ((eq ch +eof+) +eof+)
      ((char= ch #\") (parse-string source))
      ((digit-char-p ch) (parse-number source))
      ((or (char= ch #\-) (char= ch #\+)) (parse-number source))
      ((char= ch #\t) (parse-boolean source))
      ((or (char= ch #\f) (char= ch #\n) (char= ch #\~)) (parse-null source))
      (t
       (error 'extraction-error
              :format "Unexpected character: ~A"
              :args (list ch))))))

(defun parse-from (source)
  "Parse a YAML scalar value from SOURCE.
SOURCE must be a stream.
Returns the parsed value or +eof+ at end of input."
  (let ((ch (peek-chr source)))
    (if (eq ch +eof+)
        +eof+
        (parse-scalar source))))

(defun parse-from-string (string)
  "Parse a YAML scalar value from STRING.
Convenience wrapper around parse-from."
  (with-input-from-string (stream string)
    (parse-from stream)))

(defun parse-scalar-from-string (string)
  "Parse a YAML scalar value from STRING.
This is a convenience wrapper for tests."
  (parse-from-string string))
