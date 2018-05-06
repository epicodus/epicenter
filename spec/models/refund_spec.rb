describe Refund do
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  it { should belong_to :original_payment }
  it { should validate_presence_of :refund_amount }
  it { should validate_presence_of :refund_date }

  before { allow_any_instance_of(CrmLead).to receive(:status) }

  describe '.create', :vcr, :stub_mailgun do
    let(:student) { FactoryBot.create(:user_with_credit_card, email: 'example@example.com') }
    let(:payment) { FactoryBot.build(:payment_with_credit_card, student: student, payment_method: student.payment_methods.first, amount: 600_00) }

    it 'is unsuccessful with an amount that is negative' do
      refund = FactoryBot.build(:refund, student: student, original_payment: payment, refund_amount: -100_00)
      expect(refund.save).to be false
    end

    it 'is unsuccessful with an amount higher than the original payment' do
      refund = FactoryBot.build(:refund, student: student, original_payment: payment, refund_amount: 700_00)
      expect(refund.save).to be false
    end

    it 'is unsuccessful with an amount higher than unrefunded original payment' do
      FactoryBot.create(:refund, student: student, original_payment: payment, refund_amount: 200_00)
      refund = FactoryBot.build(:refund, student: student, original_payment: payment, refund_amount: 500_00)
      expect(refund.save).to be false
    end

    it 'sets category to refund' do
      refund = FactoryBot.create(:refund, student: student, original_payment: payment, refund_amount: 100_00)
      expect(refund.category).to eq 'refund'
    end

    it 'sets description to match original payment description' do
      refund = FactoryBot.create(:refund, student: student, original_payment: payment, refund_amount: 100_00)
      expect(refund.description).to eq payment.description
    end

    describe 'updates CRM', :dont_stub_crm do
      let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
      let(:lead_id) { close_io_client.list_leads('email:' + student.email)['data'].first['id'] }

      before { allow(CrmUpdateJob).to receive(:perform_later).and_return({}) }

      it 'with new amount paid after refund' do
        refund = FactoryBot.build(:refund, student: student, original_payment: payment, refund_amount: 100_00)
        expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { 'custom.Amount paid': (payment.amount - refund.refund_amount) / 100 })
        refund.save
      end

      it 'with note of refund amount and notes' do
        refund = FactoryBot.build(:refund, student: student, original_payment: payment, refund_amount: 100_00, refund_notes: 'foo')
        expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { note: "PAYMENT REFUND #{number_to_currency(refund.refund_amount / 100.00)}: #{refund.refund_notes}" })
        refund.save
      end
    end

    it 'refunds an offline payment without talking to Stripe or Mailgun' do
      refund = FactoryBot.build(:refund, student: student, original_payment: payment, offline: true)
      expect(refund).to_not receive(:issue_refund)
      expect(refund).to_not receive(:send_refund_receipt)
      refund.save
      expect(payment.total_refunded).to eq refund.refund_amount
    end


    describe 'issues a Stripe refund' do
      it 'refunds a credit card payment' do
        FactoryBot.create(:refund, student: student, original_payment: payment, refund_amount: 100_00)
        expect(payment.total_refunded).to eq 100_00
      end

      it 'refunds a bank account payment' do
        bank_payment = FactoryBot.create(:payment_with_bank_account, amount: 600_00)
        refund = FactoryBot.create(:refund, student: bank_payment.student, original_payment: bank_payment, refund_amount: 100_00)
        expect(bank_payment.total_refunded).to eq 100_00
      end

      it 'issues refund' do
        refund = FactoryBot.build(:refund, student: student, original_payment: payment, refund_amount: 100_00)
        expect(refund).to receive(:issue_refund)
        refund.save
      end

      it 'does not issue refund if already issued' do
        refund = FactoryBot.build(:refund, student: student, original_payment: payment, refund_amount: 100_00, refund_issued: true)
        expect(refund).to_not receive(:issue_refund)
        refund.save
      end
    end

    describe "sends refund receipt" do
      it "emails the student a receipt after successful refund", :vcr do
        allow(EmailJob).to receive(:perform_later).and_return({})
        refund = FactoryBot.build(:refund, student: student, original_payment: payment, refund_amount: 50_00)
        expect(EmailJob).to receive(:perform_later).with(
          { :from => ENV['FROM_EMAIL_PAYMENT'],
            :to => student.email,
            :bcc => ENV['FROM_EMAIL_PAYMENT'],
            :subject => "Epicodus tuition refund receipt",
            :text => "Hi #{student.name}. This is to confirm your refund of $50.00 from your Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
          )
        refund.save
      end
    end
  end
end
