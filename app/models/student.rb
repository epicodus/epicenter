class Student < User
  scope :recurring_active, -> { where(recurring_active: true) }

  validates :plan_id, presence: true
  validates :cohort_id, presence: true

  belongs_to :plan
  belongs_to :cohort
  has_many :bank_accounts
  has_many :credit_cards
  has_many :payments
  has_many :attendance_records
  has_many :submissions
  has_many :grades
  has_many :payment_methods
  belongs_to :primary_payment_method, class_name: 'PaymentMethod'

  def payment_methods_primary_first_then_pending
    (payment_methods.not_verified_first - [primary_payment_method]).unshift(primary_payment_method).compact
  end

  def self.billable_today
    recurring_active.select do |student|
      student.payments.last.created_at.to_date < 1.month.ago
    end
  end

  def self.billable_in_three_days
    recurring_active.select do |student|
      (student.payments.last.created_at - 3.days).to_date == 1.month.ago.to_date
    end
  end

  def self.email_upcoming_payees
    billable_in_three_days.each do |student|
      Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
        "epicodus.com",
        { :from => "michael@epicodus.com",
          :to => student.email,
          :bcc => "michael@epicodus.com",
          :subject => "Upcoming Epicodus tuition payment",
          :text => "Hi #{student.name}. This is just a reminder that your next Epicodus tuition payment will be withdrawn from your bank account in 3 days. If you need anything, reply to this email. Thanks!" }
      )
    end
  end

  def self.bill_bank_accounts
    billable_today.each do |student|
      student.payments.create(amount: student.plan.recurring_amount, payment_method: student.primary_payment_method)
    end
  end

  def set_primary_payment_method(payment_method)
    update!(primary_payment_method_id: payment_method.id)
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
    Payment.create(student: self, amount: plan.upfront_amount, payment_method: primary_payment_method)
  end

  def class_in_session?
    cohort.start_date <= Date.today && cohort.end_date >= Date.today
  end

  def start_recurring_payments
    payment = Payment.create(student: self, amount: plan.recurring_amount, payment_method: primary_payment_method)
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
