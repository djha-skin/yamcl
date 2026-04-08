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
    extraction-error
    make-char-queue
    char-queue-peek
    char-queue-pop))

(in-package #:com.djhaskin.yamcl)

(defconstant +eof+ :eof
  "End-of-file marker, used throughout the parser.")

(declaim (ftype function peek-chr read-chr))

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
  '(or stream string list char-queue))

(deftype streamed ()
  '(or character (member :eof) null))

(defstruct char-queue
  (chars nil :type list))

(defun char-queue-peek (q)
  "Peek at the front of the queue."
  (declare (type char-queue q))
  (if (null (char-queue-chars q))
    +eof+
    (car (char-queue-chars q))))

(defun char-queue-pop (q)
  "Pop the front character from the queue."
  (declare (type char-queue q))
  (if (null (char-queue-chars q))
    +eof+
    (pop (char-queue-chars q))))

(defun ensure-char-queue (strm)
  "Ensure STRM is a char-queue for consistent mutation."
  (declare (type streamable strm))
  (cond
    ((char-queue-p strm) strm)
    ((stringp strm)
     (make-char-queue :chars (coerce strm 'list)))
    ((listp strm) strm)
    (t strm)))

(declaim (inline peek-chr read-chr))

(defun peek-chr (strm)
  "Peek at the next character without consuming it."
  (declare (type streamable strm))
  (cond
    ((stringp strm)
     (if (= (length strm) 0)
       +eof+
       (char strm 0)))
    ((listp strm)
     (if (null strm)
       +eof+
       (car strm)))
    ((char-queue-p strm)
     (char-queue-peek strm))
    (t
     (peek-char nil strm nil +eof+ nil))))

(defun read-chr (strm)
  "Read and consume the next character."
  (declare (type streamable strm))
  (cond
    ((stringp strm)
     (prog1
       (peek-chr strm)
       (setf strm (if (> (length strm) 0)
                      (subseq strm 1)
                      ""))))
    ((listp strm)
     (if (null strm)
       +eof+
       (pop strm)))
    ((char-queue-p strm)
     (char-queue-pop strm))
    (t
     (read-char strm nil +eof+ nil))))

(defun build-string (lst)
  "Build a string from a list of characters."
  (declare (type list lst))
  (let* ((size (length lst))
         (building (make-string size)))
    (loop for l in lst
          for j from 0 below size
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
  (cond
    ((null chr) nil)
    ((eq chr +eof+) nil)
    (t
     (or (char= chr #\Newline)
         (char= chr #\Return)
         (char= chr #\Page)
         (blankspace-p chr)))))

(defun extract-comment (strm)
  "Extract a comment from STRM. Comments start with # and
continue to the end of the line."
  (declare (type streamable strm))
  (loop with last-read = (read-chr strm)
        while (not (eq last-read +eof+))
        do (cond
             ((char= last-read #\Newline)
              (return last-read))
             ((char= last-read #\Return)
              (let ((next (peek-chr strm)))
                (when (char= next #\Newline)
                  (read-chr strm))
                (return #\Newline)))
             (t
              (setf last-read (read-chr strm))))
        finally (return +eof+)))

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

(defun extract-while (strm pred)
  "Extract characters while PRED is true, returning a list of chars.
The first character that doesn't satisfy PRED is left in the stream."
  (declare (type streamable strm)
           (type (function (character) *) pred))
  (loop with chars = nil
        for chr = (peek-chr strm)
        while (and (not (eq chr +eof+))
                   (funcall pred chr))
        do (push (read-chr strm) chars)
        finally (return (nreverse chars))))

(defun extract-word (strm)
  "Extract a word (alphanumeric sequence) from the stream."
  (declare (type streamable strm))
  (build-string
    (extract-while strm (lambda (c)
                          (or (alpha-char-p c)
                              (digit-char-p c))))))

(defun parse-boolean (strm)
  "Parse a boolean value from STRM."
  (declare (type streamable strm))
  (let ((word (extract-word strm)))
    (cond
      ((string= word "true") t)
      ((string= word "false") nil)
      (t
       (error 'extraction-error
              :expected "boolean (true or false)"
              :got word)))))

(defun parse-null (strm)
  "Parse a null value from STRM. Returns NIL."
  (declare (type streamable strm))
  (let ((c (peek-chr strm)))
    (cond
      ((char= c #\~)
       (read-chr strm)
       nil)
      (t
       (let ((word (extract-word strm)))
         (if (string= word "null")
           nil
           (error 'extraction-error
                  :expected "null (null or ~)"
                  :got word)))))))

(defun parse-number (strm)
  "Parse a number (integer or float) from STRM."
  (declare (type streamable strm))
  (let ((chars nil))
    ;; Optional sign
    (let ((c (peek-chr strm)))
      (when (and (characterp c)
                 (or (char= c #\+) (char= c #\-)))
        (push (read-chr strm) chars)))
    ;; Parse digits - push each one
    (loop for c = (peek-chr strm)
          while (and (characterp c) (digit-char-p c))
          do (push (read-chr strm) chars))
    (when (null chars)
      (error 'extraction-error
             :expected "digit"
             :got (peek-chr strm)))
    ;; Check for decimal point
    (let ((c (peek-chr strm)))
      (when (and (characterp c) (char= c #\.))
        (push (read-chr strm) chars)
        ;; Parse fractional digits
        (loop for c = (peek-chr strm)
              while (and (characterp c) (digit-char-p c))
              do (push (read-chr strm) chars))
        (setf c (peek-chr strm)))
      ;; Check for exponent
      (when (and (characterp c)
                 (or (char= c #\e) (char= c #\E)))
        (push (read-chr strm) chars)
        (let ((s (peek-chr strm)))
          (when (and (characterp s)
                     (or (char= s #\+) (char= s #\-)))
            (push (read-chr strm) chars)))
        (loop for c = (peek-chr strm)
              while (and (characterp c) (digit-char-p c))
              do (push (read-chr strm) chars))))
    ;; Build string and convert to number
    (let ((str (build-string (nreverse chars))))
      (if (or (position #\. str)
              (position #\e str)
              (position #\E str))
        (read-from-string str)
        (parse-integer str)))))

(defun parse-string (strm)
  "Parse a double-quoted string from STRM."
  (declare (type streamable strm))
  (read-chr strm)
  (loop with chars = nil
        for c = (peek-chr strm)
        until (or (eq c +eof+) (char= c #\"))
        do (cond
             ((char= c #\\)
              (read-chr strm)
              (let ((e (read-chr strm)))
                (push (cond
                        ((char= e #\n) #\Newline)
                        ((char= e #\t) #\Tab)
                        ((char= e #\r) #\Return)
                        ((char= e #\\) #\\)
                        ((char= e #\") #\")
                        (t e))
                      chars)))
             (t
              (push (read-chr strm) chars)))
        finally (progn
                  (when (eq c +eof+)
                    (error 'extraction-error
                           :expected "closing quote"
                           :got +eof+))
                  (read-chr strm)
                  (return (build-string (nreverse chars))))))

(defun parse-scalar (strm)
  "Parse a scalar value from STRM."
  (declare (type streamable strm))
  (let ((c (skip-whitespace-and-comments strm)))
    (when (eq c +eof+)
      (return-from parse-scalar nil))
    (cond
      ((char= c #\t) (parse-boolean strm))
      ((char= c #\f) (parse-boolean strm))
      ((char= c #\n) (parse-null strm))
      ((char= c #\~)
       (read-chr strm)
       nil)
      ((or (char= c #\+) (char= c #\-) (digit-char-p c))
       (parse-number strm))
      ((char= c #\")
       (parse-string strm))
      (t
       (error 'extraction-error
              :expected "scalar value"
              :got c)))))

(defun parse-from (strm)
  "Parse a YAML document from STRM."
  (declare (type streamable strm))
  (let* ((queue (cond
                  ((char-queue-p strm) strm)
                  ((stringp strm)
                   (make-char-queue :chars (coerce strm 'list)))
                  ((listp strm)
                   (make-char-queue :chars strm))
                  (t strm))))
    (parse-scalar queue)))

(defun generate-to (strm val &key (pretty-indent 0) json-mode)
  "Generate YAML output to STRM from VAL."
  (declare (type streamable strm)
           (type (or null (integer 0 64)) pretty-indent)
           (type boolean json-mode))
  (let ((out (make-string-output-stream)))
    (format out "# YAML generation not yet implemented~%")
    out))
