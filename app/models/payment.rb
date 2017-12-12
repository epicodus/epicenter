class Payment < ApplicationRecord
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  belongs_to :student
  belongs_to :payment_method, optional: true

  validates :amount, presence: true
  validates :student_id, presence: true
  validates :payment_method, presence: true, unless: ->(payment) { payment.offline? }
  validates :category, presence: true, on: :create, unless: ->(payment) { payment.offline? }

  before_create :check_amount
  before_create :set_category, if: ->(payment) { payment.category == 'tuition' }
  before_create :set_description
  before_create :make_payment, :send_payment_receipt, unless: ->(payment) { payment.offline? }
  before_create :set_offline_status, if: ->(payment) { payment.offline? }
  after_save :update_crm
  before_update :issue_refund, if: ->(payment) { payment.refund_amount? && !payment.offline? && !payment.refund_issued? }
  after_update :send_payment_failure_notice, if: ->(payment) { payment.status == "failed" && !payment.failure_notice_sent? }
  after_create :send_webhook, if: ->(payment) { payment.status == 'succeeded' || payment.status == 'offline' }

  scope :order_by_latest, -> { order('created_at DESC') }
  scope :without_failed, -> { where.not(status: 'failed') }

  def total_amount
    amount + fee
  end

private

  def update_crm
    amount_paid = student.total_paid / 100
    if student.payments.count == 1 && student.crm_lead.status == "Applicant - Accepted"
      student.crm_lead.update({ status: "Enrolled", 'custom.Amount paid': amount_paid })
    else
      student.crm_lead.update('custom.Amount paid': amount_paid)
    end
  end

  def determine_payment_receipt_email_body
    email_body = "Hi #{student.name}. This is to confirm your payment of #{number_to_currency(total_amount / 100.00)} for Epicodus tuition. "
    if student.plan.standard? && student.payments.count == 0
      email_body += "I am going over the payments for your class and just wanted to confirm that you have chosen the #{student.plan.name} plan and that we will be charging you the remaining #{number_to_currency(student.plan.first_day_amount / 100, precision: 0)} on the first day of class. I want to be sure we know your intentions and don't mistakenly charge you. Thanks so much!"
    elsif student.plan.loan? && student.payments.count == 0
      email_body += "I am going over the payments for your class and just wanted to confirm that you have chosen the #{student.plan.name} plan. Since you are in the process of obtaining a loan for program tuition, would you please let me know (which loan company, date you applied, etc.)? I want to be sure we know your intentions and don't mistakenly charge you. Thanks so much!"
    else
      email_body += "Thanks so much!"
    end
  end

  def set_offline_status
    self.status = 'offline'
  end

  def issue_refund
    begin
      charge_id = Stripe::BalanceTransaction.retrieve(stripe_transaction).source
      refund = Stripe::Refund.create(charge: charge_id, amount: refund_amount)
      self.refund_issued = true
      WebhookPayment.new({ event_name: 'payment_refund', payment: self })
      send_refund_receipt
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      throw :abort
    end
  end

  def send_refund_receipt
    EmailJob.perform_later(
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :bcc => ENV['FROM_EMAIL_PAYMENT'],
        :subject => "Epicodus tuition refund receipt",
        :text => "Hi #{student.name}. This is to confirm your refund of #{number_to_currency(refund_amount / 100.00)} from your Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
    )
  end

  def send_payment_receipt
    EmailJob.perform_later(
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :bcc => ENV['FROM_EMAIL_PAYMENT'],
        :subject => "Epicodus tuition payment receipt",
        :text => determine_payment_receipt_email_body }
    )
  end

  def send_payment_failure_notice
    EmailJob.perform_later(
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :bcc => ENV['FROM_EMAIL_PAYMENT'],
        :subject => "Epicodus payment failure notice",
        :text => "Hi #{student.name}. This is to notify you that a recent payment you made for Epicodus tuition has failed. Please reply to this email so we can sort it out together. Thanks!" }
    )
    update_attribute(:failure_notice_sent, true)
  end

  def set_category
    if student.plan.standard? && student.payments.count > 0
      self.category = 'standard'
    else
      self.category = 'upfront'
    end
  end

  def set_description
    courses = student.courses.order(:start_date)
    if courses.any?
      if courses.first.parttime? && courses.fulltime_courses.empty?
        attendance_status = "Part-time"
        start_date = courses.first.start_date.strftime("%Y-%m-%d")
      elsif courses.first.parttime? && courses.fulltime_courses.any?
        attendance_status = "Full-time conversion"
        start_date = courses.fulltime_courses.order(:start_date).first.start_date.strftime("%Y-%m-%d")
      else
        attendance_status = "Full-time"
        start_date = courses.first.start_date.strftime("%Y-%m-%d")
      end
      location = courses.first.office.name
      self.category ||= 'offline'
      self.description = "#{location}; #{start_date}; #{attendance_status}; #{category}; #{student.email}"
    else
      self.description = "student #{student.id} not enrolled in any courses"
    end
  end

  def make_payment
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

  def check_amount
    if amount >= 8500_00
      errors.add(:amount, 'cannot be greater than $8,500.')
      throw :abort
    end
  end

  def send_webhook
    WebhookPayment.new({ event_name: "payment_#{status}", payment: self })
  end
end
