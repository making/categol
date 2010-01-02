(in-package :categol)

(defun default-header ()
  (cl-who:with-html-output (*standard-output*) 
    (:h1 (:a :href *root-path* (:img :src (img-src "categol-logo.png"))))    
    )
  )

(defun default-footer ()
  (cl-who:with-html-output (*standard-output*) 
    (:p "powered by " 
	(:a :href "http://github.com/making/categol" 
	    (:img :src (img-src "categol-logo-mini.png")) )
	" ver " (cl-who:str categol-system:*categol-version*)
	" on " 
	(:a :href "http://weitz.de/hunchentoot/" 
	    (:img :src (img-src "hunchentoot10.png"))))
    )
  )

(defun menu ()
  (cl-who:with-html-output (*standard-output*) 
    (:h3 "Menu")
    (:ul
     (:li (:a :href *root-path* "top"))
     (if (loginedp) 
	 (progn
	   (cl-who:htm (:li (:a :href  (format nil "~a~a/~{~a~^/~}/" 
					       (create-entry-create-url) +category+
					       (get-category-list-from-path-info (path-info))
					       )
				(cl-who:str +create+))))
	   (cl-who:htm (:li (:a :href (create-logout-url)  (cl-who:str +logout+))))
	   )
	 (progn
	   (cl-who:htm (:li (:a :href (create-login-url) (cl-who:str +login+))))
	   )
	 )
     )
    (values)
    )
  )

(defun recently-posts (&optional (count *recent-count*)) 
  (cl-who:with-html-output (*standard-output*) 
    (:h3 "Recently Posts")
    (:ul
     (multiple-value-bind (entry-list)
	 (get-entry-list :count count) 
       (loop for entry in entry-list do
	   (cl-who:htm (:li (:a :href (create-entry-view-url (id-of entry) (title-of entry)) (cl-who:str (title-of entry)))))
	    )
       )
     )
    (values)
    )
  )