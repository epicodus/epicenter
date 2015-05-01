class PaymentMethod < ActiveRecord::Base
  scope :not_verified_first, -> { order(verified: :desc) }

  # validates :account_uri, presence: true
  validates :student_id, presence: true

  belongs_to :student
  has_many :payments

  attr_accessor :stripe_token

  def ensure_primary_method_exists
    student.update(primary_payment_method: self) if !student.primary_payment_method
  end
end
