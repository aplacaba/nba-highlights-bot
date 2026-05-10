(in-package :nba-highlights-bot/tests)

(deftest missing-telegram-token
  (testing "Signals error when TELEGRAM_BOT_TOKEN is not set"
    (let ((saved (uiop:getenv "TELEGRAM_BOT_TOKEN")))
      (unwind-protect
           (progn
             #+sbcl (sb-posix:unsetenv "TELEGRAM_BOT_TOKEN")
             (ok (signals (nba-highlights-bot:telegram-token) 'error)))
        (when saved
          #+sbcl (sb-posix:putenv (concatenate 'string "TELEGRAM_BOT_TOKEN=" saved)))))))

(deftest missing-youtube-key
  (testing "Signals error when YOUTUBE_API_KEY is not set"
    (let ((saved (uiop:getenv "YOUTUBE_API_KEY")))
      (unwind-protect
           (progn
             #+sbcl (sb-posix:unsetenv "YOUTUBE_API_KEY")
             (ok (signals (nba-highlights-bot:youtube-api-key) 'error)))
        (when saved
          #+sbcl (sb-posix:putenv (concatenate 'string "YOUTUBE_API_KEY=" saved)))))))

(deftest telegram-token-returns-value-when-set
  (testing "Returns the token when TELEGRAM_BOT_TOKEN is set"
    #+sbcl
    (let ((saved (uiop:getenv "TELEGRAM_BOT_TOKEN")))
      (unwind-protect
           (progn
             (sb-posix:putenv "TELEGRAM_BOT_TOKEN=test-token-123")
             (ok (string= "test-token-123" (nba-highlights-bot:telegram-token))))
        (when saved
          (sb-posix:putenv (concatenate 'string "TELEGRAM_BOT_TOKEN=" saved)))))))

(deftest youtube-api-key-returns-value-when-set
  (testing "Returns the key when YOUTUBE_API_KEY is set"
    #+sbcl
    (let ((saved (uiop:getenv "YOUTUBE_API_KEY")))
      (unwind-protect
           (progn
             (sb-posix:putenv "YOUTUBE_API_KEY=test-key-456")
             (ok (string= "test-key-456" (nba-highlights-bot:youtube-api-key))))
        (when saved
          (sb-posix:putenv (concatenate 'string "YOUTUBE_API_KEY=" saved)))))))
