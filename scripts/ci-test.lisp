;;; CI: run tests
(load "scripts/ci-setup.lisp")

(ql:quickload :nba-highlights-bot/test)
(asdf:test-system :nba-highlights-bot)
