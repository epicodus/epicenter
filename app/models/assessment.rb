class Assessment < ActiveRecord::Base
  validates_presence_of :title, :section, :url
  has_many :submissions
  has_many :requirements
  has_many :grades, through: :requirements

  def self.submissions_by_assessment
    result = {}
    self.all.each do |assessment|
      result[assessment.title] = assessment.submissions.count
    end
    result
  end

  def self.graded_by_assessment
    result = {}
    self.all.each do |assessment|
      result[assessment.title] = assessment.submissions.assessed.count
    end
    result
  end

  def self.analysis_by_assessment
    [{"name" => "submitted", "data" => self.submissions_by_assessment}, {"name" => "graded", "data" => self.graded_by_assessment}]
  end
end
