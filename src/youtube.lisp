(in-package :nba-highlights-bot)

(defparameter *nba-channel-id* "UCWJ2lWNubArHWmf3FIHbfcQ"
  "The official NBA YouTube channel ID.")

(defun start-of-day-iso (timestamp)
  "Return RFC 3339 string for midnight UTC of the date in TIMESTAMP."
  (multiple-value-bind (nsec sec minute hour day month year)
      (local-time:decode-timestamp timestamp :timezone local-time:+utc-zone+)
    (declare (ignore nsec sec minute hour))
    (format nil "~4,'0D-~2,'0D-~2,'0DT00:00:00Z" year month day)))

(defun end-of-day-iso (timestamp)
  "Return RFC 3339 string for 23:59:59 UTC of the date in TIMESTAMP."
  (multiple-value-bind (nsec sec minute hour day month year)
      (local-time:decode-timestamp timestamp :timezone local-time:+utc-zone+)
    (declare (ignore nsec sec minute hour))
    (format nil "~4,'0D-~2,'0D-~2,'0DT23:59:59Z" year month day)))

(defun urlencode-param (key value)
  "URL-encode a query parameter pair, encoding key and value separately."
  (format nil "~A=~A" (quri:url-encode key) (quri:url-encode value)))

(defun search-highlights (query &key date)
  "Search the NBA YouTube channel for highlight videos.
QUERY is the search string (e.g. \"Los Angeles Lakers Highlights\").
DATE is an optional LOCAL-TIME timestamp. When provided, filters results
to videos published on that date (UTC midnight to midnight).
Returns a list of (title . url) pairs."
  (let* ((params (append (when date
                           `(("publishedAfter" . ,(start-of-day-iso date))
                             ("publishedBefore" . ,(end-of-day-iso date))))
                         `(("part" . "snippet")
                           ("channelId" . ,*nba-channel-id*)
                           ("q" . ,query)
                           ("type" . "video")
                           ("order" . "date")
                           ("maxResults" . "5")
                           ("key" . ,(youtube-api-key)))))
         (query-string (format nil "~{~A~^&~}"
                               (loop for (k . v) in params
                                     collect (urlencode-param k v))))
         (url (format nil "https://www.googleapis.com/youtube/v3/search?~A" query-string))
         (response (dex:get url
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
