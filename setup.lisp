(in-package :categol)

(defun setup-hunchentoot (&key (port 4242))
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
  (defvar *server* (hunchentoot:start (make-instance 'hunchentoot:acceptor :port port)))
  (values))

(defun setup-database (&key (host "localhost") (db "blog") (user "root") (pass "") (type :mysql))
  (unless (and (boundp '*connection*) *connection*)
    (setf *connection* (clsql:connect (list host db user pass) :database-type type :pool t))
    (when-hunchentoot () 
      (hunchentoot:log-message :info "setup database ~a" *connection*)))
  (values))

(defun setup-uploader (directory)
  (sb-thread:with-mutex (*uploaded-files-mutex*)
    (setq *uploaded-directory* (pathname directory))
    (reset-uploaded-files))
  (values))

;;;;
(defun setup ()
  (config-value-bind 
      (+config-file+
       blog-port
       db-host db-name db-user db-pass db-type
       uploaded-directory)
    (setup-hunchentoot :port blog-port)
    (setup-database :host db-host :db db-name :user db-user :pass db-pass :type db-type)    
    (setup-uploader uploaded-directory))
  (values))