# NBA Highlights Telegram Bot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Common Lisp Telegram bot that fetches NBA highlight videos from YouTube on demand via slash commands.

**Architecture:** Five-module design — config, teams, youtube client, commands, and bot. Each module has one responsibility. The bot polls Telegram for updates, dispatches commands, queries the YouTube Data API v3, and replies with inline URL buttons to highlight videos.

**Tech Stack:** Common Lisp (SBCL), cl-telegram-bot (v1), Dexador (HTTP), Yason (JSON), local-time (dates), cl-dotenv (dev env loading), Docker

---

## File Structure

| File | Responsibility |
|---|---|
| `nba-highlights-bot.asd` | ASDF system definition with dependencies |
| `src/config.lisp` | Read TELEGRAM_BOT_TOKEN and YOUTUBE_API_KEY from env |
| `src/teams.lisp` | Team alias map and case-insensitive lookup |
| `src/youtube.lisp` | YouTube Data API v3 search client |
| `src/commands.lisp` | Slash command handlers composing teams + youtube |
| `src/bot.lisp` | Bot class definition, on-command dispatch, polling loop |
| `t/config.lisp` | Tests for config module |
| `t/teams.lisp` | Tests for teams module |
| `t/youtube.lisp` | Tests for youtube module |
| `t/commands.lisp` | Tests for commands module |
| `.env.example` | Template for required env vars |
| `.gitignore` | Ignore .env, *.fasl, etc. |
| `Dockerfile` | SBCL + Quicklisp container build |
| `docker-compose.yml` | Service definition with env vars |
| `.dockerignore` | Skip .git, .env, *.fasl |

---

### Task 1: Project scaffolding

**Files:**
- Create: `nba-highlights-bot.asd`
- Create: `src/config.lisp`
- Create: `src/teams.lisp`
- Create: `src/youtube.lisp`
- Create: `src/commands.lisp`
- Create: `src/bot.lisp`
- Create: `t/config.lisp`
- Create: `t/teams.lisp`
- Create: `t/youtube.lisp`
- Create: `t/commands.lisp`
- Create: `src/packages.lisp`
- Create: `t/packages.lisp`
- Create: `.gitignore`
- Create: `.env.example`

- [ ] **Step 1: Create .gitignore**

```
*.fasl
*.lib
*._abcl
*.acl
*.dx32fsl
*.dx64fsl
*.lx32fsl
*.lx64fsl
*.x86f
.env
quicklisp/
```

- [ ] **Step 2: Create .env.example**

```
TELEGRAM_BOT_TOKEN=your-telegram-bot-token-here
YOUTUBE_API_KEY=your-youtube-api-key-here
```

- [ ] **Step 3: Create ASDF system definition**

Create `nba-highlights-bot.asd`:

```lisp
(defsystem "nba-highlights-bot"
  :version "0.1.0"
  :description "Telegram bot that posts NBA highlight videos from YouTube"
  :author ""
  :license "MIT"
  :depends-on ("cl-telegram-bot"
               "dexador"
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
  :depends-on ("nba-highlights-bot" "fiveam")
  :components ((:module "t"
                :components ((:file "packages")
                             (:file "config")
                             (:file "teams")
                             (:file "youtube")
                             (:file "commands"))))
  :perform (test-op (op sys)
             (uiop:symbol-call :fiveam :run! :nba-tests)))
```

- [ ] **Step 4: Create src/packages.lisp**

Define the `NBA-HIGHLIGHTS-BOT` package with all exported symbols:

```lisp
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
```

- [ ] **Step 5: Create src/config.lisp stub**

```lisp
(in-package :nba-highlights-bot)

(defun load-config ()
  "Load configuration. Try cl-dotenv if .env exists, then read env vars."
  (let ((env-file (merge-pathnames ".env" (asdf:system-source-directory :nba-highlights-bot))))
    (when (probe-file env-file)
      (cl-dotenv:load-dotenv env-file)))
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
```

- [ ] **Step 6: Create src/teams.lisp stub**

```lisp
(in-package :nba-highlights-bot)

(defparameter *team-aliases*
  '(("hawks" . "Atlanta Hawks")
    ("atlanta" . "Atlanta Hawks")
    ("at" . "Atlanta Hawks")
    ("celtics" . "Boston Celtics")
    ("boston" . "Boston Celtics")
    ("bos" . "Boston Celtics")
    ("nets" . "Brooklyn Nets")
    ("brooklyn" . "Brooklyn Nets")
    ("bkn" . "Brooklyn Nets")
    ("hornets" . "Charlotte Hornets")
    ("charlotte" . "Charlotte Hornets")
    ("cha" . "Charlotte Hornets")
    ("bulls" . "Chicago Bulls")
    ("chicago" . "Chicago Bulls")
    ("chi" . "Chicago Bulls")
    ("cavaliers" . "Cleveland Cavaliers")
    ("cavs" . "Cleveland Cavaliers")
    ("cleveland" . "Cleveland Cavaliers")
    ("cle" . "Cleveland Cavaliers")
    ("mavericks" . "Dallas Mavericks")
    ("mavs" . "Dallas Mavericks")
    ("dallas" . "Dallas Mavericks")
    ("dal" . "Dallas Mavericks")
    ("nuggets" . "Denver Nuggets")
    ("denver" . "Denver Nuggets")
    ("den" . "Denver Nuggets")
    ("pistons" . "Detroit Pistons")
    ("detroit" . "Detroit Pistons")
    ("det" . "Detroit Pistons")
    ("warriors" . "Golden State Warriors")
    ("golden state" . "Golden State Warriors")
    ("gsw" . "Golden State Warriors")
    ("rockets" . "Houston Rockets")
    ("houston" . "Houston Rockets")
    ("hou" . "Houston Rockets")
    ("pacers" . "Indiana Pacers")
    ("indiana" . "Indiana Pacers")
    ("ind" . "Indiana Pacers")
    ("clippers" . "LA Clippers")
    ("la clippers" . "LA Clippers")
    ("lac" . "LA Clippers")
    ("lakers" . "Los Angeles Lakers")
    ("los angeles lakers" . "Los Angeles Lakers")
    ("lal" . "Los Angeles Lakers")
    ("grizzlies" . "Memphis Grizzlies")
    ("memphis" . "Memphis Grizzlies")
    ("mem" . "Memphis Grizzlies")
    ("heat" . "Miami Heat")
    ("miami" . "Miami Heat")
    ("mia" . "Miami Heat")
    ("bucks" . "Milwaukee Bucks")
    ("milwaukee" . "Milwaukee Bucks")
    ("mil" . "Milwaukee Bucks")
    ("timberwolves" . "Minnesota Timberwolves")
    ("wolves" . "Minnesota Timberwolves")
    ("minnesota" . "Minnesota Timberwolves")
    ("min" . "Minnesota Timberwolves")
    ("pelicans" . "New Orleans Pelicans")
    ("pels" . "New Orleans Pelicans")
    ("new orleans" . "New Orleans Pelicans")
    ("nop" . "New Orleans Pelicans")
    ("knicks" . "New York Knicks")
    ("new york" . "New York Knicks")
    ("nyk" . "New York Knicks")
    ("thunder" . "Oklahoma City Thunder")
    ("oklahoma city" . "Oklahoma City Thunder")
    ("okc" . "Oklahoma City Thunder")
    ("magic" . "Orlando Magic")
    ("orlando" . "Orlando Magic")
    ("orl" . "Orlando Magic")
    ("76ers" . "Philadelphia 76ers")
    ("sixers" . "Philadelphia 76ers")
    ("philadelphia" . "Philadelphia 76ers")
    ("phi" . "Philadelphia 76ers")
    ("suns" . "Phoenix Suns")
    ("phoenix" . "Phoenix Suns")
    ("phx" . "Phoenix Suns")
    ("blazers" . "Portland Trail Blazers")
    ("trail blazers" . "Portland Trail Blazers")
    ("portland" . "Portland Trail Blazers")
    ("por" . "Portland Trail Blazers")
    ("kings" . "Sacramento Kings")
    ("sacramento" . "Sacramento Kings")
    ("sac" . "Sacramento Kings")
    ("spurs" . "San Antonio Spurs")
    ("san antonio" . "San Antonio Spurs")
    ("sas" . "San Antonio Spurs")
    ("raptors" . "Toronto Raptors")
    ("toronto" . "Toronto Raptors")
    ("tor" . "Toronto Raptors")
    ("jazz" . "Utah Jazz")
    ("utah" . "Utah Jazz")
    ("uta" . "Utah Jazz")
    ("wizards" . "Washington Wizards")
    ("washington" . "Washington Wizards")
    ("was" . "Washington Wizards"))
  "Alist mapping team alias strings to full team names.")

(defun resolve-team (input)
  "Resolve a team alias string to the full team name.
Returns the full team name string, or NIL if no match found.
Case-insensitive."
  (let ((downcased (string-downcase (string-trim " " input))))
    (cdr (assoc downcased *team-aliases* :test #'string=))))
```

- [ ] **Step 7: Create src/youtube.lisp stub**

```lisp
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
  (let ((decoded (local-time:decode-timestamp timestamp)))
    (destructuring-bind (sec min hour day month year) decoded
      (declare (ignore sec min hour))
      (encode-universal-time 0 0 0 day month year 0))))

(defun end-of-day-ut (timestamp)
  "Return the universal time for 23:59:59 UTC of the given local-time timestamp."
  (let ((decoded (local-time:decode-timestamp timestamp)))
    (destructuring-bind (sec min hour day month year) decoded
      (declare (ignore sec min hour))
      (encode-universal-time 59 59 23 day month year 0))))

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
    (loop for item across items
          collect (let* ((snippet (gethash "snippet" item))
                         (title (gethash "title" snippet))
                         (video-id (gethash "videoId"
                                            (gethash "id" item)))
                         (url (format nil "https://www.youtube.com/watch?v=~A" video-id)))
                    (cons title url)))))
```

- [ ] **Step 8: Create src/commands.lisp stub**

```lisp
(in-package :nba-highlights-bot)

(defun format-date-string (timestamp)
  "Format a local-time timestamp as a readable date string for search queries."
  (local-time:format-timestring
   nil timestamp
   :format '((:month 2) #\/ (:day 2) #\/ (:year 4))))

(defun format-results (videos)
  "Format a list of (title . url) pairs into a Telegram message string.
Returns two values: the message text and an inline keyboard markup."
  (if (null videos)
      (values "No highlights found." nil)
      (let ((lines (loop for (title . url) in videos
                         collect (format nil "~A~%" title)))
            (buttons (loop for (title . url) in videos
                           collect (list (cl-telegram-bot/inline:keyboard-button--url
                                          :text "Watch on YouTube"
                                          :url url)))))
        (values
         (format nil "~{~A~^~%~}" lines)
         (cl-telegram-bot/inline:make-inline-keyboard buttons)))))

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
  (let* ((now (local-time:now))
         (query (format nil "NBA Highlights ~A" (format-date-string now))))
    (format-results (search-highlights query :date now))))

(defun handle-yesterday ()
  "Search for yesterday's NBA highlights. Returns message text and keyboard."
  (let* ((yesterday (local-time:timestamp- (local-time:now) 1 :day))
         (query (format nil "NBA Highlights ~A" (format-date-string yesterday))))
    (format-results (search-highlights query :date yesterday))))

(defun handle-team (team-input)
  "Search for highlights for a specific team. Returns message text and keyboard."
  (let ((team-name (resolve-team team-input)))
    (if team-name
        (let* ((now (local-time:now))
               (query (format nil "~A Highlights ~A"
                              team-name (format-date-string now))))
          (format-results (search-highlights query :date now)))
        (values
         (format nil "Unknown team: ~A. Use /help to see available commands." team-input)
         nil))))
```

- [ ] **Step 9: Create src/bot.lisp stub**

```lisp
(in-package :nba-highlights-bot)

(defclass nba-bot (cl-telegram-bot/bot:bot-impl) ()
  (:documentation "NBA Highlights Telegram bot."))

(cl-telegram-bot/bot:defbot nba-bot)

(defmethod cl-telegram-bot/bot:on-command ((bot nba-bot)
                                           (command (eql :help))
                                           text)
  (declare (ignore text))
  (cl-telegram-bot/bot:reply (handle-help)))

(defmethod cl-telegram-bot/bot:on-command ((bot nba-bot)
                                           (command (eql :today))
                                           text)
  (declare (ignore text))
  (multiple-value-bind (msg keyboard) (handle-today)
    (if keyboard
        (cl-telegram-bot/bot:reply msg :reply-markup keyboard)
        (cl-telegram-bot/bot:reply msg))))

(defmethod cl-telegram-bot/bot:on-command ((bot nba-bot)
                                           (command (eql :yesterday))
                                           text)
  (declare (ignore text))
  (multiple-value-bind (msg keyboard) (handle-yesterday)
    (if keyboard
        (cl-telegram-bot/bot:reply msg :reply-markup keyboard)
        (cl-telegram-bot/bot:reply msg))))

(defmethod cl-telegram-bot/bot:on-command ((bot nba-bot)
                                           command
                                           text)
  (let ((team-name (resolve-team (symbol-name command))))
    (if team-name
        (multiple-value-bind (msg keyboard) (handle-team (symbol-name command))
          (if keyboard
              (cl-telegram-bot/bot:reply msg :reply-markup keyboard)
              (cl-telegram-bot/bot:reply msg)))
        (cl-telegram-bot/bot:reply
         (format nil "Unknown command: /~A. Use /help for available commands."
                 command)))))

(defun start ()
  "Start the NBA highlights bot."
  (let ((token (telegram-token)))
    (let ((bot (make-instance 'nba-bot :token token)))
      (cl-telegram-bot/bot:start-processing bot)
      (format t "NBA Highlights Bot is running. Press Ctrl+C to stop.~%")
      (loop (sleep 60)))))
```

- [ ] **Step 10: Create t/packages.lisp**

```lisp
(defpackage nba-highlights-bot/tests
  (:use :cl :fiveam)
  (:export :nba-tests
           :run-tests))

(in-package :nba-highlights-bot/tests)

(def-suite nba-tests
  :description "Test suite for NBA Highlights Bot")
```

- [ ] **Step 11: Create t/config.lisp**

```lisp
(in-package :nba-highlights-bot/tests)

(def-suite config-tests :in nba-tests)
(in-suite config-tests)

(test missing-telegram-token
  "Signals error when TELEGRAM_BOT_TOKEN is not set."
  (let ((uiop:*environment* (copy-seq uiop:*environment*)))
    ;; Remove the variable if present
    (setf (uiop:getenv "TELEGRAM_BOT_TOKEN") nil)
    (signals error (nba-highlights-bot:telegram-token))))

(test missing-youtube-key
  "Signals error when YOUTUBE_API_KEY is not set."
  (let ((uiop:*environment* (copy-seq uiop:*environment*)))
    (setf (uiop:getenv "YOUTUBE_API_KEY") nil)
    (signals error (nba-highlights-bot:youtube-api-key))))
```

- [ ] **Step 12: Create t/teams.lisp**

```lisp
(in-package :nba-highlights-bot/tests)

(def-suite teams-tests :in nba-tests)
(in-suite teams-tests)

(test resolve-full-name
  "Resolve full team name like 'lakers'."
  (is (string= "Los Angeles Lakers"
               (nba-highlights-bot:resolve-team "lakers"))))

(test resolve-abbreviation
  "Resolve abbreviation like 'lal'."
  (is (string= "Los Angeles Lakers"
               (nba-highlights-bot:resolve-team "lal"))))

(test resolve-city
  "Resolve city name like 'boston'."
  (is (string= "Boston Celtics"
               (nba-highlights-bot:resolve-team "boston"))))

(test case-insensitive
  "Resolution is case-insensitive."
  (is (string= "Los Angeles Lakers"
               (nba-highlights-bot:resolve-team "LAKERS")))
  (is (string= "Los Angeles Lakers"
               (nba-highlights-bot:resolve-team "Lakers"))))

(test unknown-team
  "Returns NIL for unknown team."
  (is (null (nba-highlights-bot:resolve-team "foobar"))))

(test whitespace-trimmed
  "Leading/trailing whitespace is ignored."
  (is (string= "Los Angeles Lakers"
               (nba-highlights-bot:resolve-team "  lakers  ")))))
```

- [ ] **Step 13: Create t/youtube.lisp**

```lisp
(in-package :nba-highlights-bot/tests)

(def-suite youtube-tests :in nba-tests)
(in-suite youtube-tests)

(test parse-empty-response
  "Parsing an empty items array returns nil."
  (let ((json "{\"items\":[]}"))
    (is (null (nba-highlights-bot::parse-search-response json)))))

(test parse-single-video
  "Parsing a response with one video returns one (title . url) pair."
  (let ((json "{\"items\":[{\"snippet\":{\"title\":\"Lakers vs Celtics Highlights\"},\"id\":{\"videoId\":\"abc123\"}}]}"))
    (let ((results (nba-highlights-bot::parse-search-response json)))
      (is (= 1 (length results)))
      (is (string= "Lakers vs Celtics Highlights" (car (first results))))
      (is (string= "https://www.youtube.com/watch?v=abc123" (cdr (first results)))))))

(test parse-multiple-videos
  "Parsing a response with multiple videos returns all pairs."
  (let ((json "{\"items\":[{\"snippet\":{\"title\":\"Game 1\"},\"id\":{\"videoId\":\"vid1\"}},{\"snippet\":{\"title\":\"Game 2\"},\"id\":{\"videoId\":\"vid2\"}}]}"))
    (let ((results (nba-highlights-bot::parse-search-response json)))
      (is (= 2 (length results)))
      (is (string= "Game 1" (car (first results))))
      (is (string= "https://www.youtube.com/watch?v=vid1" (cdr (first results))))
      (is (string= "Game 2" (car (second results))))
      (is (string= "https://www.youtube.com/watch?v=vid2" (cdr (second results)))))))
```

- [ ] **Step 14: Create t/commands.lisp**

```lisp
(in-package :nba-highlights-bot/tests)

(def-suite commands-tests :in nba-tests)
(in-suite commands-tests)

(test format-results-empty
  "Formatting empty results returns no-highlights message."
  (multiple-value-bind (msg keyboard) (nba-highlights-bot::format-results nil)
    (is (string= "No highlights found." msg))
    (is (null keyboard))))

(test format-results-single
  "Formatting a single result returns title text and keyboard."
  (let ((videos (list (cons "Lakers vs Celtics" "https://youtube.com/watch?v=abc"))))
    (multiple-value-bind (msg keyboard) (nba-highlights-bot::format-results videos)
      (is (search "Lakers vs Celtics" msg))
      (is (not (null keyboard))))))

(test handle-help-returns-text
  "Help handler returns a string containing command descriptions."
  (let ((help (nba-highlights-bot:handle-help)))
    (is (stringp help))
    (is (search "/today" help))
    (is (search "/yesterday" help))
    (is (search "/help" help))))

(test handle-team-unknown
  "Unknown team returns an error message with no keyboard."
  (multiple-value-bind (msg keyboard) (nba-highlights-bot:handle-team "foobar")
    (is (search "Unknown team" msg))
    (is (null keyboard))))
```

- [ ] **Step 15: Verify everything loads**

Run: `sbcl --non-interactive --eval '(require :asdf)' --eval '(push (truename ".") asdf:*central-registry*)' --eval '(asdf:load-system :nba-highlights-bot)' --eval '(format t "LOAD OK~%")'`
Expected: "LOAD OK" printed, no errors.

- [ ] **Step 16: Commit scaffolding**

```bash
git add nba-highlights-bot.asd src/ t/ .gitignore .env.example
git commit -m "feat: project scaffolding with all modules and tests"
```

---

### Task 2: Verify tests pass

**Files:**
- Uses: `t/` test files from Task 1

- [ ] **Step 1: Run team tests**

Run: `sbcl --non-interactive --eval '(require :asdf)' --eval '(push (truename ".") asdf:*central-registry*)' --eval '(ql:quickload :nba-highlights-bot/test)' --eval '(fiveam:run! :teams-tests)'`
Expected: All 6 team tests PASS.

- [ ] **Step 2: Run youtube tests**

Run: `sbcl --non-interactive --eval '(require :asdf)' --eval '(push (truename ".") asdf:*central-registry*)' --eval '(ql:quickload :nba-highlights-bot/test)' --eval '(fiveam:run! :youtube-tests)'`
Expected: All 3 youtube tests PASS.

- [ ] **Step 3: Run commands tests**

Run: `sbcl --non-interactive --eval '(require :asdf)' --eval '(push (truename ".") asdf:*central-registry*)' --eval '(ql:quickload :nba-highlights-bot/test)' --eval '(fiveam:run! :commands-tests)'`
Expected: All 4 commands tests PASS.

- [ ] **Step 4: Run full test suite**

Run: `sbcl --non-interactive --eval '(require :asdf)' --eval '(push (truename ".") asdf:*central-registry*)' --eval '(ql:quickload :nba-highlights-bot/test)' --eval '(fiveam:run! :nba-tests)'`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git commit --allow-empty -m "test: all unit tests passing"
```

---

### Task 3: Docker containerization

**Files:**
- Create: `Dockerfile`
- Create: `docker-compose.yml`
- Create: `.dockerignore`

- [ ] **Step 1: Create .dockerignore**

```
.git
.env
*.fasl
*.lib
docs/
```

- [ ] **Step 2: Create Dockerfile**

```dockerfile
FROM daewok/sbcl:latest

# Install Quicklisp
RUN sbcl --non-interactive \
         --eval '(require :asdf)' \
         --eval '(let ((ql (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))) (unless (probe-file ql) (progn (load "https://beta.quicklisp.org/quicklisp.lisp") (funcall (find-symbol "INSTALL" "QL") :path (merge-pathnames "quicklisp/" (user-homedir-pathname))))))'

# Load Quicklisp on startup
RUN echo '(let ((ql-setup (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql-setup) (load ql-setup)))' >> ~/.sbclrc

# Copy project into Quicklisp local-projects
WORKDIR /root/quicklisp/local-projects/nba-highlights-bot/
COPY nba-highlights-bot.asd .
COPY src/ src/

# Pre-load dependencies and system
RUN sbcl --non-interactive \
         --eval '(ql:quickload :nba-highlights-bot)'

ENTRYPOINT ["sbcl", "--non-interactive", \
            "--eval", "(ql:quickload :nba-highlights-bot)", \
            "--eval", "(nba-highlights-bot:start)"]
```

- [ ] **Step 3: Create docker-compose.yml**

```yaml
services:
  bot:
    build: .
    environment:
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - YOUTUBE_API_KEY=${YOUTUBE_API_KEY}
    restart: unless-stopped
```

- [ ] **Step 4: Build the Docker image**

Run: `docker compose build`
Expected: Image builds successfully.

- [ ] **Step 5: Commit**

```bash
git add Dockerfile docker-compose.yml .dockerignore
git commit -m "feat: add Dockerfile and docker-compose for containerized deployment"
```

---

### Task 4: Integration verification

**Files:**
- Uses: all files

- [ ] **Step 1: Verify Docker image starts and loads system**

Run: `docker compose run --rm -e TELEGRAM_BOT_TOKEN=test -e YOUTUBE_API_KEY=test bot 2>&1 | head -20`
Expected: Bot attempts to connect to Telegram (will fail with "test" token), confirming the system loads correctly.

- [ ] **Step 2: Verify full test suite runs in Docker**

Run: `docker run --rm $(docker build -q .) sbcl --non-interactive --eval '(ql:quickload :fiveam)' --eval '(ql:quickload :nba-highlights-bot/test)' --eval '(fiveam:run! :nba-tests)'`
Expected: All tests PASS inside the container.

- [ ] **Step 3: Final commit**

```bash
git commit --allow-empty -m "chore: integration verification complete"
```
