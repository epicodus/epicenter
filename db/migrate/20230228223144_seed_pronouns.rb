class SeedPronouns < ActiveRecord::Migration[7.0]
  def change
    Course.current_and_future_courses.map {|c| c.students}.flatten.each do |student|
      pronouns = student.crm_lead.pronouns
      student.update(pronouns: pronouns) if pronouns
    end
  end
end
