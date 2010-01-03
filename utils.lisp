(in-package :categol)

(defmacro when-hunchentoot ((&key (if-not "")) &body body)
  "useful for debug in repl"
  `(if (boundp 'hunchentoot:*request*) (progn ,@body) ,if-not)
  )

(defun h (str)
  (if (stringp str) (hunchentoot:escape-for-html str))
  )

(defun md5 (str)
  (format nil "~(~{~2,'0X~}~)" (map 'list #'identity (md5:md5sum-sequence str)))
  )

;; url getter
(defun create-entry-view-url (id &optional (title nil))
  (format nil "~a~a/~a/~a/~a/~a" *root-path* +entry+ +view+ +id+ id
	  (if title (format nil "~a/~a/" +title+ (hunchentoot:url-encode title)) "")
	  )
  )

(defun create-entry-edit-url (id)
  (format nil "~a~a/~a/~a/~a/" *root-path* +entry+ +edit+ +id+ id)
  )

(defun create-entry-edit-do-url (id)
  (concatenate 'string (create-entry-edit-url id) +do-action+)
  )

(defun create-entry-create-url ()
  (format nil "~a~a/~a/" *root-path* +entry+ +create+)
  )

(defun create-entry-create-do-url ()
  (concatenate 'string (create-entry-create-url) +do-action+)
  )

(defun create-entry-delete-url (id)
  (format nil "~a~a/~a/~a/~a/" *root-path* +entry+ +delete+ +id+ id)
  )

(defun create-entry-delete-do-url (id)
  (concatenate 'string (create-entry-delete-url id) +do-action+)
  )

(defun create-page-url (page &optional (category nil))
  (format nil "~a~{~a~^/~}/" *root-path*
          (nconc  (list +page+ page) (if category (append (list +category+) category))))
  )

(defun create-login-url () 
  (concatenate 'string *root-path* +login+ "/")
  )

(defun create-logout-url () 
  (concatenate 'string *root-path* +logout+ "/")
  )

(defun create-uploaded-view-url (file-name)
  (concatenate 'string *root-path* +uploaded+ "/" +view+ "/" file-name)
  )

(defun create-uploaded-create-url ()
  (concatenate 'string *root-path* +uploaded+ "/" +create+)
  )

(defun create-uploaded-create-do-url ()
  (concatenate 'string (create-uploaded-create-url) "/" +do-action+)
  )

(defun create-uploaded-delete-url (file-name)
  (concatenate 'string *root-path* +uploaded+ "/" +delete+ "/" file-name)
  )

(defun create-uploaded-delete-do-url (file-name)
  (concatenate 'string (create-uploaded-delete-url file-name) "/" +do-action+)
  )

(defun create-session-from-url ()
  (when-hunchentoot ()
    (format nil "~a~{~a~^/~}/" *root-path* (hunchentoot:session-value +session-from-key+))
    )
  )

(defun create-rss-url (&optional (category-string-list nil))
  (format nil "~a~a/~a" *root-path* +rss+ 
          (if category-string-list (format nil "~a/~{~a~^/~}/" 
                                           +category+
                                           (mapcar #'hunchentoot:url-encode category-string-list)) "")
          )
  )

(defun create-rss-link-html (&optional (category-string-list nil))
  (format nil "<link rel=\"alternate\" type=\"application/rss+xml\" title=\"~a RSS Feed\" href=\"~a\" />"
          *blog-title*
          (create-rss-url category-string-list)
          )
  )

;;;;
(defun path-info ()
  (when-hunchentoot (:if-not '("blog" "title" "foo" "category" "lisp" "cl"))
    (split-sequence:split-sequence #\/ (hunchentoot:script-name*) :remove-empty-subseqs t)
    )
  )

(defun get-category-list-from-path-info (path-info)
  (let ((category-position (position +category+ path-info :test #'string=))) 
    (if category-position (subseq path-info (1+ category-position))))
  )

(defun loginedp ()
  (when-hunchentoot (:if-not t)
    (hunchentoot:session-value +session-user-key+)
    )
  )

(defun do-action-p (path-info)
  (string= (car (last path-info)) +do-action+)
  )

;; path getter of static file
(defun img-src (&rest fnames)
  (format nil "~a/images/~{~a~^/~}" *static-url* fnames)
  )
(defun css-ref (&rest fnames)
  (format nil "~a/css/~{~a~^/~}" *static-url* fnames)
  )
(defun js-ref (&rest fnames)
  (format nil "~a/js/~{~a~^/~}" *static-url* fnames)
  )

;; getter of request data
(defun $post (&optional (key nil))
  (when-hunchentoot ()
    (if key (hunchentoot:post-parameter key) (hunchentoot:post-parameters*))
    )
  )

(defun $get (&optional (key nil))
  (when-hunchentoot ()
    (if key (hunchentoot:get-parameter key) (hunchentoot:get-parameters*))
    )
  )

(defun $request (key)
  (when-hunchentoot ()
    (hunchentoot:parameter key)
    )
  )

(defun http-forbidden ()
  (when-hunchentoot ()
    (setf (hunchentoot:return-code*) hunchentoot:+http-forbidden+)
    )
  nil)

;; time
(defun iso-date-time (&optional (time (get-universal-time)))
  "Returns string with date + time according to ISO 8601."
  (multiple-value-bind
        (second minute hour date month year)
      (decode-universal-time time 0)
    (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
            year month date hour minute second)))

(defun current-date-time (&optional (time (get-universal-time)))
  (multiple-value-bind
        (second minute hour date month year)
      (decode-universal-time time)
    (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
            year month date hour minute second)))

;; for cl-who
(defun parse-sexp-string (str &key (indent nil))
  "slow ..."
  (handler-case 
      (eval `(cl-who:with-html-output-to-string
                 (*standard-output* nil :indent ,indent)
               ,@(read-from-string 
                  (format nil "(~{~a~})" 
                          (mapcar #'(lambda (x) (string-trim *special-char-bangs* x)) 
                                  (cl-ppcre:split "\\n" str)))
                  )
               ))
    (error (c) (format nil "invalid sexp!! -> ~a" c))
    ))

;; page
(defun calc-offset (page count)
  (if (and (integerp page) (plusp page)) 
      (* (1- page) count) 0)
  )

(defun calc-total-page (count-of-list &optional (count *default-count*))
  (multiple-value-bind (total-page)
      (ceiling (/ count-of-list count))
    total-page
    )
  )

;; load config
(defmacro config-value-bind ((fname &rest symbols) &body body)
  (let ((s (gensym "s"))
        (f (gensym "f"))
        )
    `(with-open-file (,f ,fname)
       (let* ((,s (read ,f))
              ,@(mapcar #'(lambda (x) `(,x (cdr (assoc (intern (string ',x)) ,s)))) symbols)
              )
         ,@body
         )
       )
    ))

;; list directory (from Practical Common Lisp!)
(defun component-present-p (value)
  (and value (not (eql value :unspecific))))

(defun directory-pathname-p  (p)
  (and
   (not (component-present-p (pathname-name p)))
   (not (component-present-p (pathname-type p)))
   p))

(defun pathname-as-directory (name)
  (let ((pathname (pathname name)))
    (when (wild-pathname-p pathname)
      (error "Can't reliably convert wild pathnames."))
    (if (not (directory-pathname-p name))
      (make-pathname
       :directory (append (or (pathname-directory pathname) (list :relative))
                          (list (file-namestring pathname)))
       :name      nil
       :type      nil
       :defaults pathname)
      pathname)))

(defun directory-wildcard (dirname)
  (make-pathname
   :name :wild
   :type #-clisp :wild #+clisp nil
   :defaults (pathname-as-directory dirname)))

(defun list-directory (dirname)
  (when (wild-pathname-p dirname)
    (error "Can only list concrete directory names."))
  (let ((wildcard (directory-wildcard dirname)))
    #+(or sbcl cmu lispworks)
    (directory wildcard)
    #+openmcl
    (directory wildcard :directories t)
    #+allegro
    (directory wildcard :directories-are-files nil)
    #+clisp
    (nconc
     (directory wildcard)
     (directory (clisp-subdirectories-wildcard wildcard)))
    #-(or sbcl cmu lispworks openmcl allegro clisp)
    (error "list-directory not implemented")
    )
  )

(defun file-exists-p (pathname)
  #+(or sbcl lispworks openmcl)
  (probe-file pathname)
  #+(or allegro cmu)
  (or (probe-file (pathname-as-directory pathname))
      (probe-file pathname))
  #+clisp
  (or (ignore-errors
        (probe-file (pathname-as-file pathname)))
      (ignore-errors
        (let ((directory-form (pathname-as-directory pathname)))
          (when (ext:probe-directory directory-form)
            directory-form))))
  #-(or sbcl cmu lispworks openmcl allegro clisp)
  (error "file-exists-p not implemented")
  )

(defun pathname-as-file (name)
  (let ((pathname (pathname name)))
    (when (wild-pathname-p pathname)
      (error "Can't reliably convert wild pathnames."))
    (if (directory-pathname-p name)
      (let* ((directory (pathname-directory pathname))
             (name-and-type (pathname (first (last directory)))))
        (make-pathname
         :directory (butlast directory)
         :name (pathname-name name-and-type)
         :type (pathname-type name-and-type)
         :defaults pathname))
      pathname)))

(defun walk-directory (dirname fn &key directories (test (constantly t)))
  (labels
      ((walk (name)
         (cond
           ((directory-pathname-p name)
            (when (and directories (funcall test name))
              (funcall fn name))
            (dolist (x (list-directory name)) (walk x)))
           ((funcall test name) (funcall fn name)))))
    (walk (pathname-as-directory dirname))))

(defun reset-uploaded-files ()
  (setq *uploaded-files* (nreverse (categol::list-directory categol::*uploaded-directory*)))
  )