;;;; src/scalars.lisp
;;;; yamcl - YAML scalar parsing

(defpackage #:com.djhaskin.yamcl/scalars
  (:use #:cl #:com.djhaskin.yamcl/utils)
  (:export
   #:parse-from
   #:parse-from-string
   #:parse-scalar-from-string
   #:parse-scalar-lookahead
   #:skip-whitespace-and-comments-lookahead
   #:blankspace-p
   #:whitespace-p))

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
Returns T or NIL. Case-insensitive per YAML 1.2.2 Core Schema."
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (cond
      ((or (char= ch #\t) (char= ch #\T))
       ;; Parse "true" - read and verify each character (case-insensitive)
       (lookahead-read-chr lookahead) ;; consume 't' or 'T'
       (let ((r (lookahead-read-chr lookahead))
             (u (lookahead-read-chr lookahead))
             (e (lookahead-read-chr lookahead)))
         (unless (and (characterp r) (or (char= r #\r) (char= r #\R)))
           (error 'extraction-error :expected "true (case-insensitive)" :got ch))
         (unless (and (characterp u) (or (char= u #\u) (char= u #\U)))
           (error 'extraction-error :expected "true (case-insensitive)" :got ch))
         (unless (and (characterp e) (or (char= e #\e) (char= e #\E)))
           (error 'extraction-error :expected "true (case-insensitive)" :got ch)))
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
      ((or (char= ch #\f) (char= ch #\F))
       ;; Parse "false" - read and verify each character (case-insensitive)
       (lookahead-read-chr lookahead) ;; consume 'f' or 'F'
       (let ((a (lookahead-read-chr lookahead))
             (l1 (lookahead-read-chr lookahead))
             (s (lookahead-read-chr lookahead))
             (e (lookahead-read-chr lookahead)))
         (unless (and (characterp a) (or (char= a #\a) (char= a #\A)))
           (error 'extraction-error :expected "false (case-insensitive)" :got ch))
         (unless (and (characterp l1) (or (char= l1 #\l) (char= l1 #\L)))
           (error 'extraction-error :expected "false (case-insensitive)" :got ch))
         (unless (and (characterp s) (or (char= s #\s) (char= s #\S)))
           (error 'extraction-error :expected "false (case-insensitive)" :got ch))
         (unless (and (characterp e) (or (char= e #\e) (char= e #\E)))
           (error 'extraction-error :expected "false (case-insensitive)" :got ch)))
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
              :expected "true or false (case-insensitive)"
              :got ch)))))

(defun parse-null (lookahead)
  "Parse a null value from LOOKAHEAD.
Returns cl:null for null/~ (case-insensitive for null per YAML Core Schema).
Returns NIL for false."
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (cond
      ((or (char= ch #\n) (char= ch #\N))
       ;; Parse "null" - read and verify each character (case-insensitive)
       (lookahead-read-chr lookahead) ;; consume 'n' or 'N'
       (let ((u (lookahead-read-chr lookahead))
             (l1 (lookahead-read-chr lookahead))
             (l2 (lookahead-read-chr lookahead)))
         (unless (and (characterp u) (or (char= u #\u) (char= u #\U)))
           (error 'extraction-error :expected "null (case-insensitive)" :got ch))
         (unless (and (characterp l1) (or (char= l1 #\l) (char= l1 #\L)))
           (error 'extraction-error :expected "null (case-insensitive)" :got ch))
         (unless (and (characterp l2) (or (char= l2 #\l) (char= l2 #\L)))
           (error 'extraction-error :expected "null (case-insensitive)" :got ch)))
       'cl:null)
      ((char= ch #\~)
       (lookahead-read-chr lookahead)
       'cl:null)
      ((or (char= ch #\f) (char= ch #\F))
       ;; Parse "false" - should be handled by parse-boolean, but keep for completeness
       (lookahead-read-chr lookahead) ;; f or F
       (lookahead-read-chr lookahead) ;; a or A  
       (lookahead-read-chr lookahead) ;; l or L
       (lookahead-read-chr lookahead) ;; s or S
       (lookahead-read-chr lookahead) ;; e or E
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

(defun parse-escape-sequence (lookahead)
  "Parse an escape sequence from LOOKAHEAD.
Returns the character corresponding to the escape sequence.
Handles JSON RFC 8259 Section 7 escapes."
  ;; We've already consumed the backslash, so look at next character
  (let ((ch (lookahead-read-chr lookahead)))
    (cond
      ((char= ch #\") #\")  ; \" → "
      ((char= ch #\\) #\\)  ; \\ → \
      ((char= ch #\/) #\/)  ; \/ → /
      ((char= ch #\b) #\Backspace)  ; \b → backspace
      ((char= ch #\f) #\Page)       ; \f → form feed (form feed is #\Page in CL)
      ((char= ch #\n) #\Newline)    ; \n → newline
      ((char= ch #\r) #\Return)     ; \r → carriage return
      ((char= ch #\t) #\Tab)        ; \t → tab
      ((char= ch #\u)              ; \uXXXX → Unicode character
       ;; Parse 4 hexadecimal digits
       (let* ((hex-chars (loop repeat 4
                               for hex-char = (lookahead-read-chr lookahead)
                               collect hex-char))
              (hex-string (coerce hex-chars 'string))
              (code (parse-integer hex-string :radix 16 :junk-allowed t)))
         (if code
             (code-char code)
             (error 'extraction-error :expected "4 hexadecimal digits after \\u"
                    :got (or (when hex-chars (car hex-chars)) +eof+)))))
      (t (error 'extraction-error :expected "valid escape sequence" :got ch)))))

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
            ((and (not is-single-quote) (char= ch #\\))
             ;; Escape sequence in double-quoted string
             (lookahead-read-chr lookahead) ;; consume the backslash
             (let ((escaped-char (parse-escape-sequence lookahead)))
               (write-char escaped-char buffer)))
            (t
             ;; Normal character
             (write-char (lookahead-read-chr lookahead) buffer)))))
      (lookahead-read-chr lookahead) ;; consume closing quote
      (get-output-stream-string buffer))))

(defun starts-with-reserved-word-p (lookahead)
  "Check if the stream starts with a reserved word (true, false, null, ~).
Returns the canonical lowercase word if it's a reserved word, NIL otherwise.
Accepts specific case variations per YAML 1.2.2 Core Schema."
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (cond
      ((char= ch #\t)
       (let ((r1 (lookahead-peek-chr lookahead 1))
             (u2 (lookahead-peek-chr lookahead 2))
             (e3 (lookahead-peek-chr lookahead 3)))
         (cond
           ;; true (lowercase)
           ((and (characterp r1) (char= r1 #\r)
                 (characterp u2) (char= u2 #\u)
                 (characterp e3) (char= e3 #\e))
            "true")
           ;; True (mixed case, first letter uppercase)
           ((and (characterp r1) (char= r1 #\r)
                 (characterp u2) (char= u2 #\u)
                 (characterp e3) (char= e3 #\e))
            "true")
           (t nil))))
      ((char= ch #\T)
       (let ((r1 (lookahead-peek-chr lookahead 1))
             (u2 (lookahead-peek-chr lookahead 2))
             (e3 (lookahead-peek-chr lookahead 3)))
         ;; True (mixed case) or TRUE (uppercase)
         (cond
           ;; True (mixed case: T r u e)
           ((and (characterp r1) (char= r1 #\r)
                 (characterp u2) (char= u2 #\u)
                 (characterp e3) (char= e3 #\e))
            "true")
           ;; TRUE (uppercase: T R U E)
           ((and (characterp r1) (char= r1 #\R)
                 (characterp u2) (char= u2 #\U)
                 (characterp e3) (char= e3 #\E))
            "true")
           (t nil))))
      ((char= ch #\f)
       (let ((a1 (lookahead-peek-chr lookahead 1))
             (l2 (lookahead-peek-chr lookahead 2))
             (s3 (lookahead-peek-chr lookahead 3))
             (e4 (lookahead-peek-chr lookahead 4)))
         ;; false (lowercase)
         (when (and (characterp a1) (char= a1 #\a)
                    (characterp l2) (char= l2 #\l)
                    (characterp s3) (char= s3 #\s)
                    (characterp e4) (char= e4 #\e))
           "false")))
      ((char= ch #\F)
       (let ((a1 (lookahead-peek-chr lookahead 1))
             (l2 (lookahead-peek-chr lookahead 2))
             (s3 (lookahead-peek-chr lookahead 3))
             (e4 (lookahead-peek-chr lookahead 4)))
         ;; False (mixed case) or FALSE (uppercase)
         (cond
           ;; False (mixed case)
           ((and (characterp a1) (char= a1 #\a)
                 (characterp l2) (char= l2 #\l)
                 (characterp s3) (char= s3 #\s)
                 (characterp e4) (char= e4 #\e))
            "false")
           ;; FALSE (uppercase)
           ((and (characterp a1) (char= a1 #\A)
                 (characterp l2) (char= l2 #\L)
                 (characterp s3) (char= s3 #\S)
                 (characterp e4) (char= e4 #\E))
            "false")
           (t nil))))
      ((char= ch #\n)
       (let ((u1 (lookahead-peek-chr lookahead 1))
             (l2 (lookahead-peek-chr lookahead 2))
             (l3 (lookahead-peek-chr lookahead 3)))
         ;; null (lowercase)
         (when (and (characterp u1) (char= u1 #\u)
                    (characterp l2) (char= l2 #\l)
                    (characterp l3) (char= l3 #\l))
           "null")))
      ((char= ch #\N)
       (let ((u1 (lookahead-peek-chr lookahead 1))
             (l2 (lookahead-peek-chr lookahead 2))
             (l3 (lookahead-peek-chr lookahead 3)))
         ;; Null (mixed case) or NULL (uppercase)
         (cond
           ;; Null (mixed case)
           ((and (characterp u1) (char= u1 #\u)
                 (characterp l2) (char= l2 #\l)
                 (characterp l3) (char= l3 #\l))
            "null")
           ;; NULL (uppercase)
           ((and (characterp u1) (char= u1 #\U)
                 (characterp l2) (char= l2 #\L)
                 (characterp l3) (char= l3 #\L))
            "null")
           (t nil))))
      ((char= ch #\~)
       ;; Check if it's followed by another ~
       (let ((next-ch (lookahead-peek-chr lookahead 1)))
         (if (and (characterp next-ch) (char= next-ch #\~))
             nil  ;; ~~ is not null, it's a string
             "~")))  ;; Single ~ is null
      (t
       nil))))

(defun parse-bareword-string (lookahead)
  "Parse a bareword (plain scalar) string from LOOKAHEAD.
Bareword strings are unquoted strings that don't match other scalar patterns.
They can contain alphanumerics, dashes, and underscores.
Stops at ':' which indicates a mapping separator in YAML."
  (let ((buffer (make-string-output-stream)))
    (loop
      (let ((ch (lookahead-peek-chr lookahead 0)))
        (cond
          ((eq ch +eof+)
           (return))
          ((char= ch #\:)
           ;; : indicates end of bareword (mapping separator)
           (return))
          ((or (alpha-char-p ch)
               (digit-char-p ch)
               (char= ch #\-)
               (char= ch #\_)
               (char= ch #\~))
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
      ((or (alpha-char-p ch) (char= ch #\_) 
           ;; ~ is allowed as start of bareword string when not a reserved word
           (and (char= ch #\~) (null reserved-word)))
       (parse-bareword-string lookahead))
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
