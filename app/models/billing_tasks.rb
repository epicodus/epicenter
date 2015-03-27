module BillingTasks
  class << self
    def escrow_balance
      Balanced::Marketplace.mine.in_escrow
    end

    def transfer_full_escrow_balance
      if escrow_balance > 0
        Balanced::Marketplace.mine.owner_customer.bank_accounts.first.credit(
          :amount => escrow_balance,
          :description => 'Tuition payments withdrawal'
        )
      end
    end

    def billable_today
      recurring_students_joined_with_last_payment
        .where('DATE(payments.created_at) <= ?', 1.month.ago.utc) # dates in db are in utc
    end

    def billable_in_three_days
      recurring_students_joined_with_last_payment
        .where('DATE(payments.created_at) = ?', 1.month.ago.utc + 3.days) # dates in db are in utc
    end

    def email_upcoming_payees
      self.billable_in_three_days.each do |student|
        Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
          "epicodus.com",
          { :from => ENV['FROM_EMAIL_PAYMENT'],
            :to => student.email,
            :subject => "Upcoming Epicodus tuition payment",
            :text => "Hi #{student.name}. This is just a reminder that your next Epicodus tuition payment will be withdrawn from your bank account in 3 days. If you need anything, reply to this email. Thanks!" }
        )
      end
    end

    def bill_bank_accounts
      self.billable_today.each do |student|
        student.payments.create(amount: student.plan.recurring_amount, payment_method: student.primary_payment_method)
      end
    end

  private

    def recurring_students_joined_with_last_payment
      Student
        .recurring_active
        .joins(:payments)
        .where(payments: {
          created_at:
            Payment.order(created_at: :desc)
                   .limit(1)
                   .select(:created_at)
                   .from('payments WHERE payments.student_id = users.id')
           }
         )
    end
  end
end
