#lang racket/base

(require racket/cmdline web-server/templates)
(define run-compiled (open-output-file "run.html" #:exists 'replace))

(command-line
  #:once-each
  ("--whalesong-url" whalesong-url "Build run.html with the given whalesong-url"
   (display (include-template "run.template") run-compiled)))

