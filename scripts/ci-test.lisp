;;; CI helper: run tests
(require :asdf)
(push (truename ".") asdf:*central-registry*)
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))

(ql:quickload :nba-highlights-bot/test)
(asdf:test-system :nba-highlights-bot)
