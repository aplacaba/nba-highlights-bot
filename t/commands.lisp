(in-package :nba-highlights-bot/tests)

(deftest format-results-empty
  (testing "Formatting empty results returns no-highlights message"
    (multiple-value-bind (msg keyboard) (nba-highlights-bot::format-results nil)
      (ok (string= "No highlights found." msg))
      (ok (null keyboard)))))

(deftest format-results-single
  (testing "Formatting a single result returns title text and keyboard"
    (let ((videos (list (cons "Lakers vs Celtics" "https://youtube.com/watch?v=abc"))))
      (multiple-value-bind (msg keyboard) (nba-highlights-bot::format-results videos)
        (ok (search "Lakers vs Celtics" msg))
        (ok (not (null keyboard)))))))

(deftest handle-help-returns-text
  (testing "Help handler returns a string containing command descriptions"
    (let ((help (nba-highlights-bot:handle-help)))
      (ok (stringp help))
      (ok (search "/today" help))
      (ok (search "/yesterday" help))
      (ok (search "/help" help)))))

(deftest handle-team-unknown
  (testing "Unknown team returns an error message with no keyboard"
    (multiple-value-bind (msg keyboard) (nba-highlights-bot:handle-team "foobar")
      (ok (search "Unknown team" msg))
      (ok (null keyboard)))))
