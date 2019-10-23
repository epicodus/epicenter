class Language < ApplicationRecord
  validates :name, presence: true
  validates :level, presence: true

  has_and_belongs_to_many :tracks
  has_many :courses
  scope :active, -> { where(archived: nil) }
end
