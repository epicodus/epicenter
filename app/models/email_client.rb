class EmailClient
  def self.enable_test_mode
    @test_mode = true
  end

  def self.create
    mailgun_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mailgun_client.enable_test_mode! if (@test_mode || Rails.env.development?)
    mailgun_client
  end
end
