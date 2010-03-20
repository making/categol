(in-package :categol)
;;
(clsql:enable-sql-reader-syntax)
(setf clsql:*default-caching* nil)

;; data-accsess
(defun retry-sql-access (condition)
  (when-hunchentoot ()
    (hunchentoot:log-message :warn "before ~a" *processes-mutex*)
    (sb-thread:with-mutex (*processes-mutex*)
      (hunchentoot:log-message :warn "in     ~a" *processes-mutex*)
      (let ((clsql:*connect-if-exists* :new))
        (hunchentoot:log-message :warn "error-id ~a" (clsql:sql-error-error-id condition))
        ;; (cond
        ;;   ((= (clsql:sql-error-error-id condition) 2006) 
        (hunchentoot:log-message :warn "restart ~a" condition)
        (setf *connection* nil)
        (setup)
        ;;  )
        ;; ((> (clsql:sql-error-error-id condition) 2000)
        ;;  (clsql:reconnect :database (clsql:sql-error-database condition))
        ;;  )
        ;; )
        (hunchentoot:log-message :warn "out    ~a" *processes-mutex*)
        (invoke-restart 'retry-sql-access)))))

(defmacro define-data-access (name (&rest args) &body body) 
  "define data access function with restart case"
  (let ((helper-name (read-from-string (format nil"%~a" name))))
    `(progn
       (defun ,helper-name (,@args) 
         ,@body)
       (defun ,name (&rest arg)
         ,(format nil "(~a ~a)" name args)
         (handler-bind ((clsql-sys:sql-database-data-error #'retry-sql-access))
           (restart-case (apply #',helper-name arg) 
             (retry-sql-access () 
               (progn 
                 (when-hunchentoot ()
                   (hunchentoot:log-message :info "(~a ~a)" ',helper-name arg))
                 (apply #',helper-name arg)))))))))

(define-data-access get-last-inserted-id (table)
  (car (clsql:select [id] :from table :flatp t :order-by '(([id] :desc)) 
                     :limit 1 :field-names nil :caching nil)))

(define-data-access get-category-id (name seq)
  (car (clsql:select [id] :from 'category :where [and [= [name] name] [= [sequence] seq]] 
                     :flatp t :limit 1 :caching nil :field-names nil)))

(define-data-access get-entry-category-list-from-entry-id (entry-id &key (caching nil))
  (clsql:select 'entry-category :where 
                [= [entry-id] entry-id] :flatp t :caching caching))
  

(define-data-access get-entry-list-from-category (category-list 
                                                  &key (page 1) (count *default-count*) (caching nil))
  (let ((category (car (last category-list)))
        (sequence (1- (length category-list)))
        (category-obj nil)
        (entry-list nil)
        (offset (calc-offset page count)))
    (setq category-obj (car (clsql:select 'category 
                                          :where [and [= [name] category] 
                                          [= [sequence] sequence]]
                                          :flatp t
                                          :caching caching
                                          :limit 1)))
    (if category-obj
        (progn 
          (setq entry-list (mapcar #'car (entry-of category-obj)))      
          (setf entry-list
                (sort entry-list #'(lambda (x y) (string> (updated-at-of x) 
                                                          (updated-at-of y)))))
          ;; not efficient!!
          (values 
           (handler-case (subseq entry-list 
                                 offset 
                                 (min (+ offset count) (length entry-list)))
             (error () nil)) ; entry-list
           (calc-total-page (length entry-list)) ; total-pages
           ))
        (values nil 0))))

(define-data-access get-entry-list (&key (entry nil) (page 1) (category nil) 
                                      (caching nil) (count *default-count*))
  "returns (values entry-list total-pages)"
  (if category 
      (%get-entry-list-from-category category :page page :count count :caching caching)

      (let ((common-args (list 'entry 
                               :where (if entry [= [id] entry] [> [id] 0])
                               :order-by '(([updated-at] :desc))
                               :flatp t
                               :caching caching)))
        (values 
         (apply #'clsql:select (append common-args (list :limit count :offset (calc-offset page count)))) ; entry-list
         (calc-total-page (car (apply #'clsql:select [count(*)] :from common-args))) ; total-pages
         ))))

(define-data-access get-user (&key (id nil) (name nil) (password nil) (caching t))
  (clsql:select 'user
                :where (cond (id [= [id] id]) 
                             ((and (stringp name) (stringp password))
                              [and [= [name] name] [= [password] password]])
                             (t [> [id] 0]))
                :flatp t
                :caching caching))

(define-data-access insert-user (name password administratorp)
  (clsql:update-records-from-instance (make-instance 'user :name name :password (md5 password) :administratorp administratorp)))

(define-data-access update-entry-from-plist (entry plist)
  "insert or update entry from plist"
  (let ((category (cdr (assoc +category+ plist :test #'string=)))
        (category-list (category-of entry)))
    (when-hunchentoot ()
      (hunchentoot:log-message :info "plist=~a" plist))
    (loop for p in plist do
         (let ((key (read-from-string (format nil "~a::~a" :categol (car p))))
               (value (cdr p)))
           (when (slot-exists-p entry key)
             (setf (slot-value entry key) 
                   (cond 
                     ((member 'integer (type-of value)) (parse-integer (string value)))
                     (t value))))))
    (setf (updated-at-of entry) nil) ; automatically update at mysql server
    ;; (unless (created-at-of entry) 
    ;;   (setf (created-at-of entry) (current-date-time)))
    ;; delete category
    (setq plist (remove +category+ plist :test #'(lambda (x y) (string= x (car y)))))
    (clsql:with-transaction ()
      ;; update entry
      (clsql:update-record-from-slots entry 
                                      (append (mapcar #'(lambda (x) (read-from-string (format nil "~a::~a" :categol (car x))))
                                                      plist
                                                      ) '(created-at)))
      (when-hunchentoot ()
        (hunchentoot:log-message :info "entry=~a" (to-string entry)))
      ;; update category
      (when-hunchentoot ()
        (let ((categories (cl-ppcre:split *category-delimiter* category))
              (entry-category-list (if (integerp (id-of entry)) 
                                       (get-entry-category-list-from-entry-id (id-of entry)))))
          (hunchentoot:log-message :info "entry-category=~a" entry-category-list)

          (loop for i from 0 to (1- (length categories))
             for c in categories
             do 
               (hunchentoot:log-message :info "category[~a]=~a" i c)
               (let ((cc (make-instance 'category :name c :sequence i))
                     (category-id nil)
                     (entry-id nil))
                 (handler-case 
                     (progn 
                       (clsql:update-records-from-instance cc))
                   ;; ignore error
                   (clsql-sys:sql-database-error () nil))
                 (handler-case
                     (progn
                       ;; if id is nil then use last-inserted-id
                       (setq entry-id (or (id-of entry) (get-last-inserted-id 'entry)))
                       (setq category-id (get-category-id c i))
                       ;; update entry-category
                       (clsql:update-records-from-instance 
                        (make-instance 'entry-category 
                                       :entry-id entry-id
                                       :category-id category-id)))
                   ;; ignore error
                   (clsql-sys:sql-database-error () nil))))
          ;; delete entry-category
          (hunchentoot:log-message :info "categories=~a" category-list)
          (let ((delete-list (remove categories category-list
                                     :test #'(lambda (x y) 
                                               (member (name-of (car y)) x :test #'string=)))))
            (loop for d in delete-list
               do
                 (hunchentoot:log-message :info "del=~a" (name-of (car d)))
                 (clsql:delete-records :from [entry_category] 
                                       :where [and [= [entry_id] (entry-id-of (cadr d))] 
                                       [= [category_id] (category-id-of (cadr d))]]))))))))

(define-data-access delete-entry-from-id (id)
  (when (integerp id)
    (clsql:delete-records :from [entry] :where [= [id] id])))

;;
(clsql:disable-sql-reader-syntax)