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
Returns T or NIL. Case-sensitive: only 'true' and 'false' in lowercase."
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (cond
      ((char= ch #\t)
       ;; Parse "true" - read and verify each character
       (lookahead-read-chr lookahead) ;; consume 't'
       (unless (char= (lookahead-read-chr lookahead) #\r)
         (error 'extraction-error :expected "true" :got ch))
       (unless (char= (lookahead-read-chr lookahead) #\u)
         (error 'extraction-error :expected "true" :got ch))
       (unless (char= (lookahead-read-chr lookahead) #\e)
         (error 'extraction-error :expected "true" :got ch))
       ;; Check that we're at end of scalar (whitespace, comment, or EOF)
       (let ((next-ch (lookahead-peek-chr lookahead 0)))
         (when (and (characterp next-ch)
                    (not (char= next-ch #\#)) ; comment
                    (not (char= next-ch #\Space))
                    (not (char= next-ch #\Tab))
                    (not (char= next-ch #\Newline))
                    (not (char= next-ch #\Return)))
           (error 'extraction-error :expected "end of scalar after 'true'" :got next-ch)))
       t)
      ((char= ch #\f)
       ;; Parse "false" - read and verify each character
       (lookahead-read-chr lookahead) ;; consume 'f'
       (unless (char= (lookahead-read-chr lookahead) #\a)
         (error 'extraction-error :expected "false" :got ch))
       (unless (char= (lookahead-read-chr lookahead) #\l)
         (error 'extraction-error :expected "false" :got ch))
       (unless (char= (lookahead-read-chr lookahead) #\s)
         (error 'extraction-error :expected "false" :got ch))
       (unless (char= (lookahead-read-chr lookahead) #\e)
         (error 'extraction-error :expected "false" :got ch))
       ;; Check that we're at end of scalar (whitespace, comment, or EOF)
       (let ((next-ch (lookahead-peek-chr lookahead 0)))
         (when (and (characterp next-ch)
                    (not (char= next-ch #\#)) ; comment
                    (not (char= next-ch #\Space))
                    (not (char= next-ch #\Tab))
                    (not (char= next-ch #\Newline))
                    (not (char= next-ch #\Return)))
           (error 'extraction-error :expected "end of scalar after 'false'" :got next-ch)))
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
Handles integers and floats with optional exponent.
Returns keywords for special float values: :positive-infinity, :negative-infinity, :not-a-number"
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
                         (char= ch #\b)
                         ;; Allow hex digits (both cases)
                         (char= (char-upcase ch) #\A)
                         (char= (char-upcase ch) #\B)
                         (char= (char-upcase ch) #\C)
                         (char= (char-upcase ch) #\D)
                         (char= (char-upcase ch) #\E)
                         (char= (char-upcase ch) #\F)
                         ;; Allow letters for special float values (.inf, .nan)
                         (char= (char-upcase ch) #\I)
                         (char= (char-upcase ch) #\N)))
          do (write-char (lookahead-read-chr lookahead) buffer))
    (let ((str (get-output-stream-string buffer)))
      (if (string= str "")
          (error 'extraction-error :expected "number" :got (lookahead-peek-chr lookahead 0))
          ;; Check for special float values - return keywords for IEEE float compatibility
          (cond
            ((or (string-equal str ".inf") (string-equal str "+.inf"))
             :positive-infinity)
            ((string-equal str "-.inf")
             :negative-infinity)
            ((string-equal str ".nan")
             :not-a-number)
            (t
             ;; Convert YAML number syntax to Common Lisp syntax
             (let ((converted (yaml-number-to-cl str)))
               (read-from-string converted))))))))

(defun parse-string (lookahead)
  "Parse a quoted string from LOOKAHEAD.
Handles both single-quoted (') and double-quoted (\") strings."
  (let ((quote-char (lookahead-read-chr lookahead))) ;; consume opening quote
    (let ((buffer (make-string-output-stream))
          (is-single-quote (char= quote-char #\')))
      (loop
        (let ((ch (lookahead-peek-chr lookahead 0)))
          (cond
            ((eq ch +eof+)
             (error 'extraction-error :expected (format nil "closing ~A" quote-char) :got +eof+))
            ((char= ch quote-char)
             ;; Might be closing quote or escaped quote (for single quotes)
             (if (and is-single-quote
                      (let ((next-ch (lookahead-peek-chr lookahead 1)))
                        (and (characterp next-ch) (char= next-ch #\'))))
                 ;; It's an escaped quote: '' -> '
                 (progn
                   (lookahead-read-chr lookahead) ;; consume first '
                   (lookahead-read-chr lookahead) ;; consume second '
                   (write-char #\' buffer))
                 ;; It's the closing quote
                 (return)))
            (t
             ;; Normal character
             (write-char (lookahead-read-chr lookahead) buffer)))))
      (lookahead-read-chr lookahead) ;; consume closing quote
      (get-output-stream-string buffer))))

(defun starts-with-reserved-word-p (lookahead)
  "Check if the stream starts with a reserved word (true, false, null, ~).
Returns the word if it's a reserved word, NIL otherwise."
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (cond
      ((char= ch #\t)
       (and (char= (lookahead-peek-chr lookahead 1) #\r)
            (char= (lookahead-peek-chr lookahead 2) #\u)
            (char= (lookahead-peek-chr lookahead 3) #\e)
            "true"))
      ((char= ch #\f)
       (and (char= (lookahead-peek-chr lookahead 1) #\a)
            (char= (lookahead-peek-chr lookahead 2) #\l)
            (char= (lookahead-peek-chr lookahead 3) #\s)
            (char= (lookahead-peek-chr lookahead 4) #\e)
            "false"))
      ((char= ch #\n)
       (and (char= (lookahead-peek-chr lookahead 1) #\u)
            (char= (lookahead-peek-chr lookahead 2) #\l)
            (char= (lookahead-peek-chr lookahead 3) #\l)
            "null"))
      ((char= ch #\~)
       "~")
      (t
       nil))))

(defun parse-bareword-string (lookahead)
  "Parse a bareword (plain scalar) string from LOOKAHEAD.
Bareword strings are unquoted strings that don't match other scalar patterns.
They can contain alphanumerics, dashes, and underscores."
  (let ((buffer (make-string-output-stream)))
    (loop
      (let ((ch (lookahead-peek-chr lookahead 0)))
        (cond
          ((eq ch +eof+)
           (return))
          ((or (alpha-char-p ch)
               (digit-char-p ch)
               (char= ch #\-)
               (char= ch #\_))
           (write-char (lookahead-read-chr lookahead) buffer))
          (t
           (return)))))
    (let ((result (get-output-stream-string buffer)))
      (if (string= result "")
          (error 'extraction-error :expected "bareword string" :got (lookahead-peek-chr lookahead 0))
          result))))

(defun parse-scalar-lookahead (lookahead)
  "Parse a scalar value from LOOKAHEAD.
Detects and delegates to specific parsers."
  (skip-whitespace-and-comments-lookahead lookahead)
  (let ((ch (lookahead-peek-chr lookahead 0))
        (reserved-word (starts-with-reserved-word-p lookahead)))
    (cond
      ((eq ch +eof+) +eof+)
      ((or (char= ch #\") (char= ch #\')) (parse-string lookahead))
      ((digit-char-p ch) (parse-number lookahead))
      ((or (char= ch #\-) (char= ch #\+) (char= ch #\.)) (parse-number lookahead))
      ((equal reserved-word "true") (parse-boolean lookahead))
      ((or (equal reserved-word "false") (equal reserved-word "null") (equal reserved-word "~"))
       (parse-null lookahead))
      ((or (alpha-char-p ch) (char= ch #\_)) (parse-bareword-string lookahead))
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
  (let ((lookahead (new-lookahead-stream source :buffer-size 5)))
    ;; Call the internal parse function that works with lookahead-stream
    (let ((result (parse-from-lookahead lookahead)))
      ;; After parsing, skip any trailing whitespace and comments
      (skip-whitespace-and-comments-lookahead lookahead)
      ;; If we got a scalar (not EOF), check for invalid trailing content
      ;; Allow document markers (--- and ...) after scalars
      (unless (eq result +eof+)
        (let ((next-ch (lookahead-peek-chr lookahead 0)))
          (unless (or (eq next-ch +eof+)
                      (char= next-ch #\-)  ; possible document start
                      (char= next-ch #\.)) ; possible document end
            (error 'extraction-error
                   :expected "end of input or document marker"
                   :got next-ch))))
      ;; Unread any buffered characters back to the stream
      (unread-all lookahead)
      result)))

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
