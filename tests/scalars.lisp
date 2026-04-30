;;;; tests/scalars.lisp
;;;; Simple stub scalars test file that does nothing

(defpackage #:com.djhaskin.yamcl/tests/scalars
  (:use #:cl)
  (:import-from
    #:org.shirakumo.parachute
    #:define-test
    #:true
    #:false
    #:fail
    #:is
    #:isnt
    #:of-type
    #:finish)
  (:import-from #:com.djhaskin.yamcl/scalars)
  (:local-nicknames
    (#:parachute #:org.shirakumo.parachute)
    (#:scalars   #:com.djhaskin.yamcl/scalars)))

(in-package #:com.djhaskin.yamcl/tests/scalars)

;;; Minimal test to make compilation succeed
(define-test scalars-suite)

(define-test dummy-test
  :parent scalars-suite
  (is t t "Dummy test passes"))
