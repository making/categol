(in-package :categol)

(defmacro when-hunchentoot ((&key (if-not "")) &body body)
  "useful for debug in repl"
  `(if (boundp 'hunchentoot:*request*) (progn ,@body) ,if-not)
  )

(defun h (str)
  (hunchentoot:escape-for-html str)
  )

(defun md5 (str)
  (format nil "~(~{~2,'0X~}~)" (map 'list #'identity (md5:md5sum-sequence str)))
  )

;; url getter
(defun create-entry-view-url (id)
  (format nil "~a~a/~a/~a/~a/" *root-path* +entry+ +view+ +id+ id)
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
