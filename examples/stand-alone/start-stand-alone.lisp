(in-package :cl-user)
(defpackage :categol-stand-alone
  (:use :cl :categol)
  (:export :start)
  )
(in-package :categol-stand-alone)

(warn "load!!")
(defun start ()
  (categol:setup)
  (setq hunchentoot:*hunchentoot-default-external-format*
    (flex:make-external-format :utf-8 :eol-style :lf))
  (setq hunchentoot:*default-content-type* "text/html; charset=utf-8")
  (setq hunchentoot:*dispatch-table*
    (list 
     (hunchentoot:create-regex-dispatcher "^/.*$" 
                                          'categol:blog-dispatch-controller)
     )
    )
  (values)
  )