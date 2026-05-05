;;;; src/scalars.lisp
;;;; yamcl - YAML scalar parsing

(defpackage #:com.djhaskin.yamcl/scalars
  (:use #:cl #:com.djhaskin.yamcl/utils)
  (:export
   #:parse-from
   #:parse-from-string
   #:parse-scalar-from-string))

(in-package #:com.djhaskin.yamcl/scalars)

;;; Simple stub implementations to get tests running

(defun blankspace-p (ch)
  "Check if character is a blankspace (space or tab)."
  (and (characterp ch)
       (or (char= ch #\Space) (char= ch #\Tab))))

(defun whitespace-p (ch)
  "Check if character is any whitespace."
  (and (characterp ch)
       (or (char= ch #\Newline)
           (char= ch #\Return)
           (char= ch #\Tab)
           (char= ch #\Space)
           (blankspace-p ch))))

(defun build-string (list)
  "Build a string from a list of characters, reversing the list."
  (coerce (reverse list) 'string))





(defun skip-whitespace-and-comments-lookahead (lookahead)
  "Skip blankspaces, newlines, and comments in LOOKAHEAD.
Returns the first non-skipped character (peeked)."
  (loop for ch = (lookahead-peek-chr lookahead 0)
        while (and (not (eq ch +eof+))
                   (or (blankspace-p ch)
                       (whitespace-p ch)
                       (char= ch #\,)
                       (char= ch #\#)))
        do (cond
             ((or (blankspace-p ch) (char= ch #\,))
              (lookahead-read-chr lookahead))
             ((whitespace-p ch)
              (lookahead-read-chr lookahead))
             ((char= ch #\#)
              (lookahead-read-chr lookahead) ; consume #
              ;; Skip until end of line (newline/return) or EOF
              (loop for next = (lookahead-peek-chr lookahead 0)
                    while (and (characterp next)
                               (not (or (char= next #\Newline)
                                        (char= next #\Return))))
                    do (lookahead-read-chr lookahead))
              ;; Consume the newline/return if present
              (let ((next (lookahead-peek-chr lookahead 0)))
                (when (and (characterp next)
                           (or (char= next #\Newline)
                               (char= next #\Return)))
                  (lookahead-read-chr lookahead))))))
  (lookahead-peek-chr lookahead 0))

(defun parse-boolean (lookahead)
  "Parse a boolean value (true/false) from LOOKAHEAD.
Returns T or NIL."
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (cond
      ((char= ch #\t)
       (lookahead-read-chr lookahead) ;; t
       (lookahead-read-chr lookahead) ;; r
       (lookahead-read-chr lookahead) ;; u
       (lookahead-read-chr lookahead) ;; e
       t)
      ((char= ch #\f)
       (lookahead-read-chr lookahead) ;; f
       (lookahead-read-chr lookahead) ;; a
       (lookahead-read-chr lookahead) ;; l
       (lookahead-read-chr lookahead) ;; s
       (lookahead-read-chr lookahead) ;; e
       nil)
      (t
       (error 'extraction-error
              :expected "true or false"
              :got ch)))))

(defun parse-null (lookahead)
  "Parse a null value from LOOKAHEAD.
Returns +null+ for null/~.
Returns NIL for false."
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (cond
      ((char= ch #\n)
       (lookahead-read-chr lookahead) ;; n
       (lookahead-read-chr lookahead) ;; u
       (lookahead-read-chr lookahead) ;; l
       (lookahead-read-chr lookahead) ;; l
       'cl:null)
      ((char= ch #\~)
       (lookahead-read-chr lookahead)
       'cl:null)
      ((char= ch #\f)
       (lookahead-read-chr lookahead) ;; f
       (lookahead-read-chr lookahead) ;; a
       (lookahead-read-chr lookahead) ;; l
       (lookahead-read-chr lookahead) ;; s
       (lookahead-read-chr lookahead) ;; e
       nil)
      (t
       (error 'extraction-error
              :expected "null, false, or ~"
              :got ch)))))

(defun parse-number (lookahead)
  "Parse a number from LOOKAHEAD.
Handles integers and floats with optional exponent."
  (let ((buffer (make-string-output-stream)))
    (loop for ch = (lookahead-peek-chr lookahead 0)
          while (and (characterp ch)
                     (or (digit-char-p ch)
                         (char= ch #\.)
                         (char= ch #\-)
                         (char= ch #\+)
                         (char= ch #\e)
                         (char= ch #\E)
                         (char= ch #\_)
                         (char= ch #\o)
                         (char= ch #\x)
                         (char= ch #\b)))
          do (write-char (lookahead-read-chr lookahead) buffer))
    (let ((str (get-output-stream-string buffer)))
      (if (string= str "")
          (error 'extraction-error :expected "number" :got (lookahead-peek-chr lookahead 0))
          ;; Convert YAML number syntax to Common Lisp syntax
          (let ((converted (yaml-number-to-cl str)))
            (read-from-string converted))))))

(defun parse-string (lookahead)
  "Parse a double-quoted string from LOOKAHEAD."
  (lookahead-read-chr lookahead) ;; consume opening quote
  (let ((buffer (make-string-output-stream)))
    (loop for ch = (lookahead-peek-chr lookahead 0)
          while (and (characterp ch)
                     (not (char= ch #\")))
          do (write-char (lookahead-read-chr lookahead) buffer))
    (lookahead-read-chr lookahead) ;; consume closing quote
    (get-output-stream-string buffer)))

(defun parse-scalar-lookahead (lookahead)
  "Parse a scalar value from LOOKAHEAD.
Detects and delegates to specific parsers."
  (skip-whitespace-and-comments-lookahead lookahead)
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (cond
      ((eq ch +eof+) +eof+)
      ((char= ch #\") (parse-string lookahead))
      ((digit-char-p ch) (parse-number lookahead))
      ((or (char= ch #\-) (char= ch #\+)) (parse-number lookahead))
      ((char= ch #\t) (parse-boolean lookahead))
      ((or (char= ch #\f) (char= ch #\n) (char= ch #\~)) (parse-null lookahead))
      (t
       (error 'extraction-error
              :expected "valid scalar"
              :got ch)))))

(defun parse-from (source)
  "Parse a YAML scalar value from SOURCE.
SOURCE must be a stream.
Returns the parsed value or +eof+ at end of input."
  ;; Create a lookahead-stream wrapper with buffer size 4
  ;; (enough to check for --- and ... document markers)
  (let ((lookahead (new-lookahead-stream source :buffer-size 4)))
    ;; Call the internal parse function that works with lookahead-stream
    (prog1
        (parse-from-lookahead lookahead)
      ;; Unread any buffered characters back to the stream
      (unread-all lookahead))))

(defun parse-from-lookahead (lookahead)
  "Parse a YAML scalar value from LOOKAHEAD (a lookahead-stream).
Internal function used by parse-from."
  (skip-whitespace-and-comments-lookahead lookahead)
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (cond
      ((eq ch +eof+)
       +eof+)
      ;; Check for document markers using peeking only (no consumption)
      ((or (char= ch #\-) (char= ch #\.))
       ;; Check if we have at least 3 characters to peek at
       (let ((ch1 (lookahead-peek-chr lookahead 1))
             (ch2 (lookahead-peek-chr lookahead 2)))
         (cond
           ;; Handle --- document start (three dashes)
           ((and (char= ch #\-) 
                 (characterp ch1) (char= ch1 #\-)
                 (characterp ch2) (char= ch2 #\-))
            ;; Consume all three dashes
            (lookahead-read-chr lookahead) ; first -
            (lookahead-read-chr lookahead) ; second -
            (lookahead-read-chr lookahead) ; third -
            ;; Skip whitespace/comments after marker
            (skip-whitespace-and-comments-lookahead lookahead)
            ;; Parse content after marker
            (parse-from-lookahead lookahead))
           
           ;; Handle ... document end (three dots)  
           ((and (char= ch #\.)
                 (characterp ch1) (char= ch1 #\.)
                 (characterp ch2) (char= ch2 #\.))
            ;; Consume all three dots
            (lookahead-read-chr lookahead) ; first .
            (lookahead-read-chr lookahead) ; second .
            (lookahead-read-chr lookahead) ; third .
            +eof+) ; document end marker returns EOF
           
           (t
            ;; Not a document marker, parse as scalar
            (parse-scalar-lookahead lookahead)))))
      (t
       (parse-scalar-lookahead lookahead)))))

(defun parse-from-string (string)
  "Parse a YAML scalar value from STRING.
Convenience wrapper around parse-from."
  (with-input-from-string (stream string)
    (parse-from stream)))

(defun parse-scalar-from-string (string)
  "Parse a YAML scalar value from STRING.
This is a convenience wrapper for tests."
  (parse-from-string string))
