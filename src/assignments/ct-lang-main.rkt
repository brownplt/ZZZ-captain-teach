#lang racket/base

(require
  racket/cmdline
  json
  (only-in racket/list first)
  "ct-lang.rkt")

(command-line
  #:args file-and-maybe-other-stuff
  (when (> (length file-and-maybe-other-stuff) 1)
    (error "Expected only a single argument, got" file-and-maybe-other-stuff))
  (define file-to-run (simplify-path (path->complete-path (first file-and-maybe-other-stuff))))
  (define result (dynamic-require file-to-run 'result))
  (write-json (to-json result) (current-output-port)))

