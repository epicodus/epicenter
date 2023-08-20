class SeedCodeReviewVisibilities < ActiveRecord::Migration[7.0]
  def up
    courses = Course.where(cohort: Cohort.current_and_future_cohorts)
    courses.each do |course|
      crvs = []
      is_parttime = course.parttime?
      student_ids = course.students.pluck(:id)
      code_reviews = CodeReview.where(course: course).pluck(:id, :visible_date)
      code_reviews.each do |code_review_id, visible_date|
        student_ids.each do |student_id|
          crvs << {
            student_id: student_id,
            code_review_id: code_review_id,
            always_visible: visible_date.nil?,
            visible_start: visible_date,
            visible_end: visible_date ? calculate_end_date(visible_date, is_parttime) : nil,
            special_permission: nil
          }
        end
      end
      if crvs.any?
        puts "Inserting #{crvs.size} CodeReviewVisibility records for #{course.description}..."
        CodeReviewVisibility.insert_all(crvs)
        puts 'Done inserting CodeReviewVisibility records.'
      else
        puts "No CodeReviewVisibility records to insert for #{course.description}."
      end
    end

    puts 'Updating special permissions...'
    SpecialPermission.find_each do |sp|
      sp.code_review.code_review_visibility_for(sp.student).update(special_permission: true)
    end
    puts 'Done updating special permissions.'
  end

  def down
    CodeReviewVisibility.delete_all
  end

  def calculate_end_date(visible_date, is_parttime)
    visible_date.beginning_of_week(:sunday) + (is_parttime ? 7.days + 9.hours : 8.days + 8.hours)
  end
end
