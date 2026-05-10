(defsystem "nba-highlights-bot"
  :version "0.1.0"
  :description "Telegram bot that posts NBA highlight videos from YouTube"
  :author ""
  :license "MIT"
  :depends-on ("cl-telegram-bot"
               "dexador"
               "quri"
               "yason"
               "local-time"
               "cl-dotenv")
  :components ((:module "src"
                :components ((:file "packages")
                             (:file "config" :depends-on ("packages"))
                             (:file "teams" :depends-on ("packages"))
                             (:file "youtube" :depends-on ("packages" "config"))
                             (:file "commands" :depends-on ("packages" "teams" "youtube"))
                             (:file "bot" :depends-on ("packages" "config" "commands")))))
  :in-order-to ((test-op (test-op "nba-highlights-bot/test"))))

(defsystem "nba-highlights-bot/test"
  :depends-on ("nba-highlights-bot" "rove")
  :components ((:module "t"
                :components ((:file "packages")
                             (:file "config" :depends-on ("packages"))
                             (:file "teams" :depends-on ("packages"))
                             (:file "youtube" :depends-on ("packages"))
                             (:file "commands" :depends-on ("packages")))))
  :perform (test-op (op sys)
             (uiop:symbol-call :rove :run sys)))
