(defsystem "com.djhaskin.yamcl"
  :version "0.1.0"
  :author "Daniel Jay Haskin"
  :license "MIT"
  :depends-on (
               "alexandria"
               )
  :components ((:module "src"
                :components
                ((:file "main")
                 (:file "scalars"
                  :depends-on ("main")))))
  :description
  "YAML Ain't Markup Language -- Common Lisp. A pure Common Lisp
library for parsing and rendering YAML."
  :in-order-to
  ((test-op (test-op "com.djhaskin.yamcl/tests"))))

(defsystem "com.djhaskin.yamcl/tests"
  :version "0.1.0"
  :author "Daniel Jay Haskin"
  :license "MIT"
  :depends-on (
               "com.djhaskin.yamcl"
               "parachute"
               )
  :components ((:module "tests"
                :components
                ((:file "main")
                 (:file "scalars"))))
  :description "Test system for yamcl"
  :perform (asdf:test-op (op c)
                    (uiop:symbol-call
                      :parachute
                      :test
                      '#:com.djhaskin.yamcl/tests)))
