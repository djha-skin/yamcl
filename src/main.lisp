;;;; main.lisp -- Reference Implementation Parser for YAML in Common Lisp
;;;;
;;;; SPDX-FileCopyrightText: 2024 Daniel Jay Haskin
;;;; SPDX-License-Identifier: MIT

(in-package #:cl-user)

(defpackage #:com.djhaskin.yamcl (:use #:cl)
  (:documentation "YAML Ain't Markup Language -- Common Lisp.")
  (:import-from #:alexandria)
  (:export
    parse-from parse-from-string
    generate-to generate-to-string
    +eof+ +null+ extraction-error
    make-char-queue char-queue-peek char-queue-pop))

(in-package #:com.djhaskin.yamcl)

(defconstant +eof+ :eof)

(defconstant +null+ '+null+
  "Sentinel value representing YAML null.")

(define-condition extraction-error (error)
  ((expected :initarg :expected :reader expected)
   (got :initarg :got :reader got))
  (:report (lambda (c s)
             (format s "Expected ~A; got ~A"
                     (expected c) (got c)))))

(deftype streamable () '(or stream string list char-queue))
(deftype streamed () '(or character (member :eof) null))

(defstruct char-queue (chars nil :type list))

(defun char-queue-peek (q)
  (if (null (char-queue-chars q)) +eof+
      (car (char-queue-chars q))))

(defun char-queue-pop (q)
  (if (null (char-queue-chars q)) +eof+
      (pop (char-queue-chars q))))

(declaim (inline peek-chr read-chr))

(defun peek-chr (strm)
  (cond
    ((stringp strm)
     (if (= (length strm) 0) +eof+ (char strm 0)))
    ((listp strm)
     (if (null strm) +eof+ (car strm)))
    ((char-queue-p strm) (char-queue-peek strm))
    (t (peek-char nil strm nil +eof+ nil))))

(defun read-chr (strm)
  (cond
    ((stringp strm)
     (prog1 (peek-chr strm)
            (setf strm (if (> (length strm) 0)
                           (subseq strm 1) ""))))
    ((listp strm)
     (if (null strm) +eof+ (pop strm)))
    ((char-queue-p strm) (char-queue-pop strm))
    (t (read-char strm nil +eof+ nil))))

(defun build-string (lst)
  (let* ((size (length lst))
         (building (make-string size)))
    (loop for l in lst
          for j from 0 below size
          do (setf (elt building j) l))
    building))

(defun blankspace-p (chr)
  (or (char= chr #\Tab) (char= chr #\Space)))

(defun whitespace-p (chr)
  (cond
    ((null chr) nil)
    ((eq chr +eof+) nil)
    (t (or (char= chr #\Newline) (char= chr #\Return)
           (char= chr #\Page) (blankspace-p chr)))))

(defun extract-comment (strm)
  (loop with last-read = (read-chr strm)
        while (not (eq last-read +eof+))
        do (cond
             ((char= last-read #\Newline) (return last-read))
             ((char= last-read #\Return)
              (let ((next (peek-chr strm)))
                (when (char= next #\Newline) (read-chr strm))
                (return #\Newline)))
             (t (setf last-read (read-chr strm))))
        finally (return +eof+)))

(defun skip-whitespace-and-comments (strm)
  (loop with next = (peek-chr strm)
        while (and (not (eq next +eof+))
                   (or (whitespace-p next) (char= next #\#)))
        do (cond
             ((char= next #\#) (extract-comment strm))
             (t (read-chr strm)))
           (setf next (peek-chr strm))
        finally (return next)))

(defun extract-while (strm pred)
  (loop with chars = nil
        for chr = (peek-chr strm)
        while (and (not (eq chr +eof+)) (funcall pred chr))
        do (push (read-chr strm) chars)
        finally (return (nreverse chars))))

(defun extract-word (strm)
  (build-string
    (extract-while strm (lambda (c)
                          (or (alpha-char-p c) (digit-char-p c))))))

(defun parse-boolean (strm)
  (let ((word (extract-word strm)))
    (cond
      ((string= word "true") t)
      ((string= word "false") nil)
      (t (error 'extraction-error
                :expected "boolean (true or false)" :got word)))))

(defun parse-null (strm)
  (let ((c (peek-chr strm)))
    (cond
      ((char= c #\~) (read-chr strm) +null+)
      (t (let ((word (extract-word strm)))
           (if (string= word "null") +null+
               (error 'extraction-error
                       :expected "null (null or ~)" :got word)))))))

(defun parse-number (strm)
  (let ((chars nil) (c (peek-chr strm)))
    (when (and (characterp c) (or (char= c #\+) (char= c #\-)))
      (push (read-chr strm) chars)
      (setf c (peek-chr strm)))
    (loop while (and (characterp c) (digit-char-p c))
          do (push (read-chr strm) chars)
             (setf c (peek-chr strm)))
    (when (null chars)
      (error 'extraction-error :expected "digit" :got c))
    (when (and (characterp c) (char= c #\.))
      (push (read-chr strm) chars)
      (setf c (peek-chr strm))
      (loop while (and (characterp c) (digit-char-p c))
            do (push (read-chr strm) chars)
               (setf c (peek-chr strm))))
    (when (and (characterp c) (or (char= c #\e) (char= c #\E)))
      (push (read-chr strm) chars)
      (setf c (peek-chr strm))
      (when (and (characterp c) (or (char= c #\+) (char= c #\-)))
        (push (read-chr strm) chars)
        (setf c (peek-chr strm)))
      (loop while (and (characterp c) (digit-char-p c))
            do (push (read-chr strm) chars)
               (setf c (peek-chr strm))))
    (let ((str (build-string (nreverse chars))))
      (if (or (position #\. str) (position #\e str) (position #\E str))
          (read-from-string str) (parse-integer str)))))

(defun parse-string (strm)
  (read-chr strm)
  (loop with chars = nil
        for c = (peek-chr strm)
        until (or (eq c +eof+) (char= c #\"))
        do (cond
             ((char= c #\\)
              (read-chr strm)
              (let ((e (read-chr strm)))
                (push (cond
                        ((char= e #\") #\")
                        ((char= e #\\) #\\)
                        ((char= e #\/) #\/)
                        ((char= e #\b) (code-char 8))
                        ((char= e #\f) (code-char 12))
                        ((char= e #\n) #\Newline)
                        ((char= e #\r) #\Return)
                        ((char= e #\t) #\Tab)
                        ((char= e #\u)
                         (let* ((d1 (read-chr strm))
                                (d2 (read-chr strm))
                                (d3 (read-chr strm))
                                (d4 (read-chr strm))
                                (hex (coerce (list d1 d2 d3 d4) 'string)))
                           (code-char (parse-integer hex :radix 16))))
                        (t (error 'extraction-error
                                   :expected "valid escape" :got e)))
                      chars)))
             (t (push (read-chr strm) chars)))
        finally (when (eq c +eof+)
                  (error 'extraction-error
                          :expected "closing quote" :got +eof+))
                (read-chr strm)
                (return (build-string (nreverse chars)))))

(defun parse-scalar (strm)
  (let ((c (skip-whitespace-and-comments strm)))
    (when (eq c +eof+) (return-from parse-scalar nil))
    (cond
      ((char= c #\t) (parse-boolean strm))
      ((char= c #\f) (parse-boolean strm))
      ((char= c #\n) (parse-null strm))
      ((char= c #\~) (read-chr strm) 'cl:null)
      ((or (char= c #\+) (char= c #\-) (digit-char-p c))
       (parse-number strm))
      ((char= c #\") (parse-string strm))
      (t (error 'extraction-error
                :expected "scalar value" :got c)))))

(defun parse-from (strm)
  (declare (type stream strm))
  (let ((c (skip-whitespace-and-comments strm)))
    (when (eq c +eof+) (return-from parse-from nil))
    (parse-scalar strm)))

(defun parse-from-string (str)
  (declare (type string str))
  (with-input-from-string (strm str) (parse-from strm)))

(defun generate-to (strm val &key (pretty-indent 0) json-mode)
  (declare (type stream strm)
           (type (or null (integer 0 64)) pretty-indent)
           (type boolean json-mode))
  (typecase val
    ((eql nil) (write-string "false" strm))
    ((eql +null+) (write-string "null" strm))
    ((eql t) (write-string "true" strm))
    (number (prin1 val strm))
    (string (progn (write-char #\" strm)
                   (write-string val strm)
                   (write-char #\" strm)))
    (t (error 'extraction-error
              :expected "YAML value" :got val)))
  val)

(defun generate-to-string (val &key (pretty-indent 0) json-mode)
  (declare (type (or null (integer 0 64)) pretty-indent)
           (type boolean json-mode))
  (with-output-to-string (strm)
    (generate-to strm val
                 :pretty-indent pretty-indent
                 :json-mode json-mode)))
