;;;; Copyright (c) 2026 by Daniel J. Haskin.
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
    #:must-read-chr
    #:peek-chr
    #:read-chr
    #:number-start-p
    #:number-char-p
    #:list-string
    #:yaml-number-to-cl
    #:lookahead-stream
    #:new-lookahead-stream
    #:unread-all
    #:lookahead-read-chr
    #:lookahead-peek-chr))

(in-package #:com.djhaskin.yamcl/utils)

(defconstant +eof+ :eof)
(defconstant +null+ 'cl:null)

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
       (if (listp expected)
           (format s
                   "Expected ~v[nothing~;~:;one of ~]~{`~A`~^~#[~; or ~:;, ~]~}; got `~A`"
                   (length expected)
                   (mapcar #'nameof expected)
                   gotc-title)
           (format s "Expected `~A`; got `~A`" expected gotc-title))))))

(defun peek-chr (strm)
  (declare (type streamable strm))
  (peek-char nil strm nil +eof+ nil))

(defun read-chr (strm)
  (declare (type streamable strm))
  (read-char strm nil +eof+ nil))

(defun must-read-chr (strm)
  (declare (type streamable strm))
  (read-char strm))

(defstruct lookahead-stream
  (strm nil :type streamable)
  (buffer-start 0 :type integer)
  (buffer nil :type array))

(defun new-lookahead-stream (strm &key buffer-size)
  (declare (type streamable strm))
  (let ((initial-buffer (make-array buffer-size :initial-element +eof+)))
    (loop for i from 0 below buffer-size
          for chr = (read-chr strm)
          do
          (setf (elt initial-buffer i) chr))
    (make-lookahead-stream :strm strm :buffer initial-buffer
                           :buffer-start 0)))

(defun unread-all (lookahead)
  (declare (type lookahead-stream lookahead))
  (let ((buffer (lookahead-stream-buffer lookahead)))
    (loop for i from (1- (length buffer)) downto 0
          for chr = (elt buffer i)
          when (characterp chr)
          do
          (unread-char chr (lookahead-stream-strm lookahead))
          (setf (elt buffer i) +eof+))
    (setf (lookahead-stream-buffer-start lookahead) 0)))

(defun lookahead-read-chr (lookahead)
  (declare (type lookahead-stream lookahead))
  (let ((buffer (lookahead-stream-buffer lookahead)))
    (let* ((current-index (lookahead-stream-buffer-start lookahead))
           (chr (elt buffer current-index))
           (next-index (mod (1+ current-index) (length buffer))))
      ;; Read new character into the slot we just consumed
      (setf (elt buffer current-index) (read-chr (lookahead-stream-strm lookahead)))
      ;; Advance buffer start
      (setf (lookahead-stream-buffer-start lookahead) next-index)
      chr)))

(defun lookahead-peek-chr (lookahead n)
    (declare (type lookahead-stream lookahead))
    (let ((buffer (lookahead-stream-buffer lookahead)))
      (when (>= n (length buffer))
        (error "Lookahead buffer overflow: requested ~A characters, but buffer size is ~A" n (length buffer)))
      (let* ((index (mod (+ (lookahead-stream-buffer-start lookahead) n)
                      (length buffer)))
             (chr (elt buffer index)))
        chr)))

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

(defun yaml-number-to-cl (yaml-str)
  "Convert YAML number string to Common Lisp readable number string.
Handles:
  - Base indicators: 0o52 (octal), 0x2A (hex), 0b101010 (binary)
  - Underscores: 1_000_000 → 1000000
  - Special floats: .inf, -.inf, .nan"
  ;; Remove underscores first
  (let ((clean (remove #\_ yaml-str)))
    (cond
      ;; Special float values
      ((string= clean ".inf") "1.0e1000") ; Positive infinity
      ((string= clean "-.inf") "-1.0e1000") ; Negative infinity  
      ((string= clean ".nan") "0.0d+NaN") ; NaN
      ;; Check for base indicators
      ((and (> (length clean) 2)
            (char= (char clean 0) #\0))
       (let ((indicator (char-downcase (char clean 1))))
         (case indicator
           (#\o (format nil "#o~A" (subseq clean 2))) ; Octal
           (#\x (format nil "#x~A" (subseq clean 2))) ; Hexadecimal
           (#\b (format nil "#b~A" (subseq clean 2))) ; Binary
           (t clean)))) ; Decimal with leading zero
      (t clean))))
