(in-package :nba-highlights-bot/tests)

(def-suite config-tests :in nba-tests
  :description "Tests for configuration loading")
(in-suite config-tests)

(test (missing-telegram-token :suite config-tests)
  "Signals error when TELEGRAM_BOT_TOKEN is not set."
  (let ((saved (uiop:getenv "TELEGRAM_BOT_TOKEN")))
    (unwind-protect
         (progn
           #+sbcl (sb-posix:unsetenv "TELEGRAM_BOT_TOKEN")
           (signals error (nba-highlights-bot:telegram-token)))
      (when saved
        #+sbcl (sb-posix:putenv (concatenate 'string "TELEGRAM_BOT_TOKEN=" saved))))))

(test (missing-youtube-key :suite config-tests)
  "Signals error when YOUTUBE_API_KEY is not set."
  (let ((saved (uiop:getenv "YOUTUBE_API_KEY")))
    (unwind-protect
         (progn
           #+sbcl (sb-posix:unsetenv "YOUTUBE_API_KEY")
           (signals error (nba-highlights-bot:youtube-api-key)))
      (when saved
        #+sbcl (sb-posix:putenv (concatenate 'string "YOUTUBE_API_KEY=" saved))))))

(test (telegram-token-returns-value-when-set :suite config-tests)
  "Returns the token when TELEGRAM_BOT_TOKEN is set."
  #+sbcl
  (progn
    (let ((saved (uiop:getenv "TELEGRAM_BOT_TOKEN")))
      (unwind-protect
           (progn
             (sb-posix:putenv "TELEGRAM_BOT_TOKEN=test-token-123")
             (is (string= "test-token-123" (nba-highlights-bot:telegram-token))))
        (when saved
          (sb-posix:putenv (concatenate 'string "TELEGRAM_BOT_TOKEN=" saved)))))))

(test (youtube-api-key-returns-value-when-set :suite config-tests)
  "Returns the key when YOUTUBE_API_KEY is set."
  #+sbcl
  (progn
    (let ((saved (uiop:getenv "YOUTUBE_API_KEY")))
      (unwind-protect
           (progn
             (sb-posix:putenv "YOUTUBE_API_KEY=test-key-456")
             (is (string= "test-key-456" (nba-highlights-bot:youtube-api-key))))
        (when saved
          (sb-posix:putenv (concatenate 'string "YOUTUBE_API_KEY=" saved)))))))
