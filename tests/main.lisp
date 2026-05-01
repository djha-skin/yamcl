;;;; tests/main.lisp
;;;; yamcl - YAML Ain't Markup Language -- Common Lisp

(cl:defpackage :com.djhaskin.yamcl/tests
  (:use :cl :com.djhaskin.yamcl)
  (:import-from :org.shirakumo.parachute
                :define-test
                :true
                :false
                :fail
                :is
                :isnt
                :of-type
                :finish
                :skip
                :test))

(cl:in-package :com.djhaskin.yamcl/tests)

;;; Define a test that will be discovered by parachute
(define-test yamcl-tests
  "Top-level test suite for yamcl.")

;;; Simple smoke test
(define-test smoke-test
  :parent yamcl-tests
  (is = 1 1 "Smoke test should pass"))
