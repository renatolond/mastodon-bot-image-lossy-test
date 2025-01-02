# frozen_string_literal: true

source "https://rubygems.org"

# Used for accessing the APIs, translating responses, etc
gem "mastodon-api", require: "mastodon", github: "tootsuite/mastodon-api", branch: "master"

gem "httparty"

group :development, :test do
  gem "dotenv" # Used to load environment variables from .env files

  gem "debug"

  # Code formatting and hooks
  gem "lefthook", require: false # Used to make git hooks available between dev machines
  gem "pronto", github: "renatolond/pronto", ref: "053147d23daab414c610d708cfd7e278df6ace02", # needed for compatibility with ruby 3.4.x, revert back to a version when released.
                require: false # pronto analyzes code on changed code only
  gem "pronto-rubocop", require: false # pronto-rubocop extends pronto for rubocop

  gem "rubocop", require: false # A static code analyzer and formatter
  gem "rubocop-performance", require: false # A rubocop extension with performance suggestions
  gem "rubocop-yard", require: false # A rubocop extension for yard documentation
end
