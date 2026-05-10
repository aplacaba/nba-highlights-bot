(defpackage nba-highlights-bot
  (:use :cl)
  (:export #:telegram-token
           #:youtube-api-key
           #:load-config
           #:resolve-team
           #:*team-aliases*
           #:search-highlights
           #:handle-today
           #:handle-yesterday
           #:handle-team
           #:handle-help
           #:nba-bot
           #:start))
