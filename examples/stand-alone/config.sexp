;; -*- mode:lisp -*-
(
 ;; mysql setting
 (db-host . "localhost") 
 (db-name . "blog") 
 (db-user . "root") 
 (db-pass . "") 
 (db-type . :mysql)
 ;; 
 (static-url . "http://localhost/resources")
 (blog-port . 4242)
 (blog-url . "http://localhost:4242") ; will be reduced because can be produced by protocol and host and port and root-path
 (blog-host . "localhost:4242")
 (blog-title . "CategoL")
 (category-delimiter . "::")
 (root-path . "/")
 (default-count . 3)
 (rss-count . 20)
 (recent-count . 5)
 (uploaded-directory . "/tmp/categol/uploaded/") ; must to be changed!!
 )