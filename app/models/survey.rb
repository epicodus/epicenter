class Survey
  include ActiveModel::Model

  attr_accessor :url

  def initialize(input:)
    munge_url(input)
    add_to_code_reviews
  end

private
  def munge_url(input)
    if input.include?('/')
      regex = /(?<=widget\.surveymonkey\.com\/collect\/website\/js\/)(.*\.js)/
      results = input.match(regex)
      self.url = results.present? ? results[0] : nil
    elsif input.include?('.js')
      self.url = input
    end
  end

  def add_to_code_reviews
    beginning_of_week = Time.zone.now.beginning_of_week
    end_of_week = beginning_of_week + 5.days
    courses = Course.current_courses.non_internship_courses
    CodeReview.where(course: courses).where('visible_date > ? AND visible_date < ?', beginning_of_week, end_of_week).each do |code_review|
      code_review.survey = url if self.url
      code_review.save(validate: false)
    end
  end
end
