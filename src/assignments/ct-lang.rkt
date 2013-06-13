#lang racket/base

(require racket/list racket/string scribble/core json (for-syntax racket/base))
(provide (all-defined-out))

(struct _assignment (name description instructions pieces))

;; Pieces:

(struct piece ())

(struct _function piece
  (name
   description
   instructions
   header
   check-block
   definition))

(struct _header (name instructions))

(struct _header/given _header
  (fun-name
   arguments
   return
   purpose))

(struct _check-block (name instructions))
(struct _definition (name instructions))

(struct _description (body))
(struct _instructions (body))

(struct _fun-name (name))
(struct _argument (name ann))
(struct _return (ann))
(struct _purpose (str))
(define fun-name _fun-name)
(define argument _argument)
(define return _return)
(define purpose _purpose)

(define (render-description d)
  (content->string (paragraph-content (_description-body d))))

(define (render-instructions i)
  (content->string (paragraph-content (_instructions-body i))))

(define (piece->json p)
  (cond
    [(_function? p) (function->json p)]))

(define (function->json f)
  (hasheq
    'tag "function"
    'name (_function-name f)
    'description (render-description (_function-description f))
    'instructions (render-instructions (_function-instructions f))
    'header (header/given->json (_function-header f))
    'check_block (check-block->json (_function-check-block f))
    'definition (definition->json (_function-definition f))
    ))

(define fun-name->json _fun-name-name)
(define (argument->json a)
  (hasheq
    'name (_argument-name a)
    'ann (_argument-ann a)))
(define return->json _return-ann)
(define purpose->json _purpose-str)

(define (header/given->json h)
  (hasheq
    'tag "header_given"
    'name (_header-name h)
    'instructions (render-instructions (_header-instructions h))
    'fun_name (fun-name->json (_header/given-fun-name h))
    'arguments (map argument->json (_header/given-arguments h))
    'return (return->json (_header/given-return h))
    'purpose (purpose->json (_header/given-purpose h))))


(define (assignment->json a)
  (hasheq
    'tag "assignment"
    'name (_assignment-name a)
    'description (render-description (_assignment-description a))
    'instructions (render-instructions (_assignment-instructions a))
    'pieces (map piece->json (_assignment-pieces a))))

(define (check-block->json c)
  (hasheq
    'tag "check_block"
    'name (_check-block-name c)
    'instructions (render-instructions (_check-block-instructions c))))
(define (definition->json d)
  (hasheq
    'tag "definition"
    'name (_definition-name d)
    'instructions (render-instructions (_definition-instructions d))))


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
       (display (jsexpr->string (assignment->json
        (let [(id elt) ...]
          (_assignment
            name
            (find-description (list id ...))
            (find-instructions (list id ...))
            (find-pieces (list id ...)))))))))])))

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
  (_description (paragraph (style "description" empty) (string-append* (list body ...)))))
(define-syntax-rule (instructions body ...)
  (_instructions (paragraph (style "instructions" empty) (string-append* (list body ...)))))

