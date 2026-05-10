;;; CI: compile system and fail on warnings
(load "scripts/ci-setup.lisp")

(let ((fail nil))
  (handler-bind ((warning (lambda (c)
                             (setf fail t)
                             (format t "WARNING: ~A~%" c)
                             (muffle-warning))))
    (ql:quickload :nba-highlights-bot))
  (when fail
    (format t "FAIL: Compilation produced warnings~%")
    (sb-ext:exit :code 1)))

(format t "OK: Compilation clean~%")
