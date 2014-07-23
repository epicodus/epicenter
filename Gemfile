ruby '2.0.0'

source 'https://rubygems.org'

gem 'rails', '4.1.1'
gem 'pg'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'jquery-rails'
gem 'jbuilder', '~> 2.0'
gem 'devise'
gem 'balanced'

group :development do
  gem 'spring'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'quiet_assets'
end

group :test, :development do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'awesome_print'
  gem 'dotenv-rails'
  gem 'pry'
end

group :test do
  gem 'capybara'
  gem 'shoulda-matchers'
  gem 'launchy'
  gem 'poltergeist'
  gem 'database_cleaner', git: 'https://github.com/DatabaseCleaner/database_cleaner'
  gem 'webmock', require: false
  gem 'vcr'
  gem 'puffing-billy'
end

group :production do
  gem 'rails_12factor'
  gem 'unicorn'
  gem 'newrelic_rpm'
  gem 'bugsnag'
  gem 'lograge'
end
