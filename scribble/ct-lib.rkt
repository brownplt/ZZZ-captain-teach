#lang racket


(require json net/url scribble/core scribble/html-properties racket/string racket/list)

(provide
  (all-from-out scribble/core)
  (all-defined-out))

(define current-id-prefix (make-parameter ""))

(define (mk-resource type perms id args)
  (make-hash
    (list
      (cons 'type type)
      (cons 'perms perms)
      (cons 'ref (string-append (current-id-prefix) "/" id))
      (cons 'args args))))

(define-struct holder (elt))

(define-struct choice (data html))

(define (validate-mode mode)
  (symbol->string
   (match mode
     ['include mode]
     ['include-run mode]
     ['run mode]
     ['inert mode]
     [else (error (format "Invalid mode for code component: ~a" mode))])))

(define current-choice-id (make-parameter ""))

(define (single-resource n r)
  (jsexpr->string
   (make-hash
    (list (cons n r)))))

(define (create-choice id type contents)
  (choice
    (make-hash
      (list
        (cons 'type type)
        (cons 'name id)))
    (element
      (style #f
             (list
              (alt-tag "div")
              (attributes
                (list
                  (cons 'id id)))))
       contents)))
       #|
    (element
      (style #f
             (list
               (alt-tag "input")
               (attributes
                (list
                  (cons 'type "radio")
                  (cons 'id id)
                  (cons 'name (current-choice-id))))))
      (list
        (element
          (style #f
                 (list
                  (alt-tag "label")
                  (attributes
                    (list
                      (cons 'for id)))))
          contents)
        (element
          (style #f
                 (list
                  (alt-tag "br")
                  (attributes empty)))
           "")))))
           |#

;; TODO(joe): this is an obfuscation point
(define-syntax-rule (choice-incorrect id content ...)
  (create-choice id "choice-incorrect" content ...))

;; TODO(joe): this is an obfuscation point
(define-syntax-rule (choice-correct id content ...)
  (create-choice id "choice-correct" content ...))

(define-syntax-rule (multiple-choice unique-id elt ...)
  (begin
    (let [(choices (parameterize [(current-choice-id unique-id)]
                                  (filter choice? (list elt ...))))]
    (element
      (style #f
             (list
              (alt-tag "div")
              (attributes
                (list
                  (cons 'data-ct-node "1")
                  (cons 'data-activity-id unique-id)
                  (cons 'data-resources (single-resource 'blob (mk-resource "b" "rc" unique-id (make-hash))))
                  (cons 'data-type "multiple-choice")
                  (cons 'data-args (jsexpr->string
                    (make-hash
                      (list
                        (cons 'choices (map choice-data choices))
                        (cons 'id unique-id)))))))))
      (map choice-html choices)))))

(define-syntax-rule (function mode1 unique-id elt ...)
   (begin
     (letrec [(mode (validate-mode mode1))
              (parts (filter holder? (list elt ...)))
              ;;(include (holder-elt (first parts)))
              (header (holder-elt (first parts)))
              (check (holder-elt (second parts)))]
     (element
       (style #f
              (list
                (alt-tag "div")
                (attributes
                  (list
                    (cons 'data-ct-node "1")
                    (cons 'data-activity-id unique-id)
                    (cons 'data-resources (jsexpr->string
                                           (make-hash
                                            (list (cons 'path (mk-resource "p" "rw" unique-id (make-hash)))
                                                  (cons 'blob (mk-resource "b" "rw" unique-id (make-hash)))))))
                    (cons 'data-type "function")
                    (cons 'data-args (jsexpr->string
                    (make-hash
                    (list
                      (cons 'mode mode)
                      (cons 'header header)
                      (cons 'check check)))))))))
       ""))))

(define-syntax-rule (inline-example elt ...)
  (let [(code (string-append* (list elt ...)))]
  (element
    (style #f
           (list
             (alt-tag "span")
             (attributes
               (list
                 (cons 'data-ct-node "1")
                 (cons 'data-type "inline-example")
                 (cons 'data-args (jsexpr->string
                   (make-hash
                   (list
                     (cons 'code code)))))))))
    "")))


(define-syntax-rule (code-example mode1 elt ...)
  (let [(mode (validate-mode mode1))
        (code (string-append* (list elt ...)))]
  (element
    (style #f
           (list
             (alt-tag "div")
             (attributes
               (list
                 (cons 'data-ct-node "1")
                 (cons 'data-type "code-example")
                 (cons 'data-args (jsexpr->string
                   (make-hash
                   (list
                     (cons 'mode mode)
                     (cons 'code code)))))))))
    "")))

(define-syntax-rule (code-library lib-name elt ...)
  (let [(code (string-append* (list elt ...)))]
  (element
    (style #f
           (list
             (alt-tag "div")
             (attributes
               (list
                 (cons 'data-ct-node "1")
                 (cons 'data-type "code-library")
                 (cons 'data-args (jsexpr->string
                   (make-hash
                   (list
                     (cons 'mode "include")
                     (cons 'name lib-name)
                     (cons 'code code)))))))))
    "")))

(define-syntax-rule (include elt ...)
  (holder (list elt ...)))

(define-syntax-rule (header elt ...)
  (holder (string-append* (list elt ...))))

(define-syntax-rule (check elt ...)
  (holder (string-append* (list elt ...))))

(define-syntax-rule (journey unique-id)
  (current-id-prefix unique-id))

