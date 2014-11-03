class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  scope :recurring_active, -> { where(recurring_active: true) }

  validates :name, presence: true
  validates :plan_id, presence: true
  validates :cohort_id, presence: true

  belongs_to :plan
  belongs_to :cohort
  has_one :bank_account
  has_one :credit_card
  has_many :payments
  has_many :attendance_records
  has_many :submissions
  has_many :grades

  def self.billable_today
    recurring_active.select do |user|
      user.payments.last.created_at < 1.month.ago
    end
  end

  def self.billable_in_three_days
    recurring_active.select do |user|
      (user.payments.last.created_at - 3.days).to_date == 1.month.ago.to_date
    end
  end

  def self.email_upcoming_payees
    billable_in_three_days.each do |user|
      Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
        "epicodus.com",
        { :from => "michael@epicodus.com",
          :to => user.email,
          :bcc => "michael@epicodus.com",
          :subject => "Upcoming Epicodus tuition payment",
          :text => "Hi #{user.name}. This is just a reminder that your next Epicodus tuition payment will be withdrawn from your bank account in 3 days. If you need anything, reply to this email. Thanks!" }
      )
    end
  end

  def self.bill_bank_accounts
    billable_today.each do |user|
      user.payments.create(amount: user.plan.recurring_amount, payment_method: user.primary_payment_method)
    end
  end

  def has_payment_method
    credit_card.present? || (bank_account.present? && bank_account.verified == true)
  end

  def primary_payment_method
    credit_card.present? ? credit_card : bank_account
  end

  def set_primary_payment_method(payment_method)
    update!(primary_payment_method_id: payment_method.id, primary_payment_method_type: payment_method.class.name)
  end

  def upfront_payment_due?
    plan.upfront_amount > 0 && payments.count == 0
  end

  def recurring_amount_with_fees
    plan.recurring_amount + primary_payment_method.calculate_fee(plan.recurring_amount)
  end

  def upfront_amount_with_fees
    plan.upfront_amount + primary_payment_method.calculate_fee(plan.upfront_amount)
  end

  def ready_to_start_recurring_payments?
    plan.recurring_amount > 0 && recurring_active != true && !upfront_payment_due?
  end

  def signed_in_today?
    attendance_records.today.exists?
  end

  def next_payment_date
    payments.last.created_at + 1.month if recurring_active == true
  end

  def make_upfront_payment
    Payment.create(user: self, amount: plan.upfront_amount, payment_method: primary_payment_method)
  end

  def start_recurring_payments
    payment = Payment.create(user: self, amount: plan.recurring_amount, payment_method: primary_payment_method)
    update!(recurring_active: true) if payment.persisted?
    payment
  end

  def on_time_attendances
    attendance_records.where(tardy: false).count
  end

  def tardies
    attendance_records.where(tardy: true).count
  end

  def absences
    cohort.number_of_days_since_start - attendance_records.count
  end
end
