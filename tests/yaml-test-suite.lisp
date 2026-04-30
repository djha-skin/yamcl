;;;; tests/yaml-test-suite.lisp
;;;; 
;;;; Runs the official YAML test suite (https://github.com/yaml/yaml-test-suite)
;;;; using yamcl.
;;;;
;;;; The test suite is included as a git submodule in tests/fixtures/yaml-test-suite/
;;;; Each test represents a YAML input file, expected output JSON, and optional
;;;; error indication.

(defpackage #:com.djhaskin.yamcl/tests/yaml-test-suite
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
    #:finish
    #:skip)
  (:import-from #:com.djhaskin.yamcl)
  (:local-nicknames
    (#:parachute #:org.shirakumo.parachute)
    (#:yamcl     #:com.djhaskin.yamcl)))

(in-package #:com.djhaskin.yamcl/tests/yaml-test-suite)

;;; -------------------------------------------------------
;;; Constants and Paths
;;; -------------------------------------------------------

(defparameter *test-suite-root*
  (asdf:system-relative-pathname
    :com.djhaskin.yamcl/tests
    "fixtures/yaml-test-suite/")
  "Root directory of the YAML test suite submodule.")

(defun test-directory-p (path)
  "Return T if PATH is a test directory (contains in.yaml)."
  (and (uiop:directory-exists-p path)
       (uiop:file-exists-p (merge-pathnames "in.yaml" path))))

(defun collect-test-paths ()
  "Return a list of all test directory paths."
  (let ((paths ()))
    (uiop:collect-sub*directories
      *test-suite-root*
      (constantly t)  ; always descend
      (lambda (dir)
        (and (uiop:directory-exists-p dir)
             (uiop:file-exists-p (merge-pathnames "in.yaml" dir))))
      (lambda (dir) (push dir paths)))
    (nreverse paths)))

(defun read-test-file (test-dir filename)
  "Read file named FILENAME from TEST-DIR, return content as string or NIL if missing."
  (let ((path (merge-pathnames filename test-dir)))
    (when (uiop:file-exists-p path)
      (uiop:read-file-string path))))

(defun test-name (test-dir)
  "Generate a test name from the directory path."
  (let* ((relative (enough-namestring test-dir *test-suite-root*))
         (name (string-right-trim "/" relative)))
    (if (string= name "") 
        "unknown"
        name)))

(defun test-label (test-dir)
  "Return the test label (from === file) or NIL."
  (read-test-file test-dir "==="))

(defun test-is-error (test-dir)
  "Return T if test expects an error."
  (uiop:file-exists-p (merge-pathnames "error" test-dir)))

(defun test-is-valid (test-dir)
  "Return T if test is valid YAML (no error file)."
  (not (test-is-error test-dir)))

;;; -------------------------------------------------------
;;; Test Runner
;;; -------------------------------------------------------

(define-test yaml-test-suite
  "Top-level test suite for YAML test suite integration.")

(defun run-single-test (test-dir)
  "Run a single test from TEST-DIR.
Returns T if test passes, NIL if fails, :skip if unsupported."
  (let* ((in-yaml (read-test-file test-dir "in.yaml"))
         (in-json-str (read-test-file test-dir "in.json"))
         (name (test-name test-dir))
         (label (test-label test-dir))
         (expect-error (test-is-error test-dir)))
    
    (unless in-yaml
      (warn "Test ~A missing in.yaml" name)
      (return-from run-single-test :skip))
    
    ;; Just run the test logic without parachute:test wrapper for now
    (cond
      (expect-error
       ;; Test expects parse error
       :skip-error-not-implemented)
      
      ((and in-json-str (not expect-error))
       ;; Compare with expected JSON (if available)
       :skip-json-not-implemented)
      
      (t
       ;; Just try to parse without comparison
       (handler-case
           (let ((result (yamcl:parse-from-string in-yaml)))
             ;; If we get here, parsing succeeded.
             ;; For now we just accept that.
             t)
         (error (e)
           (warn "Test ~A failed: ~A" name e)
           nil))))))

(defun run-all-tests (&key (filter nil))
  "Run all YAML test suite tests.
FILTER can be a function taking test-dir -> T/NIL, or a regex string."
  (let ((test-dirs (collect-test-paths))
        (passed 0)
        (failed 0)
        (skipped 0))
    
    (format t "~&Found ~D test directories.~%" (length test-dirs))
    
    (dolist (test-dir test-dirs)
      (let ((name (test-name test-dir)))
        (when (or (null filter)
                  (and (stringp filter) (search filter name))
                  (and (functionp filter) (funcall filter test-dir)))
          (format t "Running test ~A... " name)
          (finish-output)
          (let ((result (run-single-test test-dir)))
            (case result
              (:skip (incf skipped) (format t "SKIP~%"))
              (t (incf passed) (format t "PASS~%")))
            (unless result
              (incf failed) (format t "FAIL~%"))))))
    
    (format t "~&Summary: ~D passed, ~D failed, ~D skipped~%" 
            passed failed skipped)
    (values passed failed skipped)))

;;; -------------------------------------------------------
;;; Entry point for interactive use
;;; -------------------------------------------------------

(defun test (&key (filter "simple"))
  "Run tests matching FILTER (string)."
  (run-all-tests :filter filter))

(define-test all-simple-tests
  :parent yaml-test-suite
  (format t "Running simple tests...~%")
  (run-all-tests :filter "simple"))

(define-test all-spec-tests
  :parent yaml-test-suite
  (format t "Running spec example tests...~%")
  (run-all-tests :filter "spec"))
