source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# 3.1.3
ruby "3.3.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0", ">= 8.0.2"
# gem 'rails', '~> 7.1.3'
# gem "rails", "~> 7.0.4", ">= 7.0.4.3"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.5.9"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.6.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails", "~> 2.1.0"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
# gem "turbo-rails", "~> 2.0.13"
gem "turbo-rails", "~> 2.0.13"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails", "~> 1.2.1"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder", "~> 2.13.0"

# gem na vsetko ohladom prihlasovania a registracie na web
gem "devise", "~> 4.9.3"

# gem na vsetko ohladom LLM
gem 'ruby_llm', '~> 1.2.0'

# Ruby's built-in Vector class for embeddings
gem 'matrix'

# https://github.com/alexrudall/ruby-openai
# gem 'ruby-openai'

# gem for managing environment variables
gem "dotenv-rails", "~> 3.1.8", groups: [:development, :test]

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# HTML to PDF
# gem 'wicked_pdf'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Select2
gem "select2-rails", "~> 4.0.13"

gem "font-awesome-sass", "~> 6.7.2"
# Use Sass to process CSS
# gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"
# gem 'rack-cors'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', '~> 1.10', platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
