class Assessment < ActiveRecord::Base
  validates_presence_of :title, :section, :url

  has_many :requirements
  has_many :submissions
end
