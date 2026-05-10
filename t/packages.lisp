(defpackage nba-highlights-bot/tests
  (:use :cl :fiveam)
  (:export :nba-tests
           :run-tests))

(in-package :nba-highlights-bot/tests)

(def-suite nba-tests
  :description "Test suite for NBA Highlights Bot")

(defun run-tests ()
  "Run all NBA Highlights Bot tests."
  (run! 'nba-tests))
