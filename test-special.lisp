(in-package #:com.djhaskin.yamcl)

(format t "Testing +.inf: ")
(handler-case
    (format t "~S~%" (parse-from-string "+.inf"))
  (error (e) (format t "ERROR: ~A~%" e)))

(format t "Testing +.nan: ")
(handler-case
    (format t "~S~%" (parse-from-string "+.nan"))
  (error (e) (format t "ERROR: ~A~%" e)))

(format t "Testing .inf: ")
(handler-case
    (format t "~S~%" (parse-from-string ".inf"))
  (error (e) (format t "ERROR: ~A~%" e)))

(format t "Testing .nan: ")
(handler-case
    (format t "~S~%" (parse-from-string ".nan"))
  (error (e) (format t "ERROR: ~A~%" e)))

(format t "Testing +.foo (should error): ")
(handler-case
    (format t "~S~%" (parse-from-string "+.foo"))
  (error (e) (format t "Got error as expected: ~A~%" e)))
