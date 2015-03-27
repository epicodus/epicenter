describe BillingTasks do
  describe '.escrow_balance' do
    it "returns the current escrow balance amount" do
      mine = double('mine')
      allow(Balanced::Marketplace).to receive(:mine) { mine }
      allow(mine).to receive(:in_escrow) { 21000 }
      expect(BillingTasks.escrow_balance).to eq 21000
    end
  end

  describe '.transfer_full_escrow_balance' do
    it "does nothing if balance is zero" do
      mine = double('mine')
      allow(Balanced::Marketplace).to receive(:mine) { mine }
      allow(mine).to receive(:in_escrow) { 0 }

      owner_customer = double('owner_customer')
      allow(mine).to receive(:owner_customer) { owner_customer }

      BillingTasks.transfer_full_escrow_balance

      expect(mine).to_not have_received(:owner_customer)
    end

    it "pays out the full escrow balance to the Balanced owner bank account" do
      mine = double('mine')
      allow(mine).to receive(:in_escrow) { 21000 }
      allow(Balanced::Marketplace).to receive(:mine) { mine }

      first = spy('first')
      allow(mine).to receive_message_chain(:owner_customer, :bank_accounts, :first).and_return(first)

      BillingTasks.transfer_full_escrow_balance
      expect(first).to have_received(:credit).with(
        :amount => 21000,
        :description => 'Tuition payments withdrawal'
      )
    end
  end

  describe ".billable_today", :vcr do
    it "includes users that have not been billed in the last month" do
      student = FactoryGirl.create(:user_with_recurring_due)
      expect(BillingTasks.billable_today).to eq [student]
    end

    it "does not include users that have been billed in the last month" do
      bank_account = FactoryGirl.create(:user_with_recurring_not_due)
      expect(BillingTasks.billable_today).to eq []
    end

    it "doesn't matter if previous payments get updated" do
      student = FactoryGirl.create(:user_with_recurring_not_due)
      old_payment = FactoryGirl.create(:payment, student: student, created_at: 6.weeks.ago)
      newer_payment = FactoryGirl.create(:payment, student: student, created_at: 2.weeks.ago)
      old_payment.update(updated_at: Date.today)
      expect(BillingTasks.billable_today).to eq []
    end

    it "only includes users that are recurring_active" do
      student = FactoryGirl.create(:user_with_recurring_due)
      student.update(recurring_active: false)
      expect(BillingTasks.billable_today).to eq []
    end

    it "handles months with different amounts of days" do
      student = nil
      travel_to(Date.parse("January 31, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("March 1, 2014")) do
        expect(BillingTasks.billable_today).to eq [student]
      end
    end

    it "disregards the time of day the last payment was made" do
      student = nil
      travel_to(Time.parse("January 1, 2014 2:00pm")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("February 1, 2014 1:00pm")) do
        expect(BillingTasks.billable_today).to eq [student]
      end
    end
  end

  describe ".billable_in_three_days", :vcr do
    it 'tells you which users are billable in three days' do
      student = nil
      travel_to(Date.parse("January 5, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(BillingTasks.billable_in_three_days).to eq [student]
      end
    end

    it 'works even if the payment is made at a different time than the method is run' do
      student = nil
      travel_to(Time.new(2014, 1, 5, 12, 0, 0, 0)) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Time.new(2014, 2, 2, 15, 0, 0, 0)) do
        expect(BillingTasks.billable_in_three_days).to eq [student]
      end
    end

    it 'does not include users that are billable in more than three days' do
      student = nil
      travel_to(Date.parse("January 6, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(BillingTasks.billable_in_three_days).to eq []
      end
    end

    it 'does not include users that are billable in less than three days' do
      student = nil
      travel_to(Date.parse("January 4, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(BillingTasks.billable_in_three_days).to eq []
      end
    end
  end

  describe ".email_upcoming_payees" do
    it "emails users who are due in 3 days", :vcr do
      student = nil
      travel_to(Date.parse("January 5, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      travel_to(Date.parse("February 2, 2014")) do
        BillingTasks.email_upcoming_payees
      end

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { :from => ENV['FROM_EMAIL_PAYMENT'],
          :to => student.email,
          :subject => "Upcoming Epicodus tuition payment",
          :text => "Hi #{student.name}. This is just a reminder that your next Epicodus tuition payment will be withdrawn from your bank account in 3 days. If you need anything, reply to this email. Thanks!" }
      )
    end
  end

  describe ".bill_bank_accounts", :vcr do
    it "bills all bank_accounts that are due today" do
      student = FactoryGirl.create(:user_with_recurring_due)
      expect { BillingTasks.bill_bank_accounts }.to change { student.payments.count }.by 1
    end

    it "does not bill bank accounts that are not due today" do
      student = FactoryGirl.create(:user_with_recurring_not_due)
      expect { BillingTasks.bill_bank_accounts }.to change { student.payments.count }.by 0
    end
  end
end
