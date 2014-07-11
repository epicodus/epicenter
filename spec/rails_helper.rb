# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'capybara/rails'
require 'capybara/poltergeist'
require 'billy/rspec'

Capybara.javascript_driver = :poltergeist_billy

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.before(:each) do
    DatabaseCleaner.clean_with(:truncation)
  end
  config.infer_spec_type_from_file_location!
  config.include FactoryGirl::Syntax::Methods
  config.include Devise::TestHelpers, type: :controller
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
  config.filter_sensitive_data('<BALANCED_API_KEY>') { ENV['BALANCED_API_KEY'] }
end

Billy.configure do |c|
  c.cache = true
  c.persist_cache = true
  c.ignore_params = ["https://api.balancedpayments.com/jsonp/bank_accounts"]
  c.cache_path = 'spec/cassettes/javascript/'
  c.non_successful_error_level = :warn
end
