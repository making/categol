(in-package :cl-user)

(defpackage :categol
  (:use :cl 
        :hunchentoot 
        :cl-who 
        :clsql 
        :cl-markdown
        )     
  ;; specials
  (:export :*static-url* 
           :*blog-url* 
           :*blog-host* 
           :*category-delimiter* 
           :*root-path* 
           :*default-count* 
           :*rss-count*
           )
  ;; utils
  (:export :when-hunchentoot 
           :h 
           :md5 
           :path-info 
           :loginedp 
           :do-action-p 
           :img-src 
           :css-ref 
           :js-ref 
           :$post
           :$get
           :$request
           :iso-date-time 
           :current-date-time 
           :parse-sexp-string
           :calc-offset
           :calc-total-page
           :config-value-bind
           )
  ;; entities
  (:export :entry :id-of :body-of :title-of :kind-of :created-at-of :updated-at-of :category-of :to-string
           :category :id-of :name-of :sequence-of :entry-of
           :entry-category :id-of :entry-id-of :entry-of :category-id-of :category-of
           :user :id-of :name-of :password-of :administratorp-of
           )
  ;; data-access
  (:export :get-last-inserted-id
           :get-category-id
           :get-entry-category-list-from-entry-id
           :get-entry-list-from-category
           :get-entry-list
           :get-user
           :update-entry-from-plist
           :delete-entry-from-id
           )
  ;; layouts
  (:export :with-html
           :with-layout
           :with-blog-layout
           )
  ;; pages
  (:export :get-body
           :category-string-list->string
           :category-list->string
           :category-list->header
           :category-string-list->header
           :view-entry
           :edit-entry
           :create-entry
           :delete-entry
           :authenticate
           :login
           :logout
           )
  ;; controllers
  (:export :with-authentication
           :blog-dispatch-controller
           )
  ;; setup
  (:export :setup
           )
  )

(pushnew :categol *features*)