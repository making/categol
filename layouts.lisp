(in-package :categol)

(defun set-default-html ()
  (config-value-bind (+parts-file+ header side footer)
    (setq *header-html* header
          *side-html* side
          *footer-html* footer
          )
    )
  (values)
  )

(defun set-config-values ()
  (config-value-bind 
      (+config-file+
       static-url blog-url blog-host blog-title category-delimiter root-path
       default-count rss-count recent-count
       )
    (setq *static-url* static-url
          *blog-url* blog-url
          *blog-host* blog-host
	  *blog-title* blog-title
          *category-delimiter* category-delimiter
          *root-path* root-path
          *default-count* default-count
          *rss-count* rss-count
	  *recent-count* recent-count
          )    
    )
  (values)
  )

;; load defaults/config to compile
(set-default-html)
(set-config-values)


;;
(defmacro with-html (&body body)
  `(cl-who:with-html-output-to-string (*standard-output* nil :prologue nil :indent t)
     ,@body
     ))

(defmacro with-layout ((&key (header *header-html*) 
                             (side *side-html*) 
                             (footer *footer-html*)
                             (title "Hello World!")
                             (css-main (css-ref "main.css"))
                             (css nil)
                             (js nil)
                             (prologue nil)
                             (indent t)
                             (script nil)
                             (style nil)
                             (onload nil)
                             (more-head nil)
                             )		       
                       &body body)
  (let ((c (gensym))
        (j (gensym)))
    `(cl-who:with-html-output-to-string (*standard-output* nil :prologue ,prologue :indent ,indent)
       (:html 
        (:head (:title ,title)
               (:link :rel "stylesheet" :type "text/css" :href ,css-main)
               (loop for ,c in ,css do		    
                    (cl-who:htm (:link :rel "stylesheet" :type "text/css" :href ,c))
                    )
               (loop for ,j in ,js do
                    (cl-who:htm (:script :src ,j))
                    )
               (if ,script (cl-who:htm (:script (cl-who:str ,script))))
               (if ,style (cl-who:htm (:style (cl-who:str ,style))))
               ,more-head
               )     
        (:body 
         :onload (if ,onload ,onload "")
         (:div 
          :id "body"
          (:div
           :id "header"
           ,@header
           )
          (:div 
           :id "navigation"
           ,@side
           )
          (:div 
           :id "contents"
           ,@body
           )
          (:div
           :id "footer"
           ,@footer
           )
          )
         )
        )
       )
    ))

(defmacro with-blog-layout ((&key (header nil) 
                                  (indent t)
                                  (js nil)
                                  (css nil)
                                  (script nil)
                                  (style nil)
                                  (onload nil)
                                  (more-head nil)
                                  )
                            &body body)
  (let ((title *blog-title*))
    `(with-layout (:title 
                   ,title
                   :indent
                   ,indent
                   :header 
                   (,@*header-html*
                    ,@header
                    )
                   :js ,js
                   :css ,css
                   :script ,script
                   :style ,style
                   :onload ,onload
                   :more-head ,more-head
                   )
       ,@body
       )
    ))

