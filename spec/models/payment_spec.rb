describe Payment do
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  it { should belong_to :payment_method }
  it { should validate_presence_of :amount }

  before { allow_any_instance_of(CrmLead).to receive(:status) }

  describe 'validations' do
    context 'if regular payment' do
      before { allow(subject).to receive(:offline?).and_return(false) }
      it { should validate_presence_of :payment_method }
    end

    context 'if offline payment' do
      before { allow(subject).to receive(:offline?).and_return(true) }
      it { should_not validate_presence_of :payment_method }
    end
  end

  describe '#total_amount' do
    it 'returns payment amount plus fees', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
      FactoryBot.create(:payment_with_credit_card, student: student)
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(payment.total_amount).to be 618_21
    end
  end

  describe '#total_refunded' do
    it 'returns total amount of payment refunded', :vcr, :stub_mailgun do # using vcr rather than stripe_mock so refund can find original charge
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      refund1 = FactoryBot.create(:refund, student: student, original_payment: payment, refund_amount: 100_00)
      refund2 = FactoryBot.create(:refund, student: student, original_payment: payment, refund_amount: 200_00)
      expect(payment.total_refunded).to be 300_00
    end
  end

  describe ".create" do
    it 'is unsuccessful with an amount that is negative' do
      student = FactoryBot.create :user_with_credit_card, email: 'example@example.com'
      payment = FactoryBot.build(:payment_with_credit_card, student: student, payment_method: student.payment_methods.first, amount: -100_00)
      expect(payment.save).to be false
    end

    it 'is unsuccessful with an amount that is too high' do
      student = FactoryBot.create :user_with_credit_card, email: 'example@example.com'
      payment = FactoryBot.build(:payment_with_credit_card, student: student, payment_method: student.payment_methods.first, amount: 9250_00)
      expect(payment.save).to be false
    end

    describe "with a bank account", :vcr, :stub_mailgun do
      it "makes a successful payment" do
        student = FactoryBot.create :user_with_verified_bank_account, email: 'example@example.com'
        FactoryBot.create(:payment_with_bank_account, student: student)
        expect(student.reload.payments).to_not eq []
      end

      it "sets the fee for the payment type" do
        student = FactoryBot.create :user_with_verified_bank_account, email: 'example@example.com'
        payment = FactoryBot.create(:payment_with_bank_account, student: student)
        expect(payment.fee).to eq 0
      end

      it "sets the status for the payment type" do
        student = FactoryBot.create :user_with_verified_bank_account, email: 'example@example.com'
        payment = FactoryBot.create(:payment_with_bank_account, student: student)
        expect(payment.status).to eq "pending"
      end
    end

    describe "with a credit card", :vcr, :stripe_mock, :stub_mailgun do
      it "makes a successful payment" do
        student = FactoryBot.create :user_with_credit_card, email: 'example@example.com'
        FactoryBot.create(:payment_with_credit_card, student: student)
        expect(student.reload.payments).to_not eq []
      end

      it "sets the fee for the payment type" do
        student = FactoryBot.create :user_with_credit_card, email: 'example@example.com'
        payment = FactoryBot.create(:payment_with_credit_card, student: student)
        expect(payment.fee).to eq 32
      end

      it "sets the status for the payment type" do
        student = FactoryBot.create :user_with_credit_card, email: 'example@example.com'
        payment = FactoryBot.create(:payment_with_credit_card, student: student)
        expect(payment.status).to eq "succeeded"
      end
    end

    describe 'sets category', :vcr, :stripe_mock, :stub_mailgun do
      let(:student_upfront_plan) { FactoryBot.create :student, email: 'example@example.com' }
      let(:student_standard_plan) { FactoryBot.create :student, email: 'example@example.com', plan: FactoryBot.create(:standard_plan) }

      it 'works for upfront payment' do
        payment = Payment.create(student: student_upfront_plan, category: 'tuition', offline: true, amount: 50_00)
        expect(payment.category).to eq 'upfront'
      end

      it 'works for second payment on plan other than standard' do
        payment = Payment.create(student: student_upfront_plan, category: 'tuition', offline: true, amount: 100_00)
        payment2 = Payment.create(student: student_upfront_plan, category: 'tuition', offline: true, amount: 4700_00)
        expect(payment2.category).to eq 'upfront'
      end

      it 'works for first payment on standard plan' do
        payment = Payment.create(student: student_upfront_plan, category: 'tuition', offline: true, amount: 4700_00)
        expect(payment.category).to eq 'upfront'
      end

      it 'works for second payment on standard plan' do
        payment = Payment.create(student: student_standard_plan, category: 'tuition', offline: true, amount: 100_00)
        payment2 = Payment.create(student: student_standard_plan, category: 'tuition', offline: true, amount: 4700_00)
        expect(payment2.category).to eq 'standard'
      end

      it 'raises error when no payment plan' do
        student = FactoryBot.create(:student, plan: nil)
        payment = Payment.create(student: student, category: 'tuition', offline: true, amount: 100_00)
        expect(payment.save).to eq false
      end
    end

    describe 'sets description', :vcr, :stripe_mock, :stub_mailgun do
      it 'works for full-time' do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, category: 'upfront')
        expect(payment.description).to eq "#{student.courses.first.office.name}; #{student.courses.first.start_date.strftime("%Y-%m-%d")}; Full-time; #{payment.category}"
      end

      it 'works for part-time' do
        part_time_course = FactoryBot.create(:part_time_course)
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', course: part_time_course)
        payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, category: 'part-time')
        expect(payment.description).to eq "#{part_time_course.office.name}; #{part_time_course.start_date.strftime("%Y-%m-%d")}; Part-time; #{payment.category}"
      end

      it 'works for full-time payment after part-time payment' do
        part_time_course = FactoryBot.create(:part_time_course)
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', course: part_time_course)
        first_payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, category: 'part-time')
        full_time_course = FactoryBot.create(:course)
        student.courses.push(full_time_course)
        second_payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, category: 'upfront')
        expect(first_payment.description).to eq "#{part_time_course.office.name}; #{part_time_course.start_date.strftime("%Y-%m-%d")}; Part-time; #{first_payment.category}"
        expect(second_payment.description).to eq "#{full_time_course.office.name}; #{full_time_course.start_date.strftime("%Y-%m-%d")}; Full-time conversion; #{second_payment.category}"
      end

      it 'works for student with known office but no courses' do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
        student.courses.delete_all
        payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
        expect(student.payments.first.description).to eq "#{student.office.name}; no enrollments; no enrollments; #{payment.category}"
      end

      it 'works for student with no office or courses' do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', office: nil)
        student.courses.delete_all
        FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
        expect(student.payments.first.description).to eq "special: #{student.email} not enrolled in any courses and unknown office"
      end

      it 'works for keycard payments' do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
        FactoryBot.create(:payment_with_credit_card, student: student, amount: 25_00, category: 'keycard')
        expect(student.payments.first.description).to eq "keycard"
      end

      it 'updates student office when nil but enrolled in courses' do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', office: nil)
        FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
        expect(student.office).to eq student.course.office
      end
    end

    describe "sends receipt", :vcr, :stripe_mock do
      it "emails the student a receipt after successful payment when the student is on the standard tuition plan" do
        standard_plan = FactoryBot.create(:standard_plan)
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', plan: standard_plan, referral_email_sent: true)

        allow(EmailJob).to receive(:perform_later).and_return({})

        FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)

        expect(EmailJob).to have_received(:perform_later).with(
          { from: ENV['FROM_EMAIL_PAYMENT'],
            to: student.email,
            bcc: ENV['FROM_EMAIL_PAYMENT'],
            subject: "Epicodus tuition payment receipt",
            text: "Hi #{student.name}. This is to confirm your payment of $618.21 for Epicodus tuition. I am going over the payments for your class and just wanted to confirm that you have chosen the Standard tuition plan and that we will be charging you the remaining #{number_to_currency(standard_plan.first_day_amount / 100, precision: 0)} on the first day of class. I want to be sure we know your intentions and don't mistakenly charge you. Thanks so much!" }
        )
      end

      it "emails the student a receipt after successful payment when the student is on the loan plan" do
        loan_plan = FactoryBot.create(:loan_plan)
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', plan: loan_plan)

        allow(EmailJob).to receive(:perform_later).and_return({})

        FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)

        expect(EmailJob).to have_received(:perform_later).with(
          { from: ENV['FROM_EMAIL_PAYMENT'],
            to: student.email,
            bcc: ENV['FROM_EMAIL_PAYMENT'],
            subject: "Epicodus tuition payment receipt",
            text: "Hi #{student.name}. This is to confirm your payment of $618.21 for Epicodus tuition. I am going over the payments for your class and just wanted to confirm that you have chosen the Loan plan. Since you are in the process of obtaining a loan for program tuition, would you please let me know (which loan company, date you applied, etc.)? I want to be sure we know your intentions and don't mistakenly charge you. Thanks so much!" }
        )
      end

      it "emails the student a receipt after successful payment when the student is on the upfront plan" do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')

        allow(EmailJob).to receive(:perform_later).and_return({})

        FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
        FactoryBot.create(:payment_with_credit_card, student: student)

        expect(EmailJob).to have_received(:perform_later).with(
          { from: ENV['FROM_EMAIL_PAYMENT'],
            to: student.email,
            bcc: ENV['FROM_EMAIL_PAYMENT'],
            subject: "Epicodus tuition payment receipt",
            text: "Hi #{student.name}. This is to confirm your payment of $1.32 for Epicodus tuition. Thanks so much!" }
        )
      end
    end

    describe "fails" do
      it "emails the student a failure notice if payment status is updated to 'failed'", :vcr, :stripe_mock do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')

        allow(EmailJob).to receive(:perform_later).and_return({})

        payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
        payment.update(status: 'failed')

        expect(EmailJob).to have_received(:perform_later).with(
          { :from => ENV['FROM_EMAIL_PAYMENT'],
            :to => student.email,
            :bcc => ENV['FROM_EMAIL_PAYMENT'],
            :subject => "Epicodus payment failure notice",
            :text => "Hi #{student.name}. This is to notify you that a recent payment you made for Epicodus tuition has failed. Please reply to this email so we can sort it out together. Thanks!" }
        )
      end

      it "does not email the student a failure notice twice for the same payment", :vcr, :stripe_mock do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')

        allow(EmailJob).to receive(:perform_later).and_return({})

        payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, failure_notice_sent: true)

        expect(EmailJob).to_not receive(:perform_later)
        payment.update(status: 'failed')
      end
    end

    describe 'updates CRM after successful payment', :stub_mailgun, :dont_stub_crm, :vcr do
      let(:student) { FactoryBot.create :user_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com' }
      let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
      let(:lead_id) { close_io_client.list_leads('email:' + student.email)['data'].first['id'] }

      before do
        allow(CrmUpdateJob).to receive(:perform_later).and_return({})
      end

      it 'updates status and amount paid on the first payment' do
        allow_any_instance_of(CrmLead).to receive(:status).and_return("Applicant - Accepted")
        payment = Payment.new(student: student, amount: 270_00, payment_method: student.primary_payment_method, category: 'standard')
        expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { status: "Enrolled", 'custom.Amount paid': payment.amount / 100 })
        payment.save
      end

      it 'updates status for part-time students and amount paid on the first payment' do
        part_time_student = FactoryBot.create(:part_time_student_with_payment_method, email: 'example-part-time@example.com')
        part_time_lead_id = close_io_client.list_leads('email:' + part_time_student.email)['data'].first['id']
        allow_any_instance_of(CrmLead).to receive(:status).and_return("Applicant - Accepted")
        payment = Payment.new(student: part_time_student, amount: 270_00, payment_method: part_time_student.primary_payment_method, category: 'upfront')
        expect(CrmUpdateJob).to receive(:perform_later).with(part_time_lead_id, { status: "Enrolled - Part-Time", 'custom.Amount paid': payment.amount / 100 })
        payment.save
      end

      it 'only updates amount paid on payments beyond the first' do
        payment = Payment.create(student: student, amount: 100_00, payment_method: student.primary_payment_method, category: 'standard')
        payment_2 = Payment.new(student: student, amount: 50_00, payment_method: student.primary_payment_method, category: 'standard')
        expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { 'custom.Amount paid': (payment.amount + payment_2.amount) / 100 })
        payment_2.save
      end

      it 'updates amount paid for offline payments' do
        payment = Payment.create(student: student, amount: 100_00, payment_method: student.primary_payment_method, category: 'standard')
        payment_2 = Payment.new(student: student, amount: 50_00, category: 'standard', offline: true)
        expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { 'custom.Amount paid': (payment.amount + payment_2.amount) / 100 })
        payment_2.save
      end

      it 'adds note to CRM with payment amount' do
        payment = Payment.new(student: student, amount: 100_00, payment_method: student.primary_payment_method, category: 'standard')
        expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { note: "PAYMENT #{number_to_currency(payment.amount / 100.00)}: " })
        payment.save
      end

      it 'adds note to CRM including notes when present' do
        payment = Payment.new(student: student, amount: 100_00, payment_method: student.primary_payment_method, category: 'standard', notes: 'test payment note from api')
        expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { note: "PAYMENT #{number_to_currency(payment.amount / 100.00)}: #{payment.notes}" })
        payment.save
      end
    end
  end
end
