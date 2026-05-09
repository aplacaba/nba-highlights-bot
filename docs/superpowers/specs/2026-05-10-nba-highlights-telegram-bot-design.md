# NBA Highlights Telegram Bot — Design Spec

## Overview

A Common Lisp Telegram bot that posts NBA game highlight videos from the official NBA YouTube channel on demand via slash commands. Runs locally using long-polling, containerized with Docker.

## Architecture

```
nba-highlights-bot.asd          # ASDF system definition
src/
  bot.lisp                      # Bot class, command dispatch, polling loop
  commands.lisp                 # /today, /<team>, /yesterday, /help handlers
  youtube.lisp                  # YouTube Data API client
  teams.lisp                    # Team name aliases & matching
  config.lisp                   # Load env vars (API keys, bot token)
```

Five modules, each with one responsibility:

- **config.lisp** — Reads `TELEGRAM_BOT_TOKEN` and `YOUTUBE_API_KEY` from environment variables. Exports accessor functions. Signals a clear error on startup if either is missing.
- **teams.lisp** — Static map of team aliases (e.g. `"lakers"` → `"Los Angeles Lakers"`, `"lal"` → `"Los Angeles Lakers"`). Handles case-insensitive matching so `/lakers`, `/LAL`, and `/los angeles lakers` all work.
- **youtube.lisp** — Calls the YouTube Data API v3. Takes a search query string and optional date, returns a list of video results (title + URL).
- **commands.lisp** — Implements each slash command by composing teams.lisp and youtube.lisp. Formats results into Telegram messages.
- **bot.lisp** — Defines the bot class (subclassing `cl-telegram-bot`'s base), wires up `on-command` methods, and starts the polling loop.

Data flow: **Telegram command → commands.lisp resolves teams/date → youtube.lisp fetches videos → commands.lisp formats → bot.lisp replies.**

## Commands

**`/help`** — Replies with a usage message listing all commands and example team names.

**`/today`** — Fetches today's date, searches YouTube for `"NBA Highlights <date>"` on the NBA channel, replies with all matching videos. If no results, replies "No highlights found for today's games yet."

**`/yesterday`** — Same as `/today` but with yesterday's date.

**`/<team>`** — Resolves the argument against the team alias map. Searches YouTube for `"<Team Name> Highlights <today's date>"` on the NBA channel. Replies with matching videos. If the team name can't be resolved, replies with an "Unknown team" message and a suggestion to use `/help`.

Each reply contains:
- Video title as bold text
- A URL button linking to the YouTube video
- Multiple results are stacked in a single message with one inline keyboard row per video

Example `/lakers` reply:
```
🏀 Lakers vs Celtics - Full Game Highlights
[Watch on YouTube] ← inline URL button
```

The bot only responds to commands — no free-text message handling.

## YouTube Search Module

The NBA YouTube channel ID is `UCWJ2lWNubArHWmf3FIHbfcQ` (hardcoded).

**Search function signature:**
```lisp
(search-highlights query &key date) → list of (title . url) pairs
```

**Query construction:**
- Takes the base query string (e.g. `"Los Angeles Lakers Highlights"`)
- Appends date as `publishedAfter`/`publishedBefore` filters using RFC 3339 timestamps (midnight to midnight UTC)
- Sends GET to `https://www.googleapis.com/youtube/v3/search` with params: `part=snippet`, `channelId`, `q`, `type=video`, `order=date`, `maxResults=5`, `key`, `publishedAfter`, `publishedBefore`
- Parses JSON response, extracts `items[].snippet.title` and constructs URLs from `items[].id.videoId`
- Returns empty list if no results

**Error handling:**
- HTTP errors or API quota exceeded → logs error, replies "Couldn't fetch highlights right now, try again later."
- Malformed JSON → same graceful fallback

No client-side caching. The bot only calls the API on demand, so the 100 searches/day free quota is sufficient.

## Configuration & Running

**Environment variables:**
- `TELEGRAM_BOT_TOKEN` — from @BotFather
- `YOUTUBE_API_KEY` — from Google Cloud Console (YouTube Data API v3 enabled)

**Entry point:**
```lisp
(nba-highlights-bot:start)
```

Creates the bot instance, connects with polling, and blocks. `Ctrl+C` (SIGINT) stops the bot cleanly via `stop-processing`.

**ASDF dependencies:**
- `cl-telegram-bot` (v1)
- `dexador`
- `yason`
- `local-time`
- `cl-dotenv` (optional, for loading `.env` during development)

No database, no persisted state. Purely request/response.

## Containerization

**Dockerfile:**
- Base image: `daewok/sbcl` (SBCL on Debian)
- Install Quicklisp in the image
- Copy project into `~/quicklisp/local-projects/nba-highlights-bot/` so Quicklisp finds it
- Entry point: `sbcl --non-interactive --eval '(ql:quickload :nba-highlights-bot)' --eval '(nba-highlights-bot:start)'`
- Expose no ports (polling mode, no incoming connections)

**docker-compose.yml:**
```yaml
services:
  bot:
    build: .
    environment:
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - YOUTUBE_API_KEY=${YOUTUBE_API_KEY}
    restart: unless-stopped
```

**.env file** (gitignored) holds tokens locally. In production, pass env vars directly.

**.dockerignore** — Skip `.git`, `.env`, `*.fasl` build artifacts.
