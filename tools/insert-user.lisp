(require :categol)
(categol:config-value-bind 
    (categol:+config-file+
     host db user pass type
     )
  (categol::setup-database :host host :db db :user user :pass pass :type type)
  )
(clsql-sys:start-sql-recording)
(let ((name (elt *posix-argv* 1))
      (password (elt *posix-argv* 2))
      (administratorp (if (>= (length *posix-argv*) 4) (parse-integer (elt *posix-argv* 3)) 1)) ; administrator is default  
      )
  (categol:insert-user name password (plusp administratorp))
  )
(sb-ext:quit)
