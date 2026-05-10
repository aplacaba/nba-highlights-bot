(in-package :nba-highlights-bot/tests)

(def-suite commands-tests :in nba-tests
  :description "Tests for command handlers")
(in-suite commands-tests)

(test (format-results-empty :suite commands-tests)
  "Formatting empty results returns no-highlights message."
  (multiple-value-bind (msg keyboard) (nba-highlights-bot::format-results nil)
    (is (string= "No highlights found." msg))
    (is (null keyboard))))

(test (format-results-single :suite commands-tests)
  "Formatting a single result returns title text and keyboard."
  (let ((videos (list (cons "Lakers vs Celtics" "https://youtube.com/watch?v=abc"))))
    (multiple-value-bind (msg keyboard) (nba-highlights-bot::format-results videos)
      (is (search "Lakers vs Celtics" msg))
      (is (not (null keyboard))))))

(test (handle-help-returns-text :suite commands-tests)
  "Help handler returns a string containing command descriptions."
  (let ((help (nba-highlights-bot:handle-help)))
    (is (stringp help))
    (is (search "/today" help))
    (is (search "/yesterday" help))
    (is (search "/help" help))))

(test (handle-team-unknown :suite commands-tests)
  "Unknown team returns an error message with no keyboard."
  (multiple-value-bind (msg keyboard) (nba-highlights-bot:handle-team "foobar")
    (is (search "Unknown team" msg))
    (is (null keyboard))))
