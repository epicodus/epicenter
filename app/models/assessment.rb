class Assessment < ActiveRecord::Base
  validates_presence_of :title, :section, :url

  has_many :assessment_requirements
end
