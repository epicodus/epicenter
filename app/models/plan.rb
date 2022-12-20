class Plan < ApplicationRecord
  scope :active, -> { where(archived: nil).order(:order) }
  scope :standard, -> { where(standard: true) }
  scope :upfront, -> { where(upfront: true) }
  scope :loan, -> { where(loan: true) }
  scope :isa, -> { where(isa: true) }
  scope :parttime, -> { where(parttime: true) }
  scope :fulltime, -> { where(parttime: nil) }
  scope :intro, -> { where(short_name: 'intro') }

  has_many :students
  validates :name, presence: true
  validates :upfront_amount, presence: true
end
