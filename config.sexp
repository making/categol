;; -*- mode:lisp -*-
(
 ;; mysql setting
 (host . "localhost") 
 (db . "blog") 
 (user . "root") 
 (pass . "") 
 (type . :mysql)
 ;; 
 (static-url . "http://localhost")
 (blog-port . 4242)
 (blog-url . "http://localhost:4242/blog") ; will be reduced because can be produced by protocol and host and port and root-path
 (blog-host . "localhost:4242")
 (category-delimiter . "::")
 (root-path . "/blog/")
 (default-count . 3)
 (rss-count . 20)
 )