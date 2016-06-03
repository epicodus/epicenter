# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'capybara/rails'
require 'capybara/poltergeist'
require 'billy/rspec'
require 'cancan/matchers'
require 'simplecov'
require 'coveralls'
require 'stripe_mock'

include Warden::Test::Helpers
Warden.test_mode!

WebMock.enable!

include ActiveSupport::Testing::TimeHelpers

Capybara.javascript_driver = :poltergeist_billy

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.before(:each) do |example|
    DatabaseCleaner.clean_with(:truncation)
    if example.metadata[:stub_mailgun]
      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }
    end
    StripeMock.start if example.metadata[:stripe_mock]
    allow(RestClient::Request).to receive(:execute) if example.metadata[:stub_less_accounting]
  end
  config.after(:each) do |example|
    StripeMock.stop if example.metadata[:stripe_mock]
  end
  config.infer_spec_type_from_file_location!
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.default_cassette_options = { :record => :new_episodes }
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
  config.filter_sensitive_data('<STRIPE_API_KEY>') { ENV['STRIPE_API_KEY'] }
  config.filter_sensitive_data('<STRIPE_PUBLIC_KEY>') { ENV['STRIPE_PUBLIC_KEY']}
  config.filter_sensitive_data('<MAILGUN_API_KEY>') { ENV['MAILGUN_API_KEY'] }
  config.filter_sensitive_data('<HELLO_SIGN_API_KEY>') { ENV['HELLO_SIGN_API_KEY'] }
  config.filter_sensitive_data('<HELLO_SIGN_CLIENT_ID>') { ENV['HELLO_SIGN_CLIENT_ID'] }
  config.filter_sensitive_data('<CODE_OF_CONDUCT_DOCUMENT_URL>') { ENV['CODE_OF_CONDUCT_DOCUMENT_URL'] }
  config.filter_sensitive_data('<REFUND_POLICY_DOCUMENT_URL>') { ENV['REFUND_POLICY_DOCUMENT_URL'] }
  config.filter_sensitive_data('<ENROLLMENT_AGREEMENT_TEMPLATE_ID>') { ENV['ENROLLMENT_AGREEMENT_TEMPLATE_ID'] }
  config.filter_sensitive_data('<CLOSE_IO_API_KEY>') { ENV['CLOSE_IO_API_KEY'] }
  config.filter_sensitive_data('<GITHUB_CLIENT_ID>') { ENV['GITHUB_CLIENT_ID'] }
  config.filter_sensitive_data('<GITHUB_CLIENT_SECRET>') { ENV['GITHUB_CLIENT_SECRET'] }
  config.filter_sensitive_data('<LESS_ACCOUNTING_API_KEY>') { ENV['LESS_ACCOUNTING_API_KEY'] }
  config.filter_sensitive_data('<LESS_ACCOUNTING_EMAIL>') { ENV['LESS_ACCOUNTING_EMAIL'] }
  config.filter_sensitive_data('<LESS_ACCOUNTING_PASSWORD>') { ENV['LESS_ACCOUNTING_PASSWORD'] }
end

Billy.configure do |c|
  c.cache = true
  c.persist_cache = true
  # c.non_whitelisted_requests_disabled = true
  c.dynamic_jsonp = true
  c.dynamic_jsonp_keys = ["callback", "stripe_xdm_c", "stripe_xdm_e", "timestamp"]
  c.cache_path = 'spec/cassettes/javascript/'
  c.non_successful_error_level = :warn
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter,
]
SimpleCov.start

OmniAuth.config.test_mode = true
