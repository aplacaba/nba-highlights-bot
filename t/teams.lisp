(in-package :nba-highlights-bot/tests)

(deftest resolve-full-name
  (testing "Resolve full team name like 'lakers'"
    (ok (string= "Los Angeles Lakers"
                 (nba-highlights-bot:resolve-team "lakers")))))

(deftest resolve-abbreviation
  (testing "Resolve abbreviation like 'lal'"
    (ok (string= "Los Angeles Lakers"
                 (nba-highlights-bot:resolve-team "lal")))))

(deftest resolve-city
  (testing "Resolve city name like 'boston'"
    (ok (string= "Boston Celtics"
                 (nba-highlights-bot:resolve-team "boston")))))

(deftest case-insensitive
  (testing "Resolution is case-insensitive"
    (ok (string= "Los Angeles Lakers"
                 (nba-highlights-bot:resolve-team "LAKERS")))
    (ok (string= "Los Angeles Lakers"
                 (nba-highlights-bot:resolve-team "Lakers")))))

(deftest unknown-team
  (testing "Returns NIL for unknown team"
    (ok (null (nba-highlights-bot:resolve-team "foobar")))))

(deftest whitespace-trimmed
  (testing "Leading/trailing whitespace is ignored"
    (ok (string= "Los Angeles Lakers"
                 (nba-highlights-bot:resolve-team "  lakers  ")))))
