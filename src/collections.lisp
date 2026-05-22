;; Collections module for yamcl
;; Handles YAML mappings (objects/dictionaries) and sequences (arrays/lists)

(in-package :com.djhaskin.yamcl/collections)

(defun parse-block-mapping (lookahead)
  "Parse a YAML block mapping from LOOKAHEAD stream.
Returns a hash table."
  (let ((mapping (make-hash-table :test 'equal)))
    (loop
      (skip-whitespace-and-comments-lookahead lookahead)
      ;; Check for indentation - for now, we assume same level (0)
      (let ((ch (lookahead-peek-chr lookahead 0)))
        (when (or (eq ch +eof+) (char= ch #\:))
          ;; We've reached end of mapping or no key
          (return mapping)))
      
      ;; Parse key
      (let* ((key (parse-scalar-lookahead lookahead key?)))
        
      ))))