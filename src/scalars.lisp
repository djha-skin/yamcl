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

(defun extract-number (strm chr)
  (declare (type streamable strm)
           (type streamed chr))
  (let ((building nil)
        (last-read chr))
    (loop while (and
                  (not (eq last-read +eof+))
                  (number-char-p last-read))
          do
          (push last-read building)
          (read-chr strm)
          (setf last-read (peek-chr strm)))
    (let ((num-str (build-string building)))
      (cond ((or (equals num-str "+.inf")
                 (equals num-str ".inf"))
             :positive-infinity)
            ((equals num-str "-.inf")
             :negative-infinity)
            ((or (equals num-str ".nan")
                 (equals num-str "+.nan")
                 (equals num-str "-.nan"))
                :not-a-number)
            (t
             (read-from-string num-str nil nil))))))

(defun extract-double-quoted
  (strm chr quote-char)
  (declare (type streamable strm)
           (type streamed chr)
           (type character quote-char))
  (declare (ignore chr))
  (must-read-chr strm)
  (let ((last-read (must-read-chr strm))
        (building nil))
    (loop while (and (not (eq last-read +eof+))
                     (char/= last-read quote-char))
          do
          (if (char= last-read #\\)
            (progn
              (setf last-read (must-read-chr strm))
              (cond (
                     ((char= last-read #\0)
                      (push (code-char 0) building))
                     ((char= last-read #\a)
                      (push (code-char 7) lbuilding))
                     ((char= last-read #\b)
                      (push #\Backspace building))
                     ((char= last-read #\v)
                      (push (code-char 11) building))
                     ((char= last-read #\f)
                      (push #\Page building))
                     ((char= last-read #\r)
                      (push #\Return building))
                     ((char= last-read #\e)
                      (push (code-char 27) building))
                     ((char= last-read #\Space)
                      (push #\Space building))
                     ((char= last-read #\

                     ((char= last-read #\\)
                      (push #\\ building))
                     ((char= last-read #\N)
                      (push (code-char #x85) building))
                     ((char= last-read #\L)
                      (push (code-char #x2028) building))
                     ((char= last-read #\P)
                      (push (code-char #x2029) building))
                     ((char= last-read #\_)
                      (push (code-char #x00A0) building))
                     ((char= last-read #\/)
                      (push last-read building))
((char= last-read quote-char)
                     (push quote-char building))
                     ((char= last-read #\n)
                      (push #\Newline building))
                     ((char= last-read #\t)
                      (push #\Tab building))
                     ((char= last-read #\x)
                        (push
                            (code-char
                            (let ((build-ordinal (make-string 2)))
                                (setf (elt build-ordinal 0) (must-read-chr strm))
                                (setf (elt build-ordinal 1) (must-read-chr strm))
                                (read-from-string build-ordinal nil nil)))
                            building))
                     ((char= last-read #\U)
                      (push
                        (code-char
                          (let ((build-ordinal (make-string 8)))
                            (setf (elt build-ordinal 0) #\#)
                            (setf (elt build-ordinal 1) #\X)
                            (setf (elt build-ordinal 2) (must-read-chr strm))
                            (setf (elt build-ordinal 3) (must-read-chr strm))
                            (setf (elt build-ordinal 4) (must-read-chr strm))
                            (setf (elt build-ordinal 5) (must-read-chr strm))
                            (setf (elt build-ordinal 6) (must-read-chr strm))
                            (setf (elt build-ordinal 7) (must-read-chr strm))
                            (read-from-string build-ordinal nil nil)))
                        building))
                     ((char= last-read #\u)
                      (push
                        (code-char
                          (let ((build-ordinal (make-string 6)))
                            (setf (elt build-ordinal 0) #\#)
                            (setf (elt build-ordinal 1) #\X)
                            (setf (elt build-ordinal 2) (must-read-chr strm))
                            (setf (elt build-ordinal 3) (must-read-chr strm))
                            (setf (elt build-ordinal 4) (must-read-chr strm))
                            (setf (elt build-ordinal 5) (must-read-chr strm))
                            (read-from-string build-ordinal nil nil)))
                        building))
                     (t (error
                          'extraction-error
                          :expected
                          '(#\"
                            #\\
                            #\/
                            #\b
                            #\f
                            #\n
                            #\r
                            #\t
                            #\x
                            #\u
                            #\U)
                          :got
                               last-read))))
            (push last-read building))
          (setf last-read (must-read-chr strm)))
    (build-string building)))

(defconstant +start-verbatim+ #\|)
(defconstant +start-prose+ #\>)
(defconstant +start-comment+ #\#)

(defun blankspace-p (chr)
  (declare (type character chr))
  (or
    (char= chr #\Tab)
    (char= chr #\Space)
    ))

(defun whitespace-p (chr)
  (declare (type character chr))
    (or
      (char= chr #\Newline)
      (char= chr #\Return)
      (char= chr #\Page)
      (blankspace-p chr)))

(defun sepchar-p (chr)
  (declare (type character chr))
  (or (whitespace-p chr)
      (char= chr #\,)
      (char= chr #\:)))

(defun guarded-sepchar-p (chr)
  (declare (type (or null character) chr))
    (unless (null chr)
      (sepchar-p chr)))

(defun guarded-blankspace-p (chr)
  (declare (type (or null character) chr))
    (unless (null chr)
      (blankspace-p chr)))

(defun extract-comment (strm)
  (declare (type streamable strm))
  (loop with last-read = (read-chr strm)
        while (and
                (not (eq last-read +eof+))
                (not (char= last-read #\Newline)))
        do
        (setf last-read (read-chr strm))
        finally
        (return last-read)))

(defun extract-sep (strm chr pred)
  (declare (type streamable strm)
           (type streamed chr)
           (type function pred))
  (loop with just-read = nil
        with next = chr
    do
    (cond
      ((eq next +eof+)
       (return just-read))
      ((eql next +start-comment+)
       (setf just-read (extract-comment strm)))
      ((funcall pred next)
       (setf just-read (must-read-chr strm)))
      (t
        (return just-read)))
    (setf next (peek-chr strm))))

(defun extract-list-sep (strm chr)
  (declare (type streamable strm)
           (type streamed chr))
  (extract-sep strm chr #'guarded-sepchar-p))

(defun extract-blob-sep (strm chr)
  (declare (type streamable strm)
           (type streamed chr))
  (extract-sep strm chr #'guarded-blankspace-p))
#|





;;; Character Queue (implement inline to avoid circular dependency)
(deftype char-queue () 'com.djhaskin.yamcl:char-queue)

(defun cq-append (cq char)
  "Append a character to the end of a char-queue."
  (push char (slot-value cq 'com.djhaskin.yamcl::chars)))

(defun cq-peek (cq)
  "Peek at the next character without consuming it."
  (let ((chars (slot-value cq 'com.djhaskin.yamcl::chars)))
    (when chars
      (car chars))))

(defun cq-pop (cq)
  "Pop and return the next character."
  (pop (slot-value cq 'com.djhaskin.yamcl::chars)))

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
      ((and (characterp ch) (char= ch #\f))
       (read-chr source)
       (loop repeat 4
             for ch = (read-chr source)
             do (push ch acc))
       (let ((word (build-string acc)))
         (if (string= word "alse")
             nil
             (error 'extraction-error
                    :format "Expected null or false, got: ~A"
                    :args (list word)))))
      ;; Check for null
      ((and (characterp ch) (char= ch #\n))
       (read-chr source)
       (loop repeat 3
             for ch = (read-chr source)
             do (push ch acc))
       (let ((word (build-string acc)))
         (if (string= word "ull")
             +null+
             (error 'extraction-error
                    :format "Expected null, got: ~A"
                    :args (list word)))))
      ;; Check for YAML ~ (null)
      ((and (characterp ch) (char= ch #\~))
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
    (when (and (characterp ch) (or (char= ch #\-) (char= ch #\+)))
      (push ch acc)
      (read-chr source)
      (setf ch (peek-chr source)))
    ;; Parse digits before decimal/exponent
    (loop while (and (characterp ch) (digit-char-p ch))
          do (push ch acc)
             (read-chr source)
             (setf ch (peek-chr source)))
    ;; Handle decimal point
    (when (and (characterp ch) (char= ch #\.))
      (push ch acc)
      (read-chr source)
      (setf ch (peek-chr source))
      (loop while (and (characterp ch) (digit-char-p ch))
            do (push ch acc)
               (read-chr source)
               (setf ch (peek-chr source))))
    ;; Handle exponent
    (when (and (characterp ch) (or (char= ch #\e) (char= ch #\E)))
      (push ch acc)
      (read-chr source)
      (setf ch (peek-chr source))
      (when (and (characterp ch) (or (char= ch #\-) (char= ch #\+)))
        (push ch acc)
        (read-chr source)
        (setf ch (peek-chr source)))
      (loop while (and (characterp ch) (digit-char-p ch))
            do (push ch acc)
               (read-chr source)
               (setf ch (peek-chr source))))
    (if (null acc)
        (error 'extraction-error
               :format "Expected number, got: ~A"
               :args (list ch))
        (let ((num-str (build-string acc)))
          (cond
            ((position #\. num-str) (read-from-string num-str))
            ((position #\e num-str) (read-from-string num-str))
            ((position #\E num-str) (read-from-string num-str))
            (t (let ((int-val (parse-integer num-str)))
                 (if (or (>= int-val 536870912)
                         (<= int-val -536870913))
                     (coerce int-val 'double-float)
                     int-val))))))))

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
                     (when (or (and (>= codepoint #xD800) (<= codepoint #xDFFF))
                               (> codepoint #x10FFFF))
                       (error 'extraction-error
                              :format "Invalid unicode codepoint: ~X"
                              :args (list codepoint)))
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

;;; Convenience wrapper for tests

(defun parse-scalar-from-string (string)
  "Parse a YAML scalar value from STRING.
This is a convenience wrapper for tests."
  (parse-from-string string))

