# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :events, Events.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "events_repo",
  # username: "postgres",
  # password: "postgres",
  hostname: "localhost"

config :events, ecto_repos: [Events.Repo]

config :events,
  keywords: [
    "china",
    "chinese",
    "taiwan",
    "hong kong",
    "mandarin",
    "cantonese",
    "chinatown"
  ]

config :events, Facebook,
  pages: [
    "ChineseFineArts",
    "ccamuseum",
    "windmilldramaclub",
    "ChicagoChinatownChamberofCommerce",
    "siskelfilmcenter",
    "musicboxchicago",
    "asianpopupcinema",
    "faaimous",
    "chicagofilmfestival",
    "ChicagoCulturalCenter"
  ]

  config :events, EventBrite,
    location: "Chicago, IL"

  import_config "auth.exs"
