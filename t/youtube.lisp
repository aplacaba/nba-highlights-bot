(in-package :nba-highlights-bot/tests)

(deftest parse-empty-response
  (testing "Parsing an empty items array returns nil"
    (let ((json "{\"items\":[]}"))
      (ok (null (nba-highlights-bot::parse-search-response json))))))

(deftest parse-single-video
  (testing "Parsing a response with one video returns one (title . url) pair"
    (let ((json "{\"items\":[{\"snippet\":{\"title\":\"Lakers vs Celtics Highlights\"},\"id\":{\"videoId\":\"abc123\"}}]}"))
      (let ((results (nba-highlights-bot::parse-search-response json)))
        (ok (= 1 (length results)))
        (ok (string= "Lakers vs Celtics Highlights" (car (first results))))
        (ok (string= "https://www.youtube.com/watch?v=abc123" (cdr (first results))))))))

(deftest parse-multiple-videos
  (testing "Parsing a response with multiple videos returns all pairs"
    (let ((json "{\"items\":[{\"snippet\":{\"title\":\"Game 1\"},\"id\":{\"videoId\":\"vid1\"}},{\"snippet\":{\"title\":\"Game 2\"},\"id\":{\"videoId\":\"vid2\"}}]}"))
      (let ((results (nba-highlights-bot::parse-search-response json)))
        (ok (= 2 (length results)))
        (ok (string= "Game 1" (car (first results))))
        (ok (string= "https://www.youtube.com/watch?v=vid1" (cdr (first results))))
        (ok (string= "Game 2" (car (second results))))
        (ok (string= "https://www.youtube.com/watch?v=vid2" (cdr (second results))))))))
