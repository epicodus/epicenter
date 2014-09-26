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

  def self.graded_by_assessment
    result = {}
    self.all.each do |assessment|
      result[assessment.title] = assessment.submissions.assessed.count
    end
    result
  end

  def self.students_by_assessment
    last_assessments = User.students.map { |student| student.last_assessment }
    last_assessments.each_with_object(Hash.new(0)) { |assessment,counts| counts[assessment] += 1 }
    binding.pry
  end

  def self.analysis_by_assessment
    [{"name" => "submitted", "data" => self.submissions_by_assessment}, {"name" => "graded", "data" => self.graded_by_assessment}]
  end
end
