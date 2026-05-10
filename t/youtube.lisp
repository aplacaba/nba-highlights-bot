(in-package :nba-highlights-bot/tests)

(def-suite youtube-tests :in nba-tests
  :description "Tests for YouTube API response parsing")
(in-suite youtube-tests)

(test (parse-empty-response :suite youtube-tests)
  "Parsing an empty items array returns nil."
  (let ((json "{\"items\":[]}"))
    (is (null (nba-highlights-bot::parse-search-response json)))))

(test (parse-single-video :suite youtube-tests)
  "Parsing a response with one video returns one (title . url) pair."
  (let ((json "{\"items\":[{\"snippet\":{\"title\":\"Lakers vs Celtics Highlights\"},\"id\":{\"videoId\":\"abc123\"}}]}"))
    (let ((results (nba-highlights-bot::parse-search-response json)))
      (is (= 1 (length results)))
      (is (string= "Lakers vs Celtics Highlights" (car (first results))))
      (is (string= "https://www.youtube.com/watch?v=abc123" (cdr (first results)))))))

(test (parse-multiple-videos :suite youtube-tests)
  "Parsing a response with multiple videos returns all pairs."
  (let ((json "{\"items\":[{\"snippet\":{\"title\":\"Game 1\"},\"id\":{\"videoId\":\"vid1\"}},{\"snippet\":{\"title\":\"Game 2\"},\"id\":{\"videoId\":\"vid2\"}}]}"))
    (let ((results (nba-highlights-bot::parse-search-response json)))
      (is (= 2 (length results)))
      (is (string= "Game 1" (car (first results))))
      (is (string= "https://www.youtube.com/watch?v=vid1" (cdr (first results))))
      (is (string= "Game 2" (car (second results))))
      (is (string= "https://www.youtube.com/watch?v=vid2" (cdr (second results)))))))
