#lang racket


(require json net/url scribble/core scribble/html-properties racket/string racket/list)

(provide
  (all-from-out scribble/core)
  (all-defined-out))

(define current-id-prefix (make-parameter ""))

(define (mk-id id)
  (string-append (current-id-prefix) "/" id))

(define (mk-resource type perms id args)
  (make-hash
    (list
      (cons 'type type)
      (cons 'perms perms)
      (cons 'ref (mk-id id))
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
     ['no-run mode]
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
                  (cons 'data-activity-id (mk-id unique-id))
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
              (elts (list elt ...))
              (parts (filter holder? elts))
              ;;(include (holder-elt (first parts)))
              (header (_header-header (first (filter _header? elts))))
              (check (holder-elt (first parts)))]
     (element
       (style #f
              (list
                (alt-tag "div")
                (attributes
                  (list
                    (cons 'data-ct-node "1")
                    (cons 'data-activity-id (mk-id unique-id))
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

(define-syntax-rule (function-reviewable mode1 unique-id elt ...)
  (begin
    (letrec [(mode (validate-mode mode1))
             (elts (list elt ...))
             (parts (filter holder? elts))
             ;;(include (holder-elt (first parts)))
             (header (_header-header (first (filter _header? elts))))
             (check (_check-check (first (filter _check? elts))))]
      (element
          (style #f
            (list
             (alt-tag "div")
             (attributes
              (list
               (cons 'data-ct-node "1")
               (cons 'data-activity-id (mk-id unique-id))
               (cons 'data-resources (jsexpr->string
                                      (make-hash
                                       (list (cons 'path (mk-resource "p" "rw" unique-id (make-hash (list (cons 'reviews 2)))))
                                             (cons 'blob (mk-resource "b" "rw" unique-id (make-hash)))))))
               (cons 'data-type "function")
               (cons 'data-parts (jsexpr->string (list (hash 'type "code" 'value "check")
                                                       (hash 'type "code" 'value "body"))))
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

(struct _part (part-name))
(struct _step _part ())
(struct _library-part _part (code))
(struct _data-part _step (name))
(struct _fun-part _step (header))
(struct _instructions _part (text))

(struct _name (name))
(struct _header (header))
(struct _check (check))

(define-syntax-rule (library-part part-name str ...)
  (_library-part part-name (string-append* (list str ...))))
(define-syntax-rule (data-part part-name str ...)
  (_data-part part-name (_name-name (findf _name? (list str ...)))))
(define-syntax-rule (fun-part part-name str ...)
  (_fun-part part-name (_header-header (findf _header? (list str ...)))))
(define (newline-para-transform str)
  (string-replace str "\n\n" "</p><p>"))
(define-syntax-rule (instructions str ...)
  ;; NOTE(dbp 2013-08-05): instructions don't have names
  (_instructions "" (format "<p>~a</p>" (newline-para-transform (string-append* (list str ...))))))

(define-syntax-rule (name str ...)
  (_name (string-append* (list str ...))))
(define-syntax-rule (header str ...)
  (_header (string-append* (list str ...))))
(define-syntax-rule (check str ...)
  (_check (string-append* (list str ...))))

(define-syntax-rule (code-assignment unique-id review-count elt ...)
  (let ()
    (define i 0)
    (define (genstr)
      (set! i (add1 i))
      (cons 'scratch (format "~a~a" name i)))
    (define elts (list elt ...))
    (define name (_name-name (findf _name? elts)))
    (define assignment-parts (filter _part? elts))
    (struct parts (code-delimiters part-names steps))
    (define (pairs->json cds)
      (map (λ (cons-pair)
              (hash 'type (symbol->string (car cons-pair))
                    'value (cdr cons-pair)))
           cds))
    (define (add-part a-part a-parts)
      (define maybe-line (if (empty? (parts-code-delimiters a-parts)) "" "\n"))
      (match a-part
        [(_library-part part-name code)
         (parts
            (append (list (cons 'code (string-append maybe-line code)))
                    (parts-code-delimiters a-parts))
            (append (list (genstr)) (parts-part-names a-parts))
            (parts-steps a-parts))]
        [(_data-part part-name data-name)
         (define v-step (cons 'variants (format "~a-variants" part-name)))
         (define c-step (cons 'data-checks (format "~a-checks" part-name)))
         (parts
            (append (list
                      (cons 'code (format "~adata ~a:" maybe-line data-name))
                      (cons 'code "\nwhere:")
                      (cons 'code "\nend"))
                    (parts-code-delimiters a-parts))
            (append (list v-step c-step (genstr)) (parts-part-names a-parts))
            (append (list v-step c-step) (parts-steps a-parts)))]
        [(_fun-part part-name fun-header)
         (define b-step (cons 'body (format "~a-body" part-name)))
         (define c-step (cons 'fun-checks (format "~a-checks" part-name)))
         (parts
            (append (list
                      (cons 'code (format "~afun ~a:" maybe-line fun-header))
                      (cons 'code "\nwhere:")
                      (cons 'code "\nend"))
                    (parts-code-delimiters a-parts))
            (append (list b-step c-step (genstr)) (parts-part-names a-parts))
            (append (list c-step b-step) (parts-steps a-parts)))]
        [(_instructions _ instr)
         (parts
          (append (list (cons 'instructions instr)) (parts-code-delimiters a-parts))
          (parts-part-names a-parts)
          (parts-steps a-parts))]))
    (define data (foldr add-part (parts (list) (list) (list)) assignment-parts))
    (element
      (style #f
             (list
               (alt-tag "div")
               (attributes
                 (list
                   (cons 'data-ct-node "1")
                   (cons 'data-activity-id (mk-id unique-id))
                   (cons 'data-resources
                         (jsexpr->string
                          (make-hash
                           (list (cons 'path
                                       (mk-resource "p" "rw" unique-id
                                                    (make-hash (list (cons 'reviews review-count)))))
                                 (cons 'blob (mk-resource "b" "rw" unique-id (make-hash)))))))
                   (cons 'data-parts (jsexpr->string (pairs->json (parts-steps data))))
                   (cons 'data-type "code-assignment")
                   (cons 'data-args (jsexpr->string
                      (make-hash
                        (list
                          (cons 'name name)
                          (cons 'codeDelimiters (pairs->json
                                                 (append (parts-code-delimiters data) (list (cons 'code "\n")))))
                          (cons 'parts (pairs->json (parts-part-names data)))))))))))
       "")))




(define-syntax-rule (include elt ...)
  (holder (list elt ...)))


(define-syntax-rule (journey unique-id)
  (current-id-prefix unique-id))
