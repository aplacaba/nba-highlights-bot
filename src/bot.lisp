(in-package :nba-highlights-bot)

(defclass nba-bot (cl-telegram-bot/bot:bot) ()
  (:documentation "NBA Highlights Telegram bot."))

(cl-telegram-bot/bot:defbot nba-bot)

(defmethod cl-telegram-bot/entities/command:on-command ((bot nba-bot)
                                                        (command (eql :help))
                                                        text)
  (declare (ignore text))
  (cl-telegram-bot/response:reply (handle-help)))

(defmethod cl-telegram-bot/entities/command:on-command ((bot nba-bot)
                                                        (command (eql :today))
                                                        text)
  (declare (ignore text))
  (multiple-value-bind (msg keyboard) (handle-today)
    (if keyboard
        (cl-telegram-bot/response:reply msg :reply-markup keyboard)
        (cl-telegram-bot/response:reply msg))))

(defmethod cl-telegram-bot/entities/command:on-command ((bot nba-bot)
                                                        (command (eql :yesterday))
                                                        text)
  (declare (ignore text))
  (multiple-value-bind (msg keyboard) (handle-yesterday)
    (if keyboard
        (cl-telegram-bot/response:reply msg :reply-markup keyboard)
        (cl-telegram-bot/response:reply msg))))

(defmethod cl-telegram-bot/entities/command:on-command ((bot nba-bot)
                                                        (command t)
                                                        text)
  (declare (ignore text))
  (let ((team-name (resolve-team (symbol-name command))))
    (if team-name
        (multiple-value-bind (msg keyboard) (handle-team (symbol-name command))
          (if keyboard
              (cl-telegram-bot/response:reply msg :reply-markup keyboard)
              (cl-telegram-bot/response:reply msg)))
        (cl-telegram-bot/response:reply
         (format nil "Unknown command: /~A. Use /help for available commands."
                 command)))))

(defun start ()
  "Start the NBA highlights bot."
  (load-config)
  (let ((token (telegram-token)))
    (let ((bot (make-instance 'nba-bot :token token)))
      (cl-telegram-bot/core:start-processing bot)
      (format t "NBA Highlights Bot is running. Press Ctrl+C to stop.~%")
      (loop (sleep 60)))))
