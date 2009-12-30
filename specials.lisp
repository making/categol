(in-package :categol)

(defmacro defconstant+ (name value &optional doc)
  `(defconstant ,name (if (boundp ',name) (symbol-value ',name) ,value)
     ,@(when doc (list doc))))

(defvar *processes-mutex* (sb-thread:make-mutex))
(defvar *connection*)

;; blog
(defparameter *blog-kinds* '("html" "markdown" "wiki"));; "sexp" "rich"))
(defparameter *special-char-bangs* '(#\Space #\Tab #\Backspace #\Rubout #\Return #\Linefeed #\Page #\Newline))

;; constant
(defconstant+ +config-file+ "config.sexp")
(defconstant+ +parts-file+ "parts.sexp")
(defconstant+ +entry+ "entry")
(defconstant+ +login+ "login")
(defconstant+ +logout+ "logout")

(defconstant+ +create+ "create")
(defconstant+ +view+ "view")
(defconstant+ +edit+ "edit")
(defconstant+ +delete+ "delete")
(defconstant+ +id+ "id")

(defconstant+ +title+ "title")
(defconstant+ +page+ "page")
(defconstant+ +category+ "category")
(defconstant+ +do-action+ "do")
(defconstant+ +session-user-key+ :logined)
(defconstant+ +session-from-key+ :from)

(defconstant+ +category-header-format+ "<span class=\"category\"><a href=\"~a~a/~{~a~^/~}/\">~a</a></span>")


(defvar *header-html*)
(defvar *side-html*)
(defvar *footer-html*)

;; in config file
(defvar *static-url*)
(defvar *blog-url*)
(defvar *blog-host*)
(defvar *category-delimiter*)
(defvar *root-path*)
(defvar *default-count*)
(defvar *rss-count*)
