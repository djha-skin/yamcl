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
                :skip))

(cl:in-package :com.djhaskin.yamcl/tests)
