# Courses, admin, plan, and scores
course = FactoryBot.create(:course)
past_course = FactoryBot.create(:past_course)
part_time_course = FactoryBot.create(:part_time_course)
FactoryBot.create(:admin, current_course: course)
FactoryBot.create(:upfront_payment_only_plan)
FactoryBot.create(:passing_score)
FactoryBot.create(:in_between_score)
FactoryBot.create(:failing_score)

# Students
15.times do
  FactoryBot.create(:user_with_all_documents_signed, course: course)
  FactoryBot.create(:user_with_all_documents_signed, course: past_course)
  FactoryBot.create(:user_with_all_documents_signed, course: part_time_course)
end

# Code reviews
5.times do
  FactoryBot.create(:code_review, course: course)
  FactoryBot.create(:code_review, course: past_course)
  FactoryBot.create(:code_review, course: part_time_course)
end

# Code review submissions
Student.all.each do |student|
  student.update(sign_in_count: 1)
  code_reviews = CodeReview.where(course_id: student.courses.pluck(:id))
  code_reviews.each do |code_review|
    FactoryBot.create(:submission, code_review: code_review, student: student)
  end
end

# Tracks
Track.create(description: 'Ruby/Rails')
Track.create(description: 'PHP/Drupal')
Track.create(description: 'Java/Android')
Track.create(description: 'C#/.NET')
Track.create(description: 'CSS/Design')
