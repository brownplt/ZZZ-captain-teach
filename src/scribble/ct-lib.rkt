#lang racket/base

(require json net/url scribble/core scribble/html-properties racket/string)

(provide (all-defined-out))

(define CT.JS (url #f #f #f #f #t (list (path/param "ct.js" (list))) (list) #f))
(define JQUERY (url #f #f #f #f #t (list (path/param "jquery.js" (list))) (list) #f))
(define FLAPJAX (url #f #f #f #f #t (list (path/param "flapjax-impl.js" (list))) (list) #f))

(define current-id-prefix (make-parameter ""))

(define (mk-id mode id)
  (string-append* (list mode ":" (current-id-prefix) "/" id)))

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

(define-syntax-rule (journey unique-id elt ...)
  (parameterize [(current-id-prefix unique-id)]
    (multiarg-element
      (style #f (list (js-addition JQUERY) (js-addition CT.JS) (js-addition FLAPJAX)))
      (list elt ...))))

