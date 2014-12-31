class Student < User
  scope :recurring_active, -> { where(recurring_active: true) }

  validates :plan_id, presence: true
  validates :cohort_id, presence: true
  validate :primary_payment_method_belongs_to_student

  belongs_to :plan
  belongs_to :cohort
  has_many :bank_accounts
  has_many :credit_cards
  has_many :payments
  has_many :attendance_records
  has_many :submissions
  has_many :payment_methods
  belongs_to :primary_payment_method, class_name: 'PaymentMethod'

  def payment_methods_primary_first_then_pending
    (payment_methods.not_verified_first - [primary_payment_method]).unshift(primary_payment_method).compact
  end

  def upfront_payment_due?
    plan.upfront_amount > 0 && payments.without_failed.count == 0
  end

  def recurring_amount_with_fees
    plan.recurring_amount + primary_payment_method.calculate_fee(plan.recurring_amount)
  end

  def upfront_amount_with_fees
    plan.upfront_amount + primary_payment_method.calculate_fee(plan.upfront_amount)
  end

  def ready_to_start_recurring_payments?
    plan.recurring_amount > 0 && !recurring_active && !upfront_payment_due?
  end

  def total_paid
    payments.without_failed.sum(:amount)
  end

  def signed_in_today?
    attendance_records.today.exists?
  end

  def next_payment_date
    payments.without_failed.last.created_at + 1.month if recurring_active
  end

  def make_upfront_payment
    payments.create(amount: plan.upfront_amount, payment_method: primary_payment_method)
  end

  def class_in_session?
    cohort.start_date <= Date.today && cohort.end_date >= Date.today
  end

  def class_over?
    Date.today > cohort.end_date
  end

  def start_recurring_payments
    payment = payments.create(amount: plan.recurring_amount, payment_method: primary_payment_method)
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

private

  def primary_payment_method_belongs_to_student
    if primary_payment_method && primary_payment_method.student != self
      errors.add(:primary_payment_method, 'must belong to you.')
    end
  end
end
