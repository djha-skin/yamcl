#!/usr/bin/env sbcl --script

(defpackage :test-analyzer
  (:use :cl))

(in-package :test-analyzer)

(defparameter *test-dir* #p"tests/fixtures/yaml-test-suite/")

(defun read-test-description (test-path)
  "Read the test description from === file."
  (let ((desc-file (merge-pathnames "===" test-path)))
    (when (probe-file desc-file)
      (with-open-file (stream desc-file)
        (read-line stream nil "")))))

(defun categorize-test (description)
  "Categorize test based on description."
  (cond
    ((search "comment" description :test #'char-equal) :comments)
    ((search "whitespace" description :test #'char-equal) :whitespace)
    ((search "null" description :test #'char-equal) :null)
    ((search "bool" description :test #'char-equal) :boolean)
    ((search "integer" description :test #'char-equal) :integer)
    ((search "float" description :test #'char-equal) :float)
    ((search "string" description :test #'char-equal) :strings)
    ((search "sequence" description :test #'char-equal) :sequences)
    ((search "mapping" description :test #'char-equal) :mappings)
    ((search "anchor" description :test #'char-equal) :anchors)
    ((search "alias" description :test #'char-equal) :aliases)
    ((search "tag" description :test #'char-equal) :tags)
    ((search "directive" description :test #'char-equal) :directives)
    ((search "escape" description :test #'char-equal) :escapes)
    (t :other)))

(defun analyze-test-suite ()
  "Analyze the YAML test suite and categorize tests."
  (let ((categories (make-hash-table :test 'equal))
        (test-count 0))
    
    (flet ((add-to-category (category test-id)
             (push test-id (gethash category categories))))
      
      (dolist (item (directory (merge-pathnames "*/*" *test-dir*)))
        (when (and (pathname-name item)
                   (string= (pathname-name item) "")
                   (probe-file (merge-pathnames "===" item)))
          (let* ((test-id (first (last (pathname-directory item))))
                 (description (read-test-description item))
                 (category (categorize-test description)))
            (incf test-count)
            (add-to-category category test-id)))))
    
    (format t "~&Analyzed ~d tests~%" test-count)
    (format t "~&Categories:~%")
    (maphash (lambda (category tests)
               (format t "  ~a: ~d tests~%" category (length tests)))
             categories)
    
    categories))

;; Run analysis
(analyze-test-suite)