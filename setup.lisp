(in-package :categol)

(defun setup-hunchentoot ()
  ;; (setq hunchentoot:*hunchentoot-default-external-format*
  ;;   (flex:make-external-format :utf-8 :eol-style :lf))
  ;; (setq hunchentoot:*default-content-type* "text/html; charset=utf-8")
  ;; (setq hunchentoot:*dispatch-table*
  ;;   (list 
  ;;    (hunchentoot:create-regex-dispatcher "^/.*$" 'root-dispatch-controller)
  ;;    )
  ;;   )
  ;; (setf hunchentoot:*access-log-pathname* "./hunchentoot-access.log")
  ;; (setf hunchentoot:*message-log-pathname* "./hunchentoot-message.log")
  (config-value-bind (+config-file+ blog-port)
    (defvar *server* (hunchentoot:start (make-instance 'hunchentoot:acceptor :port blog-port)))
    )
  (values)
  )

(defun setup-database (&key (host "localhost") (db "blog") (user "root") (pass "") (type :mysql))
  (unless (and (boundp '*connection*) *connection*)
    (setf *connection* (clsql:connect (list host db user pass) :database-type type :pool t))
    (when-hunchentoot () 
      (hunchentoot:log-message :info "setup database ~a" *connection*)
      )
    )
  (values)
  )

;;;;

(defun setup ()
  (setup-hunchentoot)
  (config-value-bind 
      (+config-file+
       host db user pass type
       )
    (setup-database :host host :db db :user user :pass pass :type type)
    )
  (values)
  )