#lang racket/base


(require json net/url scribble/core scribble/html-properties racket/string racket/list)

(provide (all-defined-out))

(define current-id-prefix (make-parameter ""))

(define (mk-id mode id)
  (string-append* (list mode ":" (current-id-prefix) "/" id)))

(define-struct str-holder (str))

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
                  (cons 'data-id (mk-id "rc" unique-id))
                  (cons 'data-type "multiple-choice")
                  (cons 'data-args (jsexpr->string choices))))))
      ""))))

(define-syntax-rule (function unique-id elt ...)
   (begin
     (letrec [(parts (filter str-holder? (list elt ...)))
              (header (str-holder-str (first parts)))
              (check (str-holder-str (second parts)))]
     (element
       (style #f
              (list
                (alt-tag "div")
                (attributes
                  (list
                    (cons 'data-ct-node "1")
                    (cons 'data-id (mk-id "rw" unique-id))
                    (cons 'data-type "function")
                    (cons 'data-args (jsexpr->string
                    (make-hash
                    (list
                      (cons 'header header)
                      (cons 'check check)))))))))
       ""))))

(define-syntax-rule (header elt ...)
  (str-holder (string-append* (list elt ...))))

(define-syntax-rule (check elt ...)
  (str-holder (string-append* (list elt ...))))

(define-syntax-rule (journey unique-id elt ...)
  (parameterize [(current-id-prefix unique-id)]
    (multiarg-element
      (style #f (list))
      (list elt ...))))
