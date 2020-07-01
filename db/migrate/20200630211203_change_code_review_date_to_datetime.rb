class ChangeCodeReviewDateToDatetime < ActiveRecord::Migration[5.2]
  def up
    add_column :code_reviews, :visible_date, :datetime
    add_column :code_reviews, :due_date, :datetime
    CodeReview.where.not(date:nil).all.each do |cr|
      zone = ActiveSupport::TimeZone[cr.course.office.time_zone]
      if cr.course.parttime?
        visible_date =  zone.local(cr.date.year, cr.date.month, cr.date.day).beginning_of_week + 3.days + 17.hours
        due_date = visible_date + 1.week
      else
        visible_date = zone.local(cr.date.year, cr.date.month, cr.date.day, 8, 0, 0)
        due_date = visible_date + 9.hours
      end
      cr.update_columns(visible_date: visible_date, due_date: due_date)
    end
  end

  def down
    remove_column :code_reviews, :visible_date
    remove_column :code_reviews, :due_date
  end
end
