;;;; tests/yaml-test-suite.lisp
;;;;
;;;; Runs the official YAML test suite.

(in-package #:com.djhaskin.yamcl/tests)

(defparameter *test-suite-root*
  (uiop:merge-pathnames*
    (make-pathname :directory '(:relative "tests" "fixtures"
                                          "yaml-test-suite"))
    (asdf:system-source-directory :com.djhaskin.yamcl)))

(defun collect-test-paths ()
  "Return a list of all test directory paths."
  (let ((paths ()))
    ;; Recursively find all directories with in.yaml files
    (labels ((collect-from-dir (dir)
               (dolist (entry (uiop:directory* (merge-pathnames "*" dir)))
                 (when (uiop:directory-exists-p entry)
                   (let ((in-yaml-path (merge-pathnames "in.yaml" entry)))
                     (when (uiop:file-exists-p in-yaml-path)
                       (push entry paths))
                     ;; Recurse into subdirectories
                     (collect-from-dir entry))))))
      (collect-from-dir *test-suite-root*)
      ;; Filter out unwanted directories
      (setf paths
            (remove-if (lambda (path)
                         (or (string= (namestring path) (namestring *test-suite-root*))
                             (search "/name/" (namestring path))
                             (search "/tags/" (namestring path))
                             (search "/.git" (namestring path))))
                       paths))
      paths)))

(defun read-test-file (test-dir filename)
  "Read file named FILENAME from TEST-DIR, return content as string."
  (let ((path (merge-pathnames filename test-dir)))
    (when (uiop:file-exists-p path)
      (uiop:read-file-string path))))

(defun test-name (test-dir)
  "Generate a test name from the directory path."
  (let* ((relative (enough-namestring test-dir *test-suite-root*))
         (name (string-right-trim "/" relative)))
    (if (string= name "")
        (first (last (pathname-directory test-dir)))
        name)))

(defun test-is-error (test-dir)
  "Return T if test expects an error."
  (uiop:file-exists-p (merge-pathnames "error" test-dir)))

(defun run-single-test (test-dir)
  "Run a single test from TEST-DIR."
  (let* ((in-yaml (read-test-file test-dir "in.yaml"))
         (name (test-name test-dir))
         (expect-error (test-is-error test-dir)))

    (unless in-yaml
      (return-from run-single-test :skip))

    (handler-case
        (progn
          (com.djhaskin.yamcl:parse-from-string in-yaml)
          t)
      (error (e)
        nil))))

(defun run-all-tests ()
  "Run all YAML test suite tests and report results."
  (let ((test-dirs (collect-test-paths))
        (passed 0)
        (failed 0)
        (skipped 0))

    (format t "~&Found ~D test directories.~%" (length test-dirs))

    (dolist (test-dir test-dirs)
      (let ((name (test-name test-dir)))
        (format t "Running test ~A... " name)
        (finish-output)
        (let ((result (run-single-test test-dir)))
          (case result
            (:skip
             (incf skipped)
             (format t "SKIP~%"))
            (t
             (if result
                 (progn (incf passed) (format t "PASS~%"))
                 (progn (incf failed) (format t "FAIL~%"))))))))

    (format t "~&Summary: ~D passed, ~D failed, ~D skipped~%"
            passed failed skipped)
    (values passed failed skipped)))

(define-test yaml-test-suite-runner
  :parent yamcl-tests
  "Run all YAML test suite tests"
  (format t "~%=== Running all YAML test suite tests ===~%")
  (multiple-value-bind (passed failed skipped)
      (run-all-tests)
    (format t "~%=== Final Results ===~%")
    (format t "Passed: ~D~%" passed)
    (format t "Failed: ~D~%" failed)
    (format t "Skipped: ~D~%" skipped)
    (format t "Total: ~D~%" (+ passed failed skipped))
    (true (> (+ passed failed skipped) 0) "Should run some tests")
    (let ((total-tests (length (collect-test-paths))))
      (is = (+ passed failed skipped) total-tests
          (format nil "Should run all ~D tests" total-tests)))))