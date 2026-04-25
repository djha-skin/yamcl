;;;; yamcl/tests/scalars.lisp
;;;;
;;;; Unit tests for YAML scalar values.
;;;;
;;;; Tests cover every example listing in the YAML 1.2.2 spec AND the JSON RFC.
;;;; Code should correspond to `src/scalars.lisp` which parses scalars.

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

;;; -------------------------------------------------------
;;; Top-level suite
;;; -------------------------------------------------------

(define-test scalars-suite)

(defun float= (a b &key (epsilon 1e-6))
  (< (abs (- a b)) epsilon))

(define-test scalars-strings
  :parent scalars-suite
  (fail (scalars:parse-scalar-from-string ""))
  (is string= (scalars:parse-scalar-from-string "\"\"") "")
  (is string= (scalars:parse-scalar-from-string "Sammy Sosa") "Sammy Sosa")
  (is string= (scalars:parse-scalar-from-string "\"Sammy Sosa\"") "Sammy Sosa")
  (is string= (scalars:parse-scalar-from-string "|\n \\//||\\/||\n // ||  ||__ \n") "\\//||\\/||\n// ||  ||__ ")
  (is string= (scalars:parse-scalar-from-string "|\n \\//||\\/||\n // ||  ||__ \n") "\\//||\\/||\n// ||  ||__ ")
  (is string= (scalars:parse-scalar-from-string ">\n  Mark McGwire's\n  year wasw crippled\n  by a knee injury.") "Mark McGwire's year wasw crippled by a knee injury.")
  (is string= (scalars:parse-scalar-from-string ">\n Sammy Sosa completed another\n fine season with great stats.\n \n   63 Home Runs\n   0.288 Batting Average\n \n What a year!\n")
      "Sammy Sosa completed another fine season with great stats.\n\n  63 Home Runs\n  0.288 Batting Average\n\nWhat a year!")
  (is string= (scalars:parse-scalar-from-string "\"Sosa did fine.\\u263A\"" (concatenate 'string "Sosa did fine." (string (code-char #x263A)))))
  (is string= (scalars:parse-scalar-from-string "\"\\b1990\\t1999\\\\march\\t2000\/2001\\f\\n\\r\"")
        (concatenate 'string
            (string (code-char 8))
            "1990"
            (string (code-char 9))
            "1999\\march"
            (string (code-char 9))
            "2000/2001"
            (string (code-char 12))
            (string (code-char 10))
            (string (code-char 13))))
  (is string= (scalars:parse-scalar-from-string "\"Antidisestab\\\\\\nlishmentariansim.\\n\\nGet on it.\"") "Antidisestablishmentariansim.\n\nGet on it.")
  (is string= (scalars:parse-scalar-from-string "\"\\x0d\\x0a is \\r\\n\"")
      (concatenate 'string
        (string (code-char 13))
        (string (code-char 10)
        " is "
        (string (code-char 13))
        (string (code-char 10)))))
  (is string= (scalars:parse-scalar-from-string "'\"Howdy!\" he cried.'") "\"Howdy!\" he cried.")
  (is string= (scalars:parse-scalar-from-string "; # Not a ''comment''.') ") "; Not a 'comment'.")
  (is string= (scalars:parse-scalar-from-string "'|\-*-/|'") "|-*-/|")
  (is string= (scalars:parse-scalar-from-string "This unquoted scalar\nspans many lines.") "This unquoted scalar\nspans many lines.")
  (is string= (scalars:parse-scalar-from-string "So does this\nquoted scalar.\n") "So does this\nquoted scalar.\n"))


(define-test scalars-numbers
  (is = (scalars:parse-scalar-from-string "65") 65)
  (is float= (scalars:parse-scalar-from-string "0.278") 0.278)
  (is eql (scalars:parse-scalar-from-string "+.inf") :positive-infinity)
  (is eql (scalars:parse-scalar-from-string "-.inf") :negative-infinity)
  (is eql (scalars:parse-scalar-from-string ".nan") :not-a-number))

(define-test example-2.2-scalars-mapping-of-scalars
  :parent scalars-suite
  (is string= (scalars:parse-scalar-from-string "hr") "hr")
  (is string= (scalars:parse-scalar-from-string "avg") "avg")
  (is float= (scalars:parse-scalar-from-string "65") 65.0)
  (is float= (scalars:parse-scalar-from-string "0.278") 0.278)
  (is = (scalars:parse-scalar-from-string 147) 147))
