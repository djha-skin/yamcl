;;;; src/blocks.lisp
;;;; yamcl - YAML block collections parsing

(defpackage #:com.djhaskin.yamcl/blocks
  (:use #:cl #:com.djhaskin.yamcl/utils)
  (:import-from #:com.djhaskin.yamcl/scalars
                #:parse-scalar-lookahead
                #:skip-whitespace-and-comments-lookahead)
  (:export
   #:parse-mapping-from-key
   #:parse-block-value
   #:parse-block-sequence
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
      (t
       (parse-scalar-lookahead lookahead)))))

(defun try-parse-next-pair (lookahead table indent)
  "Try to parse another key-value pair at the given INDENT level.
Skips whitespace/comments first. If the next content is at a
different indent level, returns NIL without consuming anything.
If at the same indent, parses a key-value pair and adds to TABLE."
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
      (when (or (not (characterp ch)) (char/= ch #\:))
        (return-from try-parse-next-pair nil))
      (unless (colon-mapping-separator-p lookahead)
        (return-from try-parse-next-pair nil))
      (lookahead-read-chr lookahead)
      (let* ((key-str (scalar-to-key-string key))
             (value (parse-value-after-colon lookahead)))
        (setf (gethash key-str table) value)
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
            (skip-whitespace-and-comments-lookahead lookahead)
            (let ((next-ch
                    (lookahead-peek-chr lookahead 0))
                  (next-col
                    (current-column lookahead)))
              (if (and (characterp next-ch)
                       (> next-col indent))
                  (let ((nested
                          (parse-block-value
                            lookahead next-col)))
                    (setf (gethash key-str table) nested)
                    (loop while
                      (try-parse-next-pair
                        lookahead table indent))
                    table)
                  (progn
                    (setf (gethash key-str table) +null+)
                    table))))
          (progn
            (setf (gethash key-str table) value)
            (loop while
              (try-parse-next-pair
                lookahead table indent))
            table)))))

(defun parse-block-value (lookahead &optional (indent 0))
  "Parse a YAML block-style value from LOOKAHEAD at INDENT
level. Uses scalar-first approach: read a scalar, check for
colon. If colon follows, it is a mapping key -- delegate to
parse-mapping-from-key. If not, return the scalar as-is."
  (let ((scalar (parse-scalar-lookahead lookahead)))
    (if (eq scalar +eof+)
        +eof+
        (or (parse-mapping-from-key lookahead scalar indent)
            scalar))))

(defun parse-block-sequence (lookahead indent item-parser)
  "Parse a block sequence from LOOKAHEAD at INDENT level.
ITEM-POP is a function (LOOKAHEAD INDENT) that parses
a single sequence item.
Returns a list of parsed items."
  (let ((items nil))
    (loop
      ;; Consume the dash and space
      (lookahead-read-chr lookahead)
      (lookahead-read-chr lookahead)
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
      ;; Check for dash-space
      (let ((ch (lookahead-peek-chr lookahead 0))
            (ch1 (lookahead-peek-chr lookahead 1)))
        (unless (and (characterp ch)
                     (char= ch #\-)
                     (characterp ch1)
                     (char= ch1 #\Space))
          (return))))
    (reverse items)))
