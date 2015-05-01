if Rails.env == 'production'
  Rails.configuration.stripe = {
    :publishable_key => ENV['STRIPE_PUBLIC_KEY']
    :secret_key => ENV['STRIPE_API_KEY']
  }
else
  Rails.configuration.stripe = {
    :publishable_key => ENV['STRIPE_TEST_PUBLIC_KEY']
    :secret_key => ENV['STRIPE_TEST_API_KEY']
  }
end

Stripe.api_key = Rails.configuration.stripe[:secret_key]
