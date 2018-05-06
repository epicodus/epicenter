describe PaymentBase do
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  it { should belong_to :student }
  it { should validate_presence_of(:category).on(:create) }

  before { allow_any_instance_of(CrmLead).to receive(:status) }

  describe 'scopes' do
    describe '.order_by_latest scope' do
      it 'orders by created_at, descending', :vcr, :stripe_mock, :stub_mailgun do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
        payment_one = FactoryBot.create(:payment_with_credit_card, student: student)
        payment_two = FactoryBot.create(:payment_with_credit_card, student: student)
        expect(Payment.order_by_latest).to eq [payment_two, payment_one]
      end
    end

    describe '.without_failed' do
      it "doesn't include failed payments", :vcr, :stripe_mock, :stub_mailgun do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
        failed_payment = FactoryBot.create(:payment_with_credit_card, student: student)
        failed_payment.update(status: 'failed')
        expect(Payment.without_failed).to eq []
      end
    end

    describe '.without_offline' do
      it "doesn't include offline payments", :vcr, :stripe_mock, :stub_mailgun do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
        offline_payment = FactoryBot.create(:payment_with_credit_card, student: student, offline: true)
        expect(Payment.without_offline).to eq []
      end
    end
  end

  describe '.create' do
    it 'sets offline payment status', :vcr do
      student = FactoryBot.create(:user_with_credit_card)
      payment = FactoryBot.create(:payment, student: student, offline: true, payment_method: student.payment_methods.first)
      expect(payment.status).to eq 'offline'
    end

    describe "sends webhook after successful payment creation", :dont_stub_webhook do
      before { allow(WebhookJob).to receive(:perform_later).and_return({}) }

      it 'posts webhook for a successful stripe payment', :stripe_mock, :stub_mailgun do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
        expect(WebhookJob).to have_received(:perform_later).with(ENV['ZAPIER_WEBHOOK_URL'], PaymentSerializer.new(payment).as_json.merge({ event_name: 'payment_succeeded' }))
      end

      it 'posts webhook after refund issued', :vcr, :stub_mailgun do # using vcr rather than stripe_mock so refund can find original charge
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
        refund = FactoryBot.create(:refund, original_payment: payment, student: student)
        expect(WebhookJob).to have_received(:perform_later).with(ENV['ZAPIER_WEBHOOK_URL'], PaymentSerializer.new(refund).as_json.merge({ event_name: 'refund_succeeded' }))
      end

      it 'posts webhook for an offline payment' do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, offline: true)
        expect(WebhookJob).to have_received(:perform_later).with(ENV['ZAPIER_WEBHOOK_URL'], PaymentSerializer.new(payment).as_json.merge({ event_name: 'payment_offline' }))
      end

      it 'posts webhook for an offline refund' do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, offline: true)
        refund = FactoryBot.create(:refund, original_payment: payment, student: student, offline: true)
        expect(WebhookJob).to have_received(:perform_later).with(ENV['ZAPIER_WEBHOOK_URL'], PaymentSerializer.new(refund).as_json.merge({ event_name: 'refund_offline' }))
      end
    end
  end
end
