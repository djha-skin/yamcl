;;;; src/blocks.lisp
;;;; yamcl - YAML block collections parsing

(defpackage #:com.djhaskin.yamcl/blocks
  (:use #:cl #:com.djhaskin.yamcl/utils)
  (:import-from #:com.djhaskin.yamcl/scalars
                #:parse-scalar-lookahead)
  (:export
   #:parse-block-value
   #:parse-block-mapping
   #:parse-block-sequence
   #:parse-block
   #:parse-simple-mapping))

(in-package #:com.djhaskin.yamcl/blocks)

;;; US-015-C: Parse colon token as separator
;;; US-015-D: Parse key-value pair with scalars

(defun parse-simple-mapping (lookahead)
  "Parse a simple key: value mapping from LOOKAHEAD stream.
Returns (key . value) cons cell or NIL if not a mapping.
This parses single-line mappings like 'key: value'."
  ;; Skip whitespace
  (loop while (let ((ch (lookahead-peek-chr lookahead 0)))
                (and (characterp ch)
                     (member ch '(#\Space #\Tab #\Newline #\Return))))
        do (lookahead-read-chr lookahead))
  
  ;; Check if first character could start a key
  (let ((first-ch (lookahead-peek-chr lookahead 0)))
    (when (or (eq first-ch +eof+)
              (not (or (alpha-char-p first-ch)
                       (member first-ch '(#\" #\' #\~ #\-) :test #'char=))))
      (return-from parse-simple-mapping nil))
    
    ;; Parse key by delegating to scalar parser
    ;; For now, use a simple implementation
    (let ((key-chars '()))
      (loop for ch = (lookahead-peek-chr lookahead 0)
            while (and (characterp ch)
                       (not (or (char= ch #\:)
                                (member ch '(#\Space #\Tab #\Newline #\Return)))))
            do (push (lookahead-read-chr lookahead) key-chars))
      
      (let ((key (coerce (reverse key-chars) 'string)))
        
        ;; Skip whitespace before colon
        (loop while (let ((ch (lookahead-peek-chr lookahead 0)))
                      (and (characterp ch)
                           (member ch '(#\Space #\Tab))))
              do (lookahead-read-chr lookahead))
        
        ;; Expect colon
        (let ((colon (lookahead-read-chr lookahead)))
          (unless (and (characterp colon) (char= colon #\:))
            (return-from parse-simple-mapping nil)))
        
        ;; Skip whitespace after colon
        (loop while (let ((ch (lookahead-peek-chr lookahead 0)))
                      (and (characterp ch)
                           (member ch '(#\Space #\Tab))))
              do (lookahead-read-chr lookahead))
        
        ;; Parse value using scalar parser (US-015-D)
        (let ((value (parse-scalar-lookahead lookahead)))
          (cons key value))))))


;;; Function stubs for block parsing

(defun parse-block-value (lookahead)
  "Parse a YAML block-style value from LOOKAHEAD stream.
This could be a mapping, sequence, or scalar (delegated to scalars).
Returns the parsed value."
  (error "Not implemented yet: parse-block-value"))

(defun parse-block-mapping (lookahead)
  "Parse a YAML block mapping from LOOKAHEAD stream.
Returns a hash table."
  (error "Not implemented yet: parse-block-mapping"))

(defun parse-block-sequence (lookahead)
  "Parse a YAML block sequence from LOOKAHEAD stream.
Returns a list."
  (error "Not implemented yet: parse-block-sequence"))

(defun parse-block (lookahead)
  "Parse a YAML block from LOOKAHEAD stream.
This is the main entry point for block parsing."
  (parse-block-value lookahead))