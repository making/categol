(in-package :categol)

(clsql:def-view-class entry ()
  ((id :accessor id-of
       :db-kind :key
       :db-constraints :auto-increment
       :type integer
       :initarg :id)
   (body :accessor body-of
         :type string
         :initarg :body)
   (title :accessor title-of
          :type (clsql:varchar 128)
          :initarg :title)   
   (kind :accessor kind-of
         :type (clsql:varchar 30)
         :initarg :type
         )
   (created-at :accessor created-at-of
               :type (clsql:varchar 128)
               :initarg :created-at
               )
   (updated-at :accessor updated-at-of
               :type (clsql:varchar 128)
               :initarg :updated-at
               )
   (category :accessor category-of
             :db-kind :join
             :db-info (:join-class entry-category
                                   :home-key id
                                   :foreign-key entry-id
                                   :target-slot category
                                   :set t
                                   ))
   ))

(clsql:def-view-class category ()
  ((id :accessor id-of
       :db-kind :key
       :db-constraints :auto-increment
       :type integer
       :initarg :id)
   (name :accessor name-of
         :type (clsql:varchar 64)
         :initarg :name
         )
   (sequence :accessor sequence-of
             :type integer
             :initarg :sequence)
   (entry :accessor entry-of
          :db-kind :join
          :db-info (:join-class entry-category
                                :home-key id
                                :foreign-key category-id
                                :target-slot entry
                                :set t
                                ))
   
   )  
  )

(clsql:def-view-class entry-category ()
  ((id :accessor id-of
       :db-kind :key
       :db-constraints :auto-increment
       :type integer
       :initarg :id)
   (entry-id :accessor entry-id-of
             :type integer
             :initarg :entry-id)
   (entry :accessor entry-of
          :db-kind :join
          :db-info (:join-class entry
                                :home-key entry-id
                                :foreign-key id
                                :retrieval :immediate))
   (category-id :accessor category-id-of
                :type integer
                :initarg :category-id)
   (category :accessor category-of
             :db-kind :join
             :db-info (:join-class category
                                   :home-key category-id
                                   :foreign-key id
                                   :retrieval :immediate))
   ))

(clsql:def-view-class user ()
  ((id :accessor id-of
       :db-kind :key
       :db-constraints :auto-increment
       :type integer
       :initarg :id)
   (name :accessor name-of
         :type (clsql:varchar 64)
         :initarg :name
         )
   (password :accessor password-of
         :type (clsql:varchar 64)
         :initarg :password
         )
   (administratorp :accessor administratorp-of
                   :type boolean
                   :initarg :administratorp)
   )  
  )

(defmethod to-string ((self entry))
  (with-slots (id body title kind created-at updated-at)
      self
    (format nil "~a[id=~a, body=~a, title=~a, kind=~a, created-at=~a, updated-at=~a]"
            self id body title kind created-at updated-at)
    )
  )
