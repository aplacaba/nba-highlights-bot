(in-package :nba-highlights-bot)

(defun load-config ()
  "Load configuration. Try cl-dotenv if .env exists, then read env vars."
  (let ((env-file (merge-pathnames ".env" (asdf:system-source-directory :nba-highlights-bot))))
    (when (probe-file env-file)
      (cl-dotenv:load-env env-file)))
  (let ((token (uiop:getenv "TELEGRAM_BOT_TOKEN"))
        (key (uiop:getenv "YOUTUBE_API_KEY")))
    (unless token
      (error "TELEGRAM_BOT_TOKEN environment variable is not set"))
    (unless key
      (error "YOUTUBE_API_KEY environment variable is not set"))
    (values token key)))

(defun telegram-token ()
  "Return the Telegram bot token from the environment."
  (let ((token (uiop:getenv "TELEGRAM_BOT_TOKEN")))
    (unless token
      (error "TELEGRAM_BOT_TOKEN environment variable is not set"))
    token))

(defun youtube-api-key ()
  "Return the YouTube API key from the environment."
  (let ((key (uiop:getenv "YOUTUBE_API_KEY")))
    (unless key
      (error "YOUTUBE_API_KEY environment variable is not set"))
    key))
