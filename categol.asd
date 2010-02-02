(defpackage :categol-system
  (:use :asdf :cl)
  )
(in-package :categol-system)

(defvar *categol-version* "0.1.0"
  "the current version of CategoL"
  )
(export '*categol-version*)

(asdf:defsystem :categol
  :version #.*categol-version*
  :author "Toshiaki Maki <makingx@gmail.com>"
  :serial t
  :depends-on (:hunchentoot
               :cl-who
               :clsql
               :cl-markdown
               :split-sequence
               )
  :components ((:file "packages")
               (:file "specials")
               (:file "utils")
               (:file "entities")
               (:file "data-access")
               (:file "gadgets")
               (:file "layouts")
               (:file "uploader")
               (:file "pages")
               (:file "controllers")
               (:file "setup")
               )
  )
