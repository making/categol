(in-package :categol)

;; helpers
(defun get-body (entry)
  (let ((kind (read-from-string (format nil "~a::~a" :categol (kind-of entry)))))
    (case kind
      (html (body-of entry))
      (markdown 
       ;;       (with-output-to-string (out)
       ;;         (cl-markdown:markdown 
       (body-of entry) ; latest cl-markdown includs bug??
       ;;          :stream out)
       ;;         )
       )
      (wiki (body-of entry))
      (sexp (parse-sexp-string 
             (body-of entry)))
      )
    )
  )

(defun category-string-list->string (category-list &optional (delimiter *category-delimiter*))
  (let ((fmt (concatenate 'string "~{~a~^" delimiter "~}")))
    (format nil fmt category-list)
    )
  )

(defun category-list->string (category-list &optional (delimiter *category-delimiter*))
  (let ((lst (sort category-list #'(lambda (x y) (< (sequence-of x) (sequence-of y)))))
        )
    (category-string-list->string (mapcar #'(lambda (x) (name-of x)) lst) delimiter)
    )
  )

(defun category-list->header (category-list &optional (delimiter *category-delimiter*))
  (let* ((lst (sort category-list #'(lambda (x y) (< (sequence-of x) (sequence-of y)))))
         (string-list (mapcar #'name-of lst))
         (fmt (concatenate 'string "~{~a~^" delimiter "~}"))
         )
    (format nil fmt (mapcar #'(lambda (x) (format nil +category-header-format+ 
                                                  *root-path*
                                                  +category+
                                                  (subseq string-list 0 (1+ (sequence-of x)))
                                                  (name-of x))) lst))
    )  
  )

(defun category-string-list->header (category-list 
                                     &optional (delimiter *category-delimiter*))
  (let* ((fmt (concatenate 'string "~{~a~^" delimiter "~}"))
         (size (length category-list))
         )
    (format nil fmt (mapcar #'(lambda (x) (format nil +category-header-format+  
                                                  *root-path*
                                                  +category+
                                                  x
                                                  (car (last x))
                                                  )) 
                            (loop for i from 1 to size 
                               :collect (subseq category-list 0 i))
                            ))
    )  
  )

;; crud pages of entry
(defun view-entry (path-info)
  (let* (
         (id-position (position +id+ path-info :test #'string=))
         (title-position (position +title+ path-info :test #'string=))
         (page-position (position +page+ path-info :test #'string=))
         (entry (if id-position (elt path-info (1+ id-position))))
         (title (if title-position (elt path-info (1+ title-position))))
         (category (get-category-list-from-path-info path-info))
         (page (if page-position (elt path-info (1+ page-position))))
         (headerp nil)
         )
    (declare (ignore title))
    (if page (setf page (read-from-string page)))

    (multiple-value-bind (entry-list total-pages)
        (get-entry-list :entry entry :page page :category category)
      (setq headerp (or (= (length entry-list) 1)
                        (not (null category))))
      (with-blog-layout (:css (list (js-ref "prettify/prettify.css") 
                                    (css-ref "pre.css"))
                              :js (mapcar #'js-ref '("prettify/prettify.js"
                                                     "prettify/lang-lisp.js"))
                              :onload "prettyPrint()"
                         )
        (if (and headerp entry-list (category-of (car entry-list)))
            (cl-who:htm (:h2 :class "header"
                             (cl-who:str (if category 
                                             (category-string-list->header category)
                                             (category-list->header (mapcar #'car (category-of (car entry-list)))))))))
        (:dl :class "main-contents"
             (loop for entry in entry-list
                do (cl-who:htm (:dt (:a :href (create-entry-view-url (id-of entry))
                                        (cl-who:str (h (title-of entry)))) )
                               (:dd (cl-who:str 
                                     (get-body entry)
                                     )
                                    (:div 
                                     :class "edit-menu"
                                     (:div 
                                      :class "edit"
                                      "[" (:a :href (create-entry-edit-url (id-of entry)) "edit") "]"
                                      )
                                     (:div :class "no-float")
                                     )
                                    (:div :class "date" 
                                          (:p
                                           "作成：" 
                                           (cl-who:str (h (created-at-of entry)))
                                           "&nbsp;"
                                           "更新："
                                           (cl-who:str (h (updated-at-of entry)))
                                           (:br)
                                           "Category: "
                                           (cl-who:str (category-list->header  (mapcar #'car (category-of entry))))
                                           )
                                          )
                                    )
                               ))
             )
        ;; paging
        (when (and (integerp total-pages)
                   (> total-pages 1))
          (cl-who:htm (:ul
                       :class "pages"
                       (loop for i from 1 to total-pages
                          do (cl-who:htm (:li (if (= (if (integerp page) page 1) i)
                                                  (cl-who:htm (:strong (cl-who:str i)))
                                                  (cl-who:htm (:a :href (create-page-url i category) (cl-who:str i)))
                                                  ))))
                       )
                      )      
          )
        )
      )
    )
  )

(defun edit-entry (path-info)
  (let* ((id (cadr path-info))
         (entry (car (get-entry-list :entry id))))

    (when-hunchentoot ()
      (if (null entry) (hunchentoot:redirect *root-path* :host *blog-host*))
      (when (do-action-p path-info)
        ;; update db
        (update-entry-from-plist entry ($post))
        (hunchentoot:redirect (create-entry-edit-url id) :host *blog-host*)
        )
      )

    (with-blog-layout (:indent nil)
      (:div 
       :class "edit-form"
       (:h2 (:a :href (create-entry-view-url id)
                (cl-who:str (title-of entry))
                ))
       (:form 
        :action (concatenate 'string (create-entry-edit-url id) +do-action+)
        :method :post
        :name "edit-form"
        (:ul
         (:li
          (:label :for "field-title" :class "desc" "title")
          (:div
           (:input :name "title" :id "field-title" :type "text" :class "field text medium" 
                   :value (h (title-of entry)))
           )
          )
         (:li
          (:label :for "field-category" :class "desc" "category")
          (:div
           (:input :name "category" :id "field-category" :type "text" 
                   :class "field text medium" 
                   :value (h (category-list->string 
                              (mapcar #'car (category-of entry)))))
           )
          )
         (:li
          (:label :for "field-id" :class "desc" "id")
          (:div
           (:input :name "id" :id "field-id" :type "text" :class "field text medium" :disabled "disabled"
                   :value (id-of entry))
           )
          )
         (:li
          (:label :for "field-body" :class "desc" "body")
          (:div
           (:textarea 
            :name "body"
            :id "field-body"
            :class "field textarea medium"
            (cl-who:str (body-of entry)))
           )
          )
         (:li
          (:label :for "field-kind" :class "desc" "kind")
          (:select
           :name "kind"
           :id "field-kind"
           :class "field select medium"
           (loop for kind in *blog-kinds* do	     	      
                (if (string= kind (h (kind-of entry)))
                    (cl-who:htm (:option :selected "selected" (cl-who:str kind)))
                    (cl-who:htm (:option (cl-who:str kind)))
                    )
                )
           )
          )
         (:li
          (:label :for "field-created-at" :class "desc" "created_at")
          (:div
           (:input :name "created-at" :id "field-created-at" :type "text" :class "field text medium" 
                   :value (h (created-at-of entry)))
           )
          )
         (:li
          (:label :for "field-updated-at" :class "desc" "updated_at")
          (:div
           (:input :name "updated-at" :id "field-updated-at" :type "text" :class "field text medium";;  :disabled "disabled"
                   :value (h (updated-at-of entry)))
           )
          )
         (:li
          :class "buttons"	  
          (:input :class "button-text submit" :type "submit" :value "Submit")
          )	 
         )
        )
       )
      )
    )
  )

(defun create-entry (path-info)
  (let* ()
    (when (do-action-p path-info)
      (let ((new-entry (make-instance 'entry  :id nil :created-at (current-date-time))))
        (update-entry-from-plist new-entry ($post))
        )
      (hunchentoot:redirect *root-path* :host *blog-host*)
      )
    (with-blog-layout (:indent nil)
      (:div 
       :class "edit-form"
       (:h2 "New Entry")
       (:form 
        :action (concatenate 'string (create-entry-create-url) +do-action+)
        :method :post
        :name "edit-form"
        (:ul
         (:li
          (:label :for "field-title" :class "desc" "title")
          (:div
           (:input :name "title" :id "field-title" :type "text" :class "field text medium" 
                   :value ""
                   )
           )
          )
         (:li
          (:label :for "field-category" :class "desc" "category")
          (:div
           (:input :name "category" :id "field-category" :type "text" 
                   :class "field text medium" 
                   :value (cl-who:str (let ((category-list (get-category-list-from-path-info path-info)))
                                        (if category-list (category-string-list->string category-list) "")
                                        )))
           )
          )	 
         (:li
          (:label :for "field-body" :class "desc" "body")
          (:div
           (:textarea 
            :name "body"
            :id "field-body"
            :class "field textarea medium"
            "")
           )
          )
         (:li
          (:label :for "field-kind" :class "desc" "kind")
          (:select
           :name "kind"
           :id "field-kind"
           :class "field select medium"
           (loop for kind in *blog-kinds* do	     	      
                (cl-who:htm (:option (cl-who:str kind)))
                )
           )
          )	 
         (:li
          :class "buttons"	  
          (:input :class "button-text submit" :type "submit" :value "Submit")
          )	 
         )
        )
       )
      )
    )
  )

(defun delete-entry (path-info)
  (let* ((id-position (position +id+ path-info :test #'string=))
         (entry-id (if id-position (elt path-info (1+ id-position)) ""))
         )
    (when-hunchentoot ()
      (hunchentoot:log-message :info "del pos=~a id=~a" id-position entry-id)
      )
    (when (do-action-p path-info)
      (delete-entry-from-id (parse-integer entry-id))
      )
    (when-hunchentoot ()
        (hunchentoot:redirect *root-path* :host *blog-host*)
      )
    ))



;; login
(defun authenticate (name password)
  (let ((user (car (get-user :name name :password (md5 password)))))
    (when user
      (when-hunchentoot ()
        (unless (hunchentoot:session-value +session-user-key+)
          (setf (hunchentoot:session-value +session-user-key+) user)
          (hunchentoot:log-message :info "authenticate -> ~a" hunchentoot:*session*)
          )  
        (hunchentoot:log-message :info "user -> ~a ~a" user (name-of user))
        )
      user
      )
    )
  )

(defun login (&optional path-info)
  (when (do-action-p path-info)
    (when (authenticate ($post "name") ($post "password"))
      (when-hunchentoot ()
        (unwind-protect 
             (hunchentoot:redirect (format nil "~a~{~a~^/~}/" *root-path*
                                           (hunchentoot:session-value +session-from-key+)) :host *blog-host*)
          
          (setf (hunchentoot:session-value +session-from-key+) nil)
          )
        )
      )
    )
  (with-blog-layout ()
    (:div 
     :class "edit-form"
     (:h2 "login")
     (if (do-action-p path-info)
         (cl-who:htm (:p :style "color:red" "login failed!!"))
         )
     (:form 
      :action +do-action+
      :method :post
      :name "edit-form"
      (:ul
       (:li
        (:label :for "field-name" :class "desc" "name")
        (:div
         (:input :name "name" :id "field-name" :type "text" :class "field text medium" 
                 :value "")
         )
        )
       (:li
        (:label :for "field-password" :class "desc" "password")
        (:div
         (:input :name "password" :id "field-password" :type "password" 
                   :class "field text medium" 
                   :value "")
         )
        )
       (:li
        :class "buttons"	  
        (:input :class "button-text submit" :type "submit" :value "Submit")
        )	       
       )
      )
     )
    ))

;; logout
(defun logout (&optional path-info)
  (declare (ignore path-info))
  (when-hunchentoot ()
    (let ((user (hunchentoot:session-value +session-user-key+)))      
      (hunchentoot:log-message :info "logout -> ~a ~a" user (and user (name-of user)))
      )
    (setf (hunchentoot:session-value +session-user-key+) nil)    
    (hunchentoot:redirect *root-path* :host *blog-host*)
    )
  )

;; RSS
(defun entry-rss (path-info)
  (let* ((category (get-category-list-from-path-info path-info))
         )
    (multiple-value-bind (entry-list)
        (get-entry-list :category category :count *rss-count*) 
      (cl-who:with-html-output-to-string (*standard-output* nil :indent t 
                                                            :prologue "<?xml version='1.0' encoding='utf-8'?>") 
        (:rss :version 1 (:channel (:title "Categol")
                                   (:description "hogehoge")
                                   (:link (cl-who:str *blog-url*))
                                   )
              (loop for entry in entry-list do
                   (cl-who:htm (:item (:title (cl-who:str (title-of entry)))
                                      (:link (cl-who:str (concatenate 'string *blog-url* (create-entry-view-url (id-of entry)))))
                                      (:description "<![CDATA[
" (cl-who:str (body-of entry)) "]]>")
                                      ))
                   )
              )
        )
      )
    )
  )
