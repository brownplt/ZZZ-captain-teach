#lang racket/base

(require racket/cmdline racket/system web-server/templates)
(require srfi/13)
(define run-compiled (open-output-file "tests/run.html" #:exists 'replace))

(define TESTS-PATH-IN "tests/scribble/scribble-tests")
(define TESTS-RELATIVE-PATH-OUT "scribble/scribble-tests-compiled")
(define TESTS-PATH-OUT (string-append "tests/" TESTS-RELATIVE-PATH-OUT))
(define full-tests-in (path->string (path->complete-path TESTS-PATH-IN)))
(define full-tests-out (path->string (path->complete-path TESTS-PATH-OUT)))

(define (get-name f)
  (define-values (type name base) (split-path f))
  (define name-str (path->string name))
  (define stripped-name (substring name-str 0 (string-index name-str #\.)))
  stripped-name)

(define TEST-NAMES
  (map get-name
       (filter (lambda (f) (string-contains (path->string f) "jrny"))
               (directory-list TESTS-PATH-IN))))

(for ((f TEST-NAMES))
  (system* (find-executable-path "scribble")
            "--dest" full-tests-out
            (path->string (build-path full-tests-in (string-append f ".jrny")))))

(command-line
  #:once-each
  ("--whalesong-url" whalesong-url "Build run.html with the given whalesong-url"
   (display (include-template "tests/run.template") run-compiled)))

