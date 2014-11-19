class Admin < User
  belongs_to :current_cohort, class_name: 'Cohort'

  before_create :assign_current_cohort


  def self.escrow_balance
    Balanced::Marketplace.mine.in_escrow
  end

  def self.transfer_full_escrow_balance
    if escrow_balance > 0
      Balanced::Marketplace.mine.owner_customer.bank_accounts.first.credit(
        :amount => escrow_balance,
        :description => 'Tuition payments withdrawal'
      )
    end
  end

private

  def assign_current_cohort
    self.current_cohort = Cohort.last
  end
end
