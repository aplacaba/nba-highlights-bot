(in-package :nba-highlights-bot/tests)

(def-suite teams-tests :in nba-tests
  :description "Tests for team name resolution")
(in-suite teams-tests)

(test (resolve-full-name :suite teams-tests)
  "Resolve full team name like 'lakers'."
  (is (string= "Los Angeles Lakers"
               (nba-highlights-bot:resolve-team "lakers"))))

(test (resolve-abbreviation :suite teams-tests)
  "Resolve abbreviation like 'lal'."
  (is (string= "Los Angeles Lakers"
               (nba-highlights-bot:resolve-team "lal"))))

(test (resolve-city :suite teams-tests)
  "Resolve city name like 'boston'."
  (is (string= "Boston Celtics"
               (nba-highlights-bot:resolve-team "boston"))))

(test (case-insensitive :suite teams-tests)
  "Resolution is case-insensitive."
  (is (string= "Los Angeles Lakers"
               (nba-highlights-bot:resolve-team "LAKERS")))
  (is (string= "Los Angeles Lakers"
               (nba-highlights-bot:resolve-team "Lakers"))))

(test (unknown-team :suite teams-tests)
  "Returns NIL for unknown team."
  (is (null (nba-highlights-bot:resolve-team "foobar"))))

(test (whitespace-trimmed :suite teams-tests)
  "Leading/trailing whitespace is ignored."
  (is (string= "Los Angeles Lakers"
               (nba-highlights-bot:resolve-team "  lakers  "))))
