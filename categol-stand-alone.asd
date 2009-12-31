(defpackage :categol-stand-alone-sysmtem
  (:use :asdf :cl)
  )
(in-package :categol-stand-alone-sysmtem)

(asdf:defsystem :categol-stand-alone
  :author "Toshiaki Maki <makingx@gmail.com>"
  :serial t
  :depends-on (:categol
               )
  :components 
  ((:module "examples/stand-alone"
            :components ((:file "start-stand-alone")
                         )
            )
   )
  )
