#!/usr/bin/env sbcl --script

(defpackage :test-categorizer
  (:use :cl))

(in-package :test-categorizer)

(defparameter *test-dir* "tests/fixtures/yaml-test-suite/")
(defparameter *categories* '())

(defun read-test-description (test-id)
  (let ((desc-file (format nil "~a~a/===" *test-dir* test-id)))
    (when (probe-file desc-file)
      (with-open-file (stream desc-file)
        (read-line stream nil "")))))

(defun categorize-description (desc)
  (cond
    ((search "comment" desc :test #'char-equal) '(:comment))
    ((search "whitespace" desc :test #'char-equal) '(:whitespace))
    ((search "null" desc :test #'char-equal) '(:null))
    ((search "bool" desc :test #'char-equal) '(:boolean))
    ((search "int" desc :test #'char-equal) '(:integer))
    ((search "float" desc :test #'char-equal) '(:float))
    ((search "str" desc :test #'char-equal) '(:string))
    ((search "seq" desc :test #'char-equal) '(:sequence))
    ((search "map" desc :test #'char-equal) '(:mapping))
    ((search "anchor" desc :test #'char-equal) '(:anchor))
    ((search "alias" desc :test #'char-equal) '(:alias))
    ((search "tag" desc :test #'char-equal) '(:tag))
    ((search "directive" desc :test #'char-equal) '(:directive))
    ((search "escape" desc :test #'char-equal) '(:escape))
    ((search "indent" desc :test #'char-equal) '(:indentation))
    (t '(:other))))

(defun analyze-tests ()
  (let ((test-ids (directory (format nil "~a*" *test-dir*)))
        (category-map (make-hash-table :test 'equal)))
    
    (format t "Analyzing ~d tests~%" (length test-ids))
    
    (dolist (test-path test-ids)
      (let* ((test-id (car (last (pathname-directory test-path))))
             (desc (read-test-description test-id))
             (categories (categorize-description desc)))
        
        (dolist (cat categories)
          (push test-id (gethash cat category-map '())))))
    
    (format t "~%=== CATEGORY REPORT ===~%")
    (loop for cat in '(:comment :whitespace :null :boolean :integer :float 
                       :string :sequence :mapping :anchor :alias :tag 
                       :directive :escape :indentation :other)
          for tests = (gethash cat category-map)
          do (format t "~a: ~d tests~%" cat (length tests)))
    
    category-map))

;; Run analysis
(analyze-tests)