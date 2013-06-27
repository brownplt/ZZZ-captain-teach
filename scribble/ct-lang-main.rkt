#lang racket/base

(require
  racket/cmdline
  racket/file
  json
  (only-in racket/list first)
  "ct-lang.rkt")

(command-line
  #:args file-and-maybe-other-stuff
  (when (> (length file-and-maybe-other-stuff) 1)
    (error "Expected only a single argument, got" file-and-maybe-other-stuff))
  (define file-to-run (simplify-path (path->complete-path (first file-and-maybe-other-stuff))))
  (unless (file-exists? file-to-run)
    (error (format "Could not find ct scribble file: ~a" file-to-run)))
  (display (format "~a\n" (file->string file-to-run)) (current-error-port))
  (define result (dynamic-require file-to-run 'result))
  (write-json (to-json result) (current-output-port)))

