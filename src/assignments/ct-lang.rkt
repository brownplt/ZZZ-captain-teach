#lang racket/base

(require
 (only-in racket/list first)
 racket/string
 racket/match
 (only-in json json-null)
 (for-syntax racket/base)
 (for-syntax syntax/parse))
(provide (all-defined-out))

(define (to-json thing)
  (cond
    [(string? thing) thing]
    [(number? thing) thing]
    [(equal? thing (json-null)) thing]
    [(boolean? thing) thing]
    [(list? thing) (map to-json thing)]
    [(tojsonable? thing) (thing)]
    [else
     (error (format "Not a jsonable value: ~a.
Possible reasons:
- You forgot to use json-struct or inherit from something that does
- You used a symbol and need to have used a string
- You used the wrong value for json-null (currently ~a)" thing (json-null)))]))

(struct tojsonable ())
(define-syntax (json-struct stx)
  (syntax-case stx ()
   [(_ name (field ...))
    #'(json-struct name tojsonable (field ...))]
    [(_ name super (field ...))
    (with-syntax
      ([(accessor ...) (map (lambda (field)
                              (datum->syntax #'field
                                             (string->symbol
                                              (format "~a-~a"
                                                      (syntax->datum #'name)
                                                      field))))
                            (syntax->datum #'(field ...)))]
       [name-str (datum->syntax #'name (symbol->string (syntax->datum #'name)))])
      #'(struct name super (field ...)
        #:property prop:procedure
        (lambda (instance)
          (match instance
            [(name field ...)
             (apply hasheq
              (append
                 (list 'tag name-str)
                 (list (quote field) (to-json (accessor instance))) ...))]))))]))

(json-struct _assignment (name description instructions pieces))

;; Pieces:

(json-struct piece ())

(json-struct _function piece
  (name
   description
   instructions
   header
   check-block
   definition))

(json-struct _header ())

(json-struct _header/given _header
  (
   name
   instructions
   fun-name
   arguments
   return
   purpose))

(json-struct _check-block (name instructions))
(json-struct _definition (name instructions))

(json-struct _description (body))
(json-struct _instructions (body))

(json-struct _fun-name (name))
(json-struct _argument (name ann))
(json-struct _return (ann))
(json-struct _purpose (str))
(define fun-name _fun-name)
(define argument _argument)
(define return _return)
(define purpose _purpose)


(define (find-description lst)
  (first (filter _description? lst)))
(define (find-instructions lst)
  (first (filter _instructions? lst)))
(define (find-header lst)
  (first (filter _header? lst)))
(define (find-check-block lst)
  (first (filter _check-block? lst)))
(define (find-definition lst)
  (first (filter _definition? lst)))
(define (find-fun-name lst)
  (first (filter _fun-name? lst)))
(define (find-arguments lst)
  (filter _argument? lst))
(define (find-return lst)
  (first (filter _return? lst)))
(define (find-purpose lst)
  (first (filter _purpose? lst)))

(define (find-pieces lst)
  (filter piece? lst))
 
(define-syntax assignment
  (lambda (stx)
    (syntax-case stx ()
      [(_ name elt ...)
       (with-syntax ([(id ...) (generate-temporaries #'(elt ...))])
       #'(begin
       (provide result)
       (define result (let [(id elt) ...]
          (_assignment
            name
            (find-description (list id ...))
            (find-instructions (list id ...))
            (find-pieces (list id ...)))))))])))

(define-syntax function
  (lambda (stx)
    (syntax-case stx ()
      [(_ name elt ...)
       (with-syntax ([(id ...) (generate-temporaries #'(elt ...))])
         #'(let [(id elt) ...]
            (_function
              name
              (find-description (list id ...))
              (find-instructions (list id ...))
              (find-header (list id ...))
	      (find-check-block (list id ...))
              (find-definition (list id ...))
              )))])))

(define-syntax header/given
  (lambda (stx)
    (syntax-case stx ()
      [(_ name elt ...)
       (with-syntax ([(id ...) (generate-temporaries #'(elt ...))])
         #'(let [(id elt) ...]
          (_header/given
            name
            (find-instructions (list elt ...))
            (find-fun-name (list elt ...))
            (find-arguments (list elt ...))
            (find-return (list elt ...))
            (find-purpose (list elt ...)))))])))

(define (check-block . elts)
  (_check-block
    (first elts)
    (find-instructions elts)))

(define (definition . elts)
  (_definition
    (first elts)
    (find-instructions elts)))


(define-syntax-rule (description body ...)
  (_description (string-append body ...)))
(define-syntax-rule (instructions body ...)
  (_instructions (string-append body ...)))

