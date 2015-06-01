class PaymentMethod < ActiveRecord::Base
  scope :not_verified_first, -> { order(verified: :desc) }

  validates :student_id, presence: true

  belongs_to :student
  has_many :payments

  attr_accessor :stripe_token

  def ensure_primary_method_exists
    student.update(primary_payment_method: self) if !student.primary_payment_method
  end

  def create_stripe_account
    begin
      account = student.stripe_customer.sources.create(:source => stripe_token)
      self.stripe_id = account.id
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      false
    end
  end

  def get_last_four_string
    begin
      customer = student.stripe_customer
      stripe_account = customer.sources.retrieve(stripe_id)
      self.last_four_string = stripe_account.last4
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      false
    end
  end
end
