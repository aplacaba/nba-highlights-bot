(in-package :nba-highlights-bot)

(defun format-results (videos)
  "Format a list of (title . url) pairs into a Telegram message string.
Returns two values: the message text and an inline keyboard markup."
  (if (null videos)
      (values "No highlights found." nil)
      (let ((lines (loop for (title . url) in videos
                         collect (format nil "~A~%" title)))
            (buttons (loop for (title . url) in videos
                           collect (list (make-instance
                                          'cl-telegram-bot/inline-keyboard::url-button
                                          :text (format nil "~A" title)
                                          :data url)))))
        (values
         (format nil "~{~A~^~%~}" lines)
         (cl-telegram-bot/inline-keyboard:inline-keyboard buttons)))))

(defun handle-help ()
  "Return the help message text."
  "Available commands:

/today - Get today's game highlights
/yesterday - Get yesterday's game highlights
/<team> - Get highlights for a specific team (e.g. /lakers, /celtics)
/help - Show this message

Team names support full names (celtics), cities (boston), and abbreviations (bos).")

(defun handle-today ()
  "Search for today's NBA highlights. Returns message text and keyboard."
  (format-results (search-highlights "NBA Highlights" :date (local-time:now))))

(defun handle-yesterday ()
  "Search for yesterday's NBA highlights. Returns message text and keyboard."
  (let ((yesterday (local-time:timestamp- (local-time:now) 1 :day)))
    (format-results (search-highlights "NBA Highlights" :date yesterday))))

(defun handle-team (team-input)
  "Search for highlights for a specific team. Returns message text and keyboard."
  (let ((team-name (resolve-team team-input)))
    (if team-name
        (let ((query (format nil "~A Highlights" team-name)))
          (format-results (search-highlights query :date (local-time:now))))
        (values
         (format nil "Unknown team: ~A. Use /help to see available commands." team-input)
         nil))))
