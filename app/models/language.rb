class Language < ActiveRecord::Base
  validates :name, presence: true
  validates :level, presence: true

  has_and_belongs_to_many :tracks
  has_many :courses
end
