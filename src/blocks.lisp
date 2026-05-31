;;;; src/blocks.lisp
;;;; yamcl - YAML block collections parsing

(defpackage #:com.djhaskin.yamcl/blocks
  (:use #:cl #:com.djhaskin.yamcl/utils)
  (:import-from #:com.djhaskin.yamcl/scalars
                #:parse-scalar-lookahead
                #:skip-whitespace-and-comments-lookahead
                #:parse-flow-scalar-lookahead
                #:skip-flow-separator)
  (:export
   #:parse-mapping-from-key
   #:parse-block-value
   #:parse-block-sequence
   #:parse-flow-sequence
   #:parse-flow-mapping
   #:parse-literal-block-scalar
   #:scalar-to-key-string))

(in-package #:com.djhaskin.yamcl/blocks)

(defun scalar-to-key-string (scalar)
  (cond
    ((stringp scalar) scalar)
    ((null scalar) "false")
    ((eq scalar 'cl:null) "null")
    ((eq scalar t) "true")
    (t (format nil "~A" scalar))))

(defun colon-mapping-separator-p (lookahead)
  (let ((ch1 (lookahead-peek-chr lookahead 1)))
    (cond
      ((or (null ch1) (eq ch1 +eof+)) t)
      ((char= ch1 #\Space) t)
      ((char= ch1 #\Tab) t)
      ((char= ch1 #\Newline) t)
      ((char= ch1 #\Return) t)
      ((char= ch1 #\#) t)
      (t nil))))

(defun parse-value-after-colon (lookahead)
  (skip-inline-whitespace lookahead)
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (cond
      ((or (null ch) (eq ch +eof+)
           (char= ch #\Newline) (char= ch #\Return))
       +null+)
      ((char= ch #\#)
       (skip-whitespace-and-comments-lookahead lookahead)
       (let ((next (lookahead-peek-chr lookahead 0)))
         (if (or (null next) (eq next +eof+)
                 (char= next #\Newline) (char= next #\Return))
             +null+
             (parse-scalar-lookahead lookahead))))
      ;; Flow sequence value
      ((char= ch #\[)
       (parse-flow-sequence lookahead))
      ;; Flow mapping value
      ((char= ch #\{)
       (parse-flow-mapping lookahead))
      ;; Literal block scalar value
      ((char= ch #\|)
       (parse-literal-block-scalar lookahead))
      (t
       (parse-scalar-lookahead lookahead)))))

(defun try-parse-next-pair (lookahead table indent
                            &optional (value-parser
                                        #'parse-block-value))
  "Try to parse another key-value pair at the given INDENT level.
Skips whitespace/comments first. If the next content is at a
different indent level, returns NIL without consuming anything.
If at the same indent, parses a key-value pair and adds to TABLE.
VALUE-PARSER is called for values that need block parsing
(sequences, nested mappings on next lines)."
  (skip-whitespace-and-comments-lookahead lookahead)
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (when (or (null ch) (eq ch +eof+))
      (return-from try-parse-next-pair nil)))
  (let ((current-col (current-column lookahead)))
    (when (/= current-col indent)
      (return-from try-parse-next-pair nil)))
  (let ((key (parse-scalar-lookahead lookahead)))
    (when (eq key +eof+)
      (return-from try-parse-next-pair nil))
    (skip-inline-whitespace lookahead)
    (let ((ch (lookahead-peek-chr lookahead 0)))
      (when (or (not (characterp ch))
                (char/= ch #\:))
        (return-from try-parse-next-pair nil))
      (unless (colon-mapping-separator-p lookahead)
        (return-from try-parse-next-pair nil))
      (lookahead-read-chr lookahead)
      (let* ((key-str (scalar-to-key-string key))
             (value (parse-value-after-colon
                      lookahead)))
        (if (eq value +null+)
            (progn
              (skip-whitespace-and-comments-lookahead
                lookahead)
              (let ((next-ch
                      (lookahead-peek-chr lookahead 0))
                    (next-col
                      (current-column lookahead)))
                (if (and (characterp next-ch)
                         (> next-col indent))
                    (setf (gethash key-str table)
                          (funcall value-parser
                                   lookahead next-col))
                    (setf (gethash key-str table)
                          +null+))))
            (setf (gethash key-str table) value))
        t))))

(defun parse-mapping-from-key (lookahead key indent)
  "Given a pre-parsed KEY at INDENT level, check if a colon
follows. If yes, parse the value and return a hash table.
If the value is empty (+null+), check for indented content on
the next line(s) -- if found at a deeper indent, recursively
parse as a nested mapping."
  (skip-inline-whitespace lookahead)
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (unless (and (characterp ch) (char= ch #\:))
      (return-from parse-mapping-from-key nil))
    (unless (colon-mapping-separator-p lookahead)
      (return-from parse-mapping-from-key nil))
    (lookahead-read-chr lookahead)
    (let* ((key-str (scalar-to-key-string key))
           (value (parse-value-after-colon lookahead))
           (table (make-hash-table :test 'equal)))
      (if (eq value +null+)
          (progn
            (skip-whitespace-and-comments-lookahead
              lookahead)
            (let ((next-ch
                    (lookahead-peek-chr lookahead 0))
                  (next-col
                    (current-column lookahead)))
              (if (and (characterp next-ch)
                       (> next-col indent))
                  (setf (gethash key-str table)
                        (parse-block-value
                          lookahead next-col))
                  (setf (gethash key-str table)
                        +null+)))
            (loop while
              (try-parse-next-pair
                lookahead table indent))
            table)
          (progn
            (setf (gethash key-str table) value)
            (loop while
              (try-parse-next-pair
                lookahead table indent))
            table)))))

(defun parse-block-value (lookahead &optional (indent 0))
  "Parse a YAML block-style value from LOOKAHEAD at INDENT
level. Checks for block sequence entries first, then uses
scalar-first approach: read a scalar, check for colon.
If colon follows, it is a mapping key -- delegate to
parse-mapping-from-key. If not, return the scalar as-is."
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (cond
      ;; Block sequence entry (- space or - eol)
      ((and (characterp ch)
            (char= ch #\-)
            (let ((ch1 (lookahead-peek-chr
                         lookahead 1)))
              (and (characterp ch1)
                   (or (char= ch1 #\Space)
                       (char= ch1 #\Newline)
                       (char= ch1 #\Return)))))
       (parse-block-sequence
         lookahead indent #'parse-block-value))
      ;; Scalar-first approach
      (t
       (let ((scalar
               (parse-scalar-lookahead lookahead)))
         (if (eq scalar +eof+)
             +eof+
             (or (parse-mapping-from-key
                   lookahead scalar indent)
                 scalar)))))))

(defun parse-block-sequence (lookahead indent item-parser)
  "Parse a block sequence from LOOKAHEAD at INDENT level.
ITEM-POP is a function (LOOKAHEAD INDENT) that parses
a single sequence item.
Returns a list of parsed items."
  (let ((items nil))
    (loop
      ;; Consume the dash
      (lookahead-read-chr lookahead)
      ;; Consume trailing space if present
      (let ((ch (lookahead-peek-chr lookahead 0)))
        (when (and (characterp ch)
                   (or (char= ch #\Space)
                       (char= ch #\Tab)))
          (lookahead-read-chr lookahead)))
      ;; Parse the item at deeper indent
      (let ((item (funcall item-parser
                           lookahead (+ indent 2))))
        (push item items))
      ;; Skip to next line
      (skip-whitespace-and-comments-lookahead lookahead)
      ;; Check indent matches
      (let ((col (current-column lookahead)))
        (when (/= col indent)
          (return)))
      ;; Check for dash (space or newline follows)
      (let ((ch (lookahead-peek-chr lookahead 0))
            (ch1 (lookahead-peek-chr lookahead 1)))
        (unless (and (characterp ch)
                     (char= ch #\-)
                     (characterp ch1)
                     (or (char= ch1 #\Space)
                         (char= ch1 #\Newline)
                         (char= ch1 #\Return)))
          (return))))
    (reverse items)))

(defun parse-flow-sequence (lookahead)
  "Parse a YAML flow sequence [a, b, c] from LOOKAHEAD.
Returns a list of parsed items.
Handles empty sequences, trailing commas, nested
flow sequences, and comments inside the sequence."
  (lookahead-read-chr lookahead) ;; consume [
  (let ((items nil))
    (loop
      (skip-flow-separator lookahead)
      (let ((ch (lookahead-peek-chr lookahead 0)))
        (cond
          ;; End of sequence
          ((char= ch #\])
           (lookahead-read-chr lookahead)
           (return (reverse items)))
          ;; Nested flow sequence
          ((char= ch #\[)
           (push (parse-flow-sequence lookahead)
                 items))
          ;; Nested flow mapping
          ((char= ch #\{)
           (push (parse-flow-mapping lookahead)
                 items))
          ;; Comma (at start or after another comma)
          ((char= ch #\,)
           (lookahead-read-chr lookahead))
          ;; Scalar value
          (t
           (push (parse-flow-scalar-lookahead
                   lookahead)
                 items)
           ;; After scalar, check for , or ]
           (skip-flow-separator lookahead)
           (let ((ch2
                   (lookahead-peek-chr lookahead 0)))
             (cond
               ((char= ch2 #\])
                (lookahead-read-chr lookahead)
                (return (reverse items)))
               ((char= ch2 #\,)
                (lookahead-read-chr lookahead))
               (t
                (error
                  'extraction-error
                  :expected
                  "comma or closing bracket"
                  :got ch2))))))))))

(defun parse-flow-mapping (lookahead)
  "Parse a YAML flow mapping {key: value, ...} from LOOKAHEAD.
Returns a hash table with string keys.
Handles empty mappings, trailing commas, nested flow
collections, and comments."
  (lookahead-read-chr lookahead)
  (let ((table (make-hash-table :test 'equal)))
    (loop
      (skip-flow-separator lookahead)
      (let ((ch (lookahead-peek-chr lookahead 0)))
        (cond
          ((char= ch #\})
           (lookahead-read-chr lookahead)
           (return table))
          ((char= ch #\,)
           (lookahead-read-chr lookahead))
          (t
           (let ((key
                   (parse-flow-scalar-lookahead
                     lookahead)))
             (when (eq key +eof+)
               (error 'extraction-error
                      :expected "mapping key"
                      :got +eof+))
             (skip-flow-separator lookahead)
             (let ((ch2
                     (lookahead-peek-chr
                       lookahead 0)))
               (unless (and (characterp ch2)
                            (char= ch2 #\:))
                 (error 'extraction-error
                        :expected
                        "colon after key"
                        :got ch2))
               (lookahead-read-chr lookahead)
               (skip-flow-separator lookahead)
               (let ((ch3
                       (lookahead-peek-chr
                         lookahead 0))
                     (ks
                       (scalar-to-key-string key)))
                 (cond
                   ((char= ch3 #\[)
                    (setf (gethash ks table)
                          (parse-flow-sequence
                            lookahead)))
                   ((char= ch3 #\{)
                    (setf (gethash ks table)
                          (parse-flow-mapping
                            lookahead)))
                   (t
                    (setf (gethash ks table)
                          (parse-flow-scalar-lookahead
                            lookahead))))))
             (skip-flow-separator lookahead)
             (let ((ch4
                     (lookahead-peek-chr
                       lookahead 0)))
               (cond
                 ((char= ch4 #\})
                  (lookahead-read-chr lookahead)
                  (return table))
                 ((char= ch4 #\,)
                  (lookahead-read-chr lookahead))
                 (t
                  (error 'extraction-error
                         :expected
                         "comma or closing brace"
                         :got ch4)))))))))))

(defun parse-literal-block-scalar (lookahead)
  "Parse a YAML literal block scalar from LOOKAHEAD.
The pipe character has NOT been consumed yet.
Reads the pipe, then subsequent indented lines, strips
common indentation, and returns the content as a string."
  (lookahead-read-chr lookahead) ;; consume |
  ;; Skip rest of line (block header / trailing content)
  (loop for ch = (lookahead-peek-chr lookahead 0)
        while (and (characterp ch)
                   (not (char= ch #\Newline))
                   (not (char= ch #\Return))
                   (not (eq ch +eof+)))
        do (lookahead-read-chr lookahead))
  ;; Consume newline after |
  (let ((ch (lookahead-peek-chr lookahead 0)))
    (when (and (characterp ch)
               (or (char= ch #\Newline)
                   (char= ch #\Return)))
      (lookahead-read-chr lookahead)
      (when (and (char= ch #\Return)
                 (let ((n (lookahead-peek-chr
                            lookahead 0)))
                   (and (characterp n)
                        (char= n #\Newline))))
        (lookahead-read-chr lookahead))))
  ;; Collect all raw lines until end of scalar.
  ;; Use offset-based peeking to count indentation
  ;; without consuming characters.
  (let ((raw-lines nil)
        (block-indent nil))
    (loop
      ;; Count indentation via offset peeking
      (let ((indent 0))
        (loop for offset from 0
              while (and (< offset 16)
                         (let ((ch
                                 (lookahead-peek-chr
                                   lookahead offset)))
                           (and (characterp ch)
                                (char= ch #\Space))))
              do (incf indent))
        (let ((ch (lookahead-peek-chr
                    lookahead indent)))
          (cond
            ;; End of input
            ((eq ch +eof+)
             (return))
            ;; Empty line (just newline)
            ((and (characterp ch)
                  (or (char= ch #\Newline)
                      (char= ch #\Return)))
             ;; If block-indent is known, this is an
             ;; empty content line. Preserve it.
             (when block-indent
               (push "" raw-lines))
             ;; If block-indent NOT known, skip this
             ;; blank line (it's before any content).
             ;; Consume the newline.
             (lookahead-read-chr lookahead)
             (when (and (characterp ch)
                        (char= ch #\Return)
                        (let ((n (lookahead-peek-chr
                                   lookahead 0)))
                          (and (characterp n)
                               (char= n #\Newline))))
               (lookahead-read-chr lookahead)))
            ;; Non-empty content line
            (t
             (when (null block-indent)
               ;; First content line determines
               ;; block-indent
               (setf block-indent indent))
             (when (< indent block-indent)
               ;; Less indented than block - end scalar
               (return))
             ;; Skip exactly block-indent spaces
             (loop repeat block-indent
                   do (lookahead-read-chr lookahead))
             ;; Collect rest of line content
             (let ((chars nil))
               (loop for ch2 =
                       (lookahead-peek-chr
                         lookahead 0)
                     while (and (characterp ch2)
                                (not (char=
                                        ch2
                                        #\Newline))
                                (not (char=
                                        ch2
                                        #\Return))
                                (not (eq ch2
                                         +eof+)))
                     do (lookahead-read-chr
                          lookahead)
                        (push ch2 chars))
               (push (coerce (reverse chars)
                             'string)
                     raw-lines))
             ;; Consume newline at end of line
             (let ((ch2 (lookahead-peek-chr
                           lookahead 0)))
               (cond
                 ((eq ch2 +eof+) (return))
                 ((or (char= ch2 #\Newline)
                      (char= ch2 #\Return))
                  (lookahead-read-chr lookahead)
                  (when (and (char= ch2 #\Return)
                             (let ((n
                                     (lookahead-peek-chr
                                       lookahead
                                       0)))
                               (and (characterp n)
                                    (char= n
                                           #\Newline))))
                    (lookahead-read-chr lookahead)))
                 (t (return)))))))))
    ;; If block-indent was never found, scalar is empty
    (unless block-indent
      (return-from parse-literal-block-scalar ""))
    (format nil "~{~A~^~%~}"
            (reverse raw-lines))))
