;;;; tests/yaml-test-suite-runner.lisp
;;;; 
;;;; Simple test runner for YAML test suite that doesn't require the full
;;;; Common Lisp environment to be loaded.

(defpackage #:yamcl-test-runner
  (:use #:cl)
  (:export #:run-tests #:run-single-test))

(in-package #:yamcl-test-runner)

;;; File utilities
(defun read-file-contents (path)
  "Read contents of file at PATH as string."
  (with-open-file (stream path :direction :input)
    (let ((contents (make-string (file-length stream))))
      (read-sequence contents stream)
      contents)))

(defun file-exists-p (path)
  "Check if file exists."
  (probe-file path))

(defun directory-exists-p (path)
  "Check if directory exists."
  (and (probe-file path)
       (pathname-name path) ; directory has no name
       (not (pathname-type path))))

(defun list-directories (path)
  "List subdirectories in PATH."
  (let ((dirs ())
        (entries (directory (concatenate 'string path "/*/"))))
    (dolist (entry entries dirs)
      (when (directory-exists-p entry)
        (push entry dirs)))
    (nreverse dirs)))

;;; Test suite path
(defvar *suite-root* (merge-pathnames "tests/fixtures/yaml-test-suite/"
                                      (asdf:system-source-directory :com.djhaskin.yamcl)))

(defun test-directory-p (path)
  "Check if directory contains a test (has in.yaml)."
  (file-exists-p (merge-pathnames "in.yaml" path)))

(defun collect-test-paths ()
  "Collect all test directory paths."
  (let ((paths ()))
    (labels ((collect (dir)
               (when (test-directory-p dir)
                 (push dir paths))
               (dolist (subdir (list-directories dir))
                 (collect subdir))))
      (collect *suite-root*))
    (nreverse paths)))

(defun read-test-file (test-dir filename)
  "Read file from test directory."
  (let ((path (merge-pathnames filename test-dir)))
    (when (file-exists-p path)
      (read-file-contents path))))

(defun test-name (test-dir)
  "Get test name from directory path."
  (let ((relative (enough-namestring test-dir *suite-root*))
        (pos (position #\/ relative :from-end t)))
    (if pos
        (subseq relative (1+ pos))
        relative)))

(defun test-is-error (test-dir)
  "Check if test expects error."
  (file-exists-p (merge-pathnames "error" test-dir)))

;;; Test runner
(defun run-single-test (test-dir &key verbose)
  "Run a single test from test directory."
  (let* ((in-yaml (read-test-file test-dir "in.yaml"))
         (name (test-name test-dir))
         (expect-error (test-is-error test-dir)))
    
    (unless in-yaml
      (when verbose (format t "~A: Missing in.yaml~%" name))
      (return-from run-single-test :skip))
    
    (when verbose (format t "~A: " name))
    
    (cond
      (expect-error
       (when verbose (format t "expects error (not implemented)~%"))
       :skip-error-not-implemented)
      
      (t
       (when verbose (format t "valid test (not implemented)~%"))
       :skip-parser-not-implemented))))

(defun run-tests (&key (filter nil) (verbose t))
  "Run tests matching FILTER."
  (let ((test-dirs (collect-test-paths))
        (passed 0)
        (failed 0)
        (skipped 0))
    
    (format t "Found ~D test directories~%" (length test-dirs))
    
    (dolist (test-dir test-dirs)
      (let ((name (test-name test-dir)))
        (when (or (null filter)
                  (and (stringp filter) (search filter name)))
          (let ((result (run-single-test test-dir :verbose verbose)))
            (cond
              ((or (eq result :skip)
                   (eq result :skip-error-not-implemented)
                   (eq result :skip-parser-not-implemented))
               (incf skipped))
              (t (incf passed)))))))
    
    (format t "~%Summary: ~D would run, ~D skipped~%" passed skipped)
    (list :passed passed :failed failed :skipped skipped)))

;;; Interactive entry point
(defun run-demo ()
  "Run a demo with simple tests."
  (format t "=== YAML Test Suite Demo ===~%")
  (format t "Test suite root: ~A~%" *suite-root*)
  
  (let ((simple-tests (loop for test-dir in (collect-test-paths)
                            for name = (test-name test-dir)
                            when (string= name "9J7A")
                            collect test-dir)))
    (format t "Found ~D test(s) to demonstrate~%" (length simple-tests))
    
    (dolist (test-dir simple-tests)
      (let ((in-yaml (read-test-file test-dir "in.yaml"))
            (in-json (read-test-file test-dir "in.json"))
            (label (read-test-file test-dir "===")))
        (format t "~%=== Test: ~A ===" (test-name test-dir))
        (format t "~%Label: ~A" (or label "(no label)"))
        (format t "~%YAML:~%~A" in-yaml)
        (format t "~%Expected JSON:~%~A" (or in-json "(no JSON)"))
        (format t "~%Expects error: ~A~%" (test-is-error test-dir))))))

(defun main ()
  "Main entry point."
  (if (find-package :com.djhaskin.yamcl)
      (format t "YAMCL is loaded.~%")
      (format t "YAMCL not loaded. Running in demo mode.~%"))
  (run-demo))
