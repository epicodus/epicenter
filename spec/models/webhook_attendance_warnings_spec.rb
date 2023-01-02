describe WebhookAttendanceWarnings do
  before { allow(Webhook).to receive(:send).and_return({}) }

  it 'creates webhook with endpoint' do
    webhook = WebhookAttendanceWarnings.new({ name: 'test', student: 'student@example.com', teacher: 'teacher@example.com', absences: 3.5, class_days: 5 })
    expect(webhook.endpoint).to eq ENV['ZAPIER_ATTENDANCE_WARNINGS_WEBHOOK_URL']
  end

  it 'creates webhook with payload' do
    webhook = WebhookAttendanceWarnings.new({ name: 'test', student: 'student@example.com', teacher: 'teacher@example.com', absences: 3.5, class_days: 5 })
    expect(webhook.payload).to eq ({ name: 'test', student: 'student@example.com', teacher: 'teacher@example.com', absences: 3.5, class_days: 5, auth: ENV['ZAPIER_SECRET_TOKEN'] })
  end
end
