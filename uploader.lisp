(in-package :categol)

;; mainly copied from hunchentoot-test

(defun uploader ()
  (cl-who:with-html-output (*standard-output*) 
    (:h3 "Uploader")
    (:form :method :post :enctype "multipart/form-data" :action (create-uploaded-create-do-url)
	   (:p "file: "
	       (:input :type :file
		       :name +file+)	       
	       )	   
	   (:p
	    (when-hunchentoot ()
	      (cl-who:htm (:input :type :hidden :name +from+ :value (create-session-from-url)))
	      )
	    (:input :type :submit :value "Upload")
	    ))
    )
  )

(defun uploaded-gallery ()
  (when *uploaded-files*
    (cl-who:with-html-output (*standard-output*) 
      (:p
       (:table :border 1
	       (:tr (:th :colspan 4 "Uploaded files"))
	       (loop for path in *uploaded-files*
		  for counter from 1
		  do
		    (let* ((file-name (format nil "~a.~a" (pathname-name path) (pathname-type path)))
			   (file-href (create-uploaded-view-url file-name))
			   (from (create-session-from-url))
			   )
		      (cl-who:htm
		       (:tr (:td (cl-who:str counter))
			    (:td (:a :href file-href
				     (:img :src file-href :width "50")))
			    (:td (str (ignore-errors
					(with-open-file (in path)
					  (file-length in))))
				 "&nbsp;Bytes")
			    (:td (:form :method :post :action (create-uploaded-delete-do-url file-name)
					(:input :type :hidden :name +from+ :value from)
					(:input :type :submit :value "Delete")
					))
			    ))))
	       )
       )
      )
    )
  (values)
  )

(defun create-uploaded-file (post-parameter)
  (when (and post-parameter
	     (listp post-parameter))
      (destructuring-bind (path file-name content-type)
          post-parameter
	(declare (ignore content-type))
	(hunchentoot:log-message :info "upload path=~a file-name=~a" path file-name)
	(sb-thread:with-mutex (*uploaded-files-mutex*)
	  (hunchentoot:log-message :info "lock mutex=~a" *uploaded-files-mutex*)
	  (let ((new-path nil))
	    ;; strip directory info sent by Windows browsers
	    (when (search "Windows" (hunchentoot:user-agent) :test 'char-equal)
	      (setq file-name (cl-ppcre:regex-replace ".*\\\\" file-name "")))
	    (setq new-path (make-pathname :name (format nil "~a-~a~a" +uploaded-file-prefix+ 
							(get-universal-time)
							(+ 100 (random 900)) ; tekitou
							)
					  :type (pathname-type (pathname  file-name))
					  :defaults *uploaded-directory*))
	    (rename-file path (ensure-directories-exist new-path))
	    (push new-path *uploaded-files*))
	  ) ; end of mutex lock
	)
      )
  (values)
  )

(defun delete-uploaded-file (file-name)
  (sb-thread:with-mutex (*uploaded-files-mutex*)
    (when (file-exists-p file-name)
      (ignore-errors (delete-file file-name))
      (reset-uploaded-files)
      )
    )
  (values)
  )
