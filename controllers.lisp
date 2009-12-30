(in-package :categol)
;;

(defmacro with-authentication (&body body)
  "unless authenticated then redirect to login page"
  `(if (loginedp)
        (progn
          ,@body
          )
        (when-hunchentoot ()
          (hunchentoot:redirect (create-login-url) :host *blog-host*)
          )
        )
  )

(defmacro define-crud-dispatcher (target) 
  (let ((root-string (gensym))
        (root (gensym))
        (set-from-sexp `(when-hunchentoot ()
                          (setf (hunchentoot:session-value +session-from-key+) (append (list ',target) path-info))
                          ))
        )
    `(defun ,(read-from-string (format nil "~a-dispatch-controller" target)) 
         (path-info)
       (let* ((,root-string (car path-info))
              (,root (if (stringp ,root-string) (read-from-string (format nil "~a::~a" :categol ,root-string)) ,root-string))
              )
         (case ,root
           (view (,(read-from-string (concatenate 'string +view+ "-" 
                                                  (symbol-name target)))
                   (cdr path-info)))
           (edit ,set-from-sexp
                 (with-authentication                   
                   (,(read-from-string (concatenate 'string +edit+ "-" 
                                                    (symbol-name target)))
                     (cdr path-info))))
           (create ,set-from-sexp
                   (with-authentication                      
                     (,(read-from-string (concatenate 'string +create+ "-" 
                                                      (symbol-name target)))
                       (cdr path-info))))
           (delete ,set-from-sexp
                   (with-authentication
                     (,(read-from-string (concatenate 'string +delete+ "-" 
                                                      (symbol-name target)))
                       (cdr path-info))))
           (t (,(read-from-string (concatenate 'string +view+ "-" 
                                               (symbol-name target)))
                (cdr path-info)))
           
           )
         )
       )
    ))

;; entry-dispatch-controller
(define-crud-dispatcher entry)

(defun blog-dispatch-controller (&optional (path-info (path-info)))
  (let* ((path-info (mapcar #'hunchentoot:url-decode path-info))
         (root-string (car path-info))
         (root (if (stringp root-string) (read-from-string (format nil "~a::~a" :categol root-string)) root-string))
         )
    (when-hunchentoot () 
      (hunchentoot:log-message :info "~a" path-info)
      (unless hunchentoot:*session*
        (hunchentoot:start-session)
        )
      (hunchentoot:log-message :info "~a login=~a max-time=~a agent=~a remote=~a" 
                               hunchentoot:*session* 
                               (loginedp)
                               (hunchentoot:session-max-time hunchentoot:*session*)
                               (hunchentoot:session-user-agent hunchentoot:*session*)
                               (hunchentoot:session-remote-addr hunchentoot:*session*)
                               )
      )
    (case root
      ((page category) (print 1)(view-entry path-info))
      ((login) (print 2)(login path-info))
      ((logout) (print 3)(logout path-info))
      ((rss) (print 4)(entry-rss path-info))
      (t (print 5)(entry-dispatch-controller (cdr path-info)))
      )
    )
  )
