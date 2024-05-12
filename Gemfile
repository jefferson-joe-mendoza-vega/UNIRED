# Use Ruby 3.2.3
ruby "3.2.3"

# Rails framework
gem "rails", "~> 7.1.3"

# Use PostgreSQL as the production database
group :production do
  gem 'pg'
end

# Use sqlite3 as the development and test database
group :development, :test do
  gem "sqlite3", "~> 1.4"
end

# Web server
gem "puma", ">= 5.0"

# Active Storage for file uploads
gem "aws-sdk-s3"

# Pagination
gem "pagy", "~> 7.0"
gem 'will_paginate'

# Linking URLs in Rails views
gem 'rails_autolink'

# Frontend
gem "importmap-rails" # JavaScript import maps
gem "turbo-rails"      # Hotwire's SPA-like page accelerator
gem "stimulus-rails"   # Hotwire's modest JavaScript framework

# JSON APIs
gem "jbuilder"

# Password hashing
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Speed up boot time
gem "bootsnap", require: false

# Development and debugging tools
group :development do
  gem "web-console" # Console on exceptions pages
end

# Testing tools
group :test do
  gem "capybara"           # System testing
  gem "selenium-webdriver" # Webdriver for Capybara
end

# FTS (Full Text Search) support
gem 'pg_search', "~> 2.3"

# Fake data generation for testing
gem 'faker'
