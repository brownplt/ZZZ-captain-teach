#lang racket


(require json net/url scribble/core scribble/html-properties racket/string racket/list)

(provide
  (all-from-out scribble/core)
  (all-defined-out))

(define current-id-prefix (make-parameter ""))

(define (mk-id type mode id)
  (string-append* (list type ":" mode ":"
                        (current-id-prefix) "/" id)))

(define-struct holder (elt))

;; TODO(joe): this is an obfuscation point
(define-syntax-rule (choice-incorrect id str)
  (make-hash
    (list
      (cons 'type "choice-incorrect")
      (cons 'name id)
      (cons 'content str))))


;; TODO(joe): this is an obfuscation point
(define-syntax-rule (choice-correct id str)
  (begin
    (make-hash
      (list
        (cons 'type "choice-correct")
        (cons 'name id)
        (cons 'content str)))))


(define-syntax-rule (multiple-choice unique-id elt ...)
  (begin
    (let [(choices (filter hash? (list elt ...)))]
    (element
      (style #f
             (list
              (alt-tag "div")
              (attributes
                (list
                  (cons 'data-ct-node "1")
                  (cons 'data-id (mk-id "b" "rc" unique-id))
                  (cons 'data-type "multiple-choice")
                  (cons 'data-args (jsexpr->string choices))))))
      ""))))

(define-syntax-rule (function unique-id elt ...)
   (begin
     (letrec [(parts (filter holder? (list elt ...)))
              (include (holder-elt (first parts)))
              (header (holder-elt (second parts)))
              (check (holder-elt (third parts)))]
     (element
       (style #f
              (list
                (alt-tag "div")
                (attributes
                  (list
                    (cons 'data-ct-node "1")
                    (cons 'data-id (mk-id "p" "rw" unique-id))
                    (cons 'data-type "function")
                    (cons 'data-args (jsexpr->string
                    (make-hash
                    (list
                      (cons 'includes include)
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


(define-syntax-rule (code-example elt ...)
  (let [(code (string-append* (list elt ...)))]
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
                 (cons 'data-ct-resource "1")
                 (cons 'data-type "code-library")
                 (cons 'data-args (jsexpr->string
                   (make-hash
                   (list
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

