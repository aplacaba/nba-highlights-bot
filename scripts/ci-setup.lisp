;;; CI helper: compile system and fail on warnings
(require :asdf)
(push (truename ".") asdf:*central-registry*)
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))

(let ((fail nil))
  (handler-bind ((warning (lambda (c)
                             (setf fail t)
                             (format t "WARNING: ~A~%" c)
                             (muffle-warning))))
    (asdf:compile-system :nba-highlights-bot :force t))
  (when fail
    (format t "FAIL: Compilation produced warnings~%")
    (sb-ext:exit :code 1)))

(format t "OK: Compilation clean~%")
