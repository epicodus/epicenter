class Assessment < ActiveRecord::Base
  validates_presence_of :title, :section, :url
  has_many :submissions
  has_many :requirements

  def self.submissions_by_assessment
    result = {}
    self.all.each do |assessment|
      result[assessment.title] = assessment.submissions.count
    end
    result
  end
end
