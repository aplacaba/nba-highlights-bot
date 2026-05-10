(in-package :nba-highlights-bot)

(defparameter *nba-channel-id* "UCWJ2lWNubArHWmf3FIHbfcQ"
  "The official NBA YouTube channel ID.")

(defun make-rfc3339-timestamp (universal-time)
  "Convert a universal time to an RFC 3339 timestamp string."
  (local-time:format-timestring
   nil (local-time:universal-to-timestamp universal-time)
   :format '((:year 4) #\- (:month 2) #\- (:day 2) #\T
             (:hour 2) #\: (:min 2) #\: (:sec 2) #\Z)))

(defun start-of-day-ut (timestamp)
  "Return the universal time for midnight UTC of the given local-time timestamp."
  ;; decode-timestamp returns: nsec sec minute hour day month year day-of-week daylight-p offset abbrev
  (multiple-value-bind (nsec sec minute hour day month year)
      (local-time:decode-timestamp timestamp :timezone local-time:+utc-zone+)
    (declare (ignore nsec sec minute hour))
    (encode-universal-time 0 0 0 day month year 0)))

(defun end-of-day-ut (timestamp)
  "Return the universal time for 23:59:59 UTC of the given local-time timestamp."
  (multiple-value-bind (nsec sec minute hour day month year)
      (local-time:decode-timestamp timestamp :timezone local-time:+utc-zone+)
    (declare (ignore nsec sec minute hour))
    (encode-universal-time 59 59 23 day month year 0)))

(defun search-highlights (query &key date)
  "Search the NBA YouTube channel for highlight videos.
QUERY is the search string (e.g. \"Los Angeles Lakers Highlights\").
DATE is an optional LOCAL-TIME timestamp. When provided, filters results
to videos published on that date (UTC midnight to midnight).
Returns a list of (title . url) pairs."
  (let* ((params `(,@(when date
                       `(("publishedAfter" . ,(make-rfc3339-timestamp (start-of-day-ut date)))
                         ("publishedBefore" . ,(make-rfc3339-timestamp (end-of-day-ut date)))))
                   ("part" . "snippet")
                   ("channelId" . ,*nba-channel-id*)
                   ("q" . ,query)
                   ("type" . "video")
                   ("order" . "date")
                   ("maxResults" . "5")
                   ("key" . ,(youtube-api-key))))
         (response (dex:get "https://www.googleapis.com/youtube/v3/search"
                            :params params
                            :headers '(("Accept" . "application/json")))))
    (parse-search-response response)))

(defun parse-search-response (json-string)
  "Parse YouTube search API JSON response into a list of (title . url) pairs."
  (let* ((data (yason:parse json-string))
         (items (gethash "items" data)))
    (when items
      (loop for item in items
            collect (let* ((snippet (gethash "snippet" item))
                           (title (gethash "title" snippet))
                           (video-id (gethash "videoId"
                                              (gethash "id" item)))
                           (url (format nil "https://www.youtube.com/watch?v=~A" video-id)))
                      (cons title url))))))
