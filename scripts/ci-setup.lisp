;;; Shared: load Quicklisp, register project
(require :asdf)
(push (truename ".") asdf:*central-registry*)
(let ((ql-setup (or (probe-file (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
                    (probe-file (merge-pathnames ".quicklisp/setup.lisp" (user-homedir-pathname))))))
  (unless ql-setup
    (error "Quicklisp not found"))
  (load ql-setup))
