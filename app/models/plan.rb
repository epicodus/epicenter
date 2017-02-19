class Plan < ActiveRecord::Base
  scope :active, -> { where(archived: nil).order(:name) }
  scope :standard, -> { where(standard: true) }
  scope :upfront, -> { where(upfront: true) }
  scope :loan, -> { where(loan: true) }
  scope :parttime, -> { where(parttime: true) }
  scope :fulltime, -> { where(parttime: nil) }
  scope :old_rates, -> { where(start_date: Time.new(2016, 4, 1).to_date) }
  scope :new_rates, -> { where(start_date: Time.new(2017, 5, 22).to_date) }

  has_many :students
  validates :name, presence: true
  validates :upfront_amount, presence: true
end
