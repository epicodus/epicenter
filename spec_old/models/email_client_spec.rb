describe EmailClient do
  it 'creates email client with test mode disabled' do
    email_client = EmailClient.create
    expect(email_client.test_mode?).to eq false
  end

  it 'creates email client with test mode enabled' do
    EmailClient.enable_test_mode
    email_client = EmailClient.create
    expect(email_client.test_mode?).to eq true
  end
end
