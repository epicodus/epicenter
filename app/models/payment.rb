class Payment < PaymentBase
  belongs_to :payment_method, optional: true
  has_many :refunds, class_name: 'Refund', foreign_key: 'original_payment_id'

  validates :amount, presence: true
  validates :payment_method, presence: true, unless: ->(payment) { payment.offline? }

  before_create :make_payment, :send_payment_receipt, unless: ->(payment) { payment.offline? }

  after_update :send_payment_failure_notice, if: ->(payment) { payment.status == "failed" && !payment.failure_notice_sent? }

  def total_amount
    amount + fee
  end

  def total_refunded
    refunds.sum(:refund_amount)
  end

private

# ------------------ BEFORE --------------------

  def check_amount
    if amount <= 0 || amount >= 8500_00
      errors.add(:amount, 'must be positive and less than $8,500.')
      throw :abort
    end
  end

  def set_category
    if student.plan.try(:standard?) && student.payments.any?
      self.category = 'standard'
    elsif student.plan
      self.category = 'upfront'
    else
      errors.add(:base, "No payment plan found.")
      throw :abort
    end
  end

  def set_description
    attendance_status = student.attendance_status
    courses = student.courses.reorder(:start_date)
    if category == 'keycard'
      self.description = 'keycard'
    elsif student.office.nil? && courses.empty?
      self.description = "special: #{student.email} not enrolled in any courses and unknown office"
    elsif student.office.nil?
      student.update(office: courses.first.office)
    else
      if courses.fulltime_courses.any?
        start_date = courses.fulltime_courses.first.start_date.strftime("%Y-%m-%d")
      elsif courses.any?
        start_date = courses.first.start_date.strftime("%Y-%m-%d")
      else
        start_date = 'no enrollments'
      end
      self.description = "#{student.office.name}; #{start_date}; #{attendance_status}; #{category}"
    end
  end


  # ------------------ ACTION --------------------

  def make_payment
    binding.pry
    customer = student.stripe_customer
    self.fee = payment_method.calculate_fee(amount)
    begin
      charge = Stripe::Charge.create(amount: total_amount, currency: 'usd', customer: customer.id, source: payment_method.stripe_id, description: description)
      self.status = payment_method.starting_status
      self.stripe_transaction = charge.balance_transaction
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      throw :abort
    end
  end

  def send_payment_receipt
    binding.pry
    EmailJob.perform_later(
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :bcc => ENV['FROM_EMAIL_PAYMENT'],
        :subject => "Epicodus tuition payment receipt",
        :text => determine_payment_receipt_email_body }
    )
  end

  def determine_payment_receipt_email_body
    binding.pry
    email_body = "Hi #{student.name}. This is to confirm your payment of #{number_to_currency(total_amount / 100.00)} for Epicodus tuition. "
    if student.plan.standard? && student.payments.count == 0
      email_body += "I am going over the payments for your class and just wanted to confirm that you have chosen the #{student.plan.name} plan and that we will be charging you the remaining #{number_to_currency(student.plan.first_day_amount / 100, precision: 0)} on the first day of class. I want to be sure we know your intentions and don't mistakenly charge you. Thanks so much!"
    elsif student.plan.loan? && student.payments.count == 0
      email_body += "I am going over the payments for your class and just wanted to confirm that you have chosen the #{student.plan.name} plan. Since you are in the process of obtaining a loan for program tuition, would you please let me know (which loan company, date you applied, etc.)? I want to be sure we know your intentions and don't mistakenly charge you. Thanks so much!"
    else
      email_body += "Thanks so much!"
    end
  end


  # ------------------ AFTER --------------------

  def update_crm
    binding.pry
    amount_paid = student.total_paid / 100
    if student.payments.count == 1 && student.crm_lead.status == "Applicant - Accepted"
      if student.course.try(:parttime?)
        student.crm_lead.update({ status: "Enrolled - Part-Time", 'custom.Amount paid': amount_paid })
      else
        student.crm_lead.update({ status: "Enrolled", 'custom.Amount paid': amount_paid })
      end
    else
      student.crm_lead.update('custom.Amount paid': amount_paid)
    end
    student.crm_lead.update(note: "PAYMENT #{number_to_currency(amount / 100.00)}: #{notes}")
  end


  # ------------------ ON STRIPE CALLBACK --------------------

  def send_payment_failure_notice
    binding.pry
    EmailJob.perform_later(
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :bcc => ENV['FROM_EMAIL_PAYMENT'],
        :subject => "Epicodus payment failure notice",
        :text => "Hi #{student.name}. This is to notify you that a recent payment you made for Epicodus tuition has failed. Please reply to this email so we can sort it out together. Thanks!" }
    )
    update_attribute(:failure_notice_sent, true)
  end
end
