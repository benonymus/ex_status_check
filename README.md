# ExStatusCheck

Small website status checker made with Elixir, Phoenix LiveView, Oban and SQLite deployed to fly.io.

A functional test project to explore SQLite prompted by [`https://fly.io/blog/introducing-litefs/`](https://fly.io/blog/introducing-litefs/) and a failed job prospect.

Deployment link: [`https://ex-status-check.fly.dev`](https://ex-status-check.fly.dev)

## Local development
To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Could be nice to have
- Better test coverage
- Alerting - email or different outlets
- One level deeper page that shows the actual checks, it would need more info to be saved about success/failure
- UI tweaks, show more numbers not just in the tooltips
- Remove pages that have not been visited in a while
- Rate limit page creation
