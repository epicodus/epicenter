class CreditCard < ActiveRecord::Base
  belongs_to :student
  has_many :payments, :as => :payment_method

  validates :credit_card_uri, presence: true
  validates :student_id, presence: true

  before_create :get_last_four_string

  after_create :ensure_primary_method_exists

  def fetch_balanced_account
    Balanced::Card.fetch(credit_card_uri)
  end

  def verified?
    true
  end

  def calculate_fee(amount)
    ((amount / BigDecimal.new("0.971")) + 30).to_i - amount
  end

private
  def ensure_primary_method_exists
    student.set_primary_payment_method(self) if !student.primary_payment_method
  end

  def get_last_four_string
    self.last_four_string = fetch_balanced_account.number
  end
end
