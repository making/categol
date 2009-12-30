;; -*- mode:lisp -*-
(
 (header . ((:h1 (:a :href *root-path* (:img :src (img-src "categol-logo.png"))))))
 (side . ((:div
           :id "navi"
           (:h3 "MENU")
           (:ul
            (:li (:a :href *root-path* "top"))
                        (if (loginedp) 
                            (progn
                              (cl-who:htm (:li (:a :href (concatenate 'string (create-entry-create-url) +category+
                                                                      (format nil "/~{~a~^/~}/" 
                                                                              (get-category-list-from-path-info (path-info))
                                                                              ))
                                                   (cl-who:str +create+))))
                              (cl-who:htm (:li (:a :href (create-logout-url)  (cl-who:str +logout+))))
                              )
                            (progn
                              (cl-who:htm (:li (:a :href (create-login-url) (cl-who:str +login+))))
                              )
                            )
                        )
           )
          ))
 (footer . ((:p "powered by " 
                (:img :src (img-src "categol-logo-mini.png")) 
                " ver " (cl-who:str categol-system:*categol-version*)
                " on " 
                (:a :href "http://weitz.de/hunchentoot/" 
                    (:img :src (img-src "hunchentoot10.png"))))
            ))
 )