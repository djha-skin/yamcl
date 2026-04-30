;;;; Copyright (c) 2026 by Daniel J. Haskin. All rights reserved.
;;;; Use and distribution are subject to the license terms in the LICENSE file
;;;; that is part of this source code distribution.
;;;;
;;;; src/utils.lisp - utility functions for parsing YAML

(defpackage #:com.djhaskin.yamcl/utils
  (:use :cl)
  (:export
    #:+eof+
    #:+null+
    #:streamable
    #:streamed
    #:extraction-error
    #:extraction-error-format
    #:extraction-error-args
    #:must-read-chr
    #:peek-chr
    #:read-chr
    #:number-start-p
    #:number-char-p
    #:list-string))

(in-package #:com.djhaskin.yamcl/utils)

(defconstant +eof+ :eof)
(defconstant +null+ :null)

(deftype streamable ()
  '(or boolean stream))

(deftype streamed ()
  `(or character (member ,+eof+)))

(defun nameof (c)
  (cond
    ((eq c +eof+)
     "EOF")
    ((typep c 'character)
     (format nil "~:C" c))
    (t
     (format nil "~A" c))))

(define-condition extraction-error (error)
  ((expected :initarg :expected :reader expected)
   (got :initarg :got :reader got))
  (:report
   (lambda (c s)
     (let* ((gotc (got c))
            (gotc-title (nameof gotc))
            (expected (expected c)))
       (format s
             "Expected ~v[nothing~;~:;one of ~]~{`~A`~^~#[~; or ~:;, ~]~}; got `~A`"
             (length expected)
             (mapcar #'nameof expected)
             gotc-title)))))

(defun peek-chr (strm)
  (declare (type streamable strm))
  (peek-char nil strm nil +eof+ nil))

(defun read-chr (strm)
  (declare (type streamable strm))
  (read-char strm nil +eof+ nil))

(defun must-read-chr (strm)
  (declare (type streamable strm))
  (read-char strm))

(defun number-start-p (chr)
  (declare (type character chr))
  (or
    (char= chr #\-)
    (char= chr #\.)
    (digit-char-p chr)))

(defun number-char-p (chr)
  (declare (type character chr))
  (or
    (number-start-p chr)
    (char= chr #\+)
    (char= chr #\E)
    (char= chr #\e)
    (char= chr #\I)
    (char= chr #\i)
    (char= chr #\N)
    (char= chr #\n)
    (char= chr #\F)
    (char= chr #\f)))

(defun list-string (lst)
  (declare (type list lst))
  (let* ((size (length lst))
         (building (make-string size)))
    (loop for l in lst
          for j from (- size 1) downto 0
          do
          (setf (elt building j) l))
    building))
