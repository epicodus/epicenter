require 'hello_sign'
HelloSign.configure do |config|
  config.api_key = ENV['HELLO_SIGN_API_KEY']
end
