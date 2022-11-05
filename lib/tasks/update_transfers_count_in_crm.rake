desc "update transfers count in CRM"
task :update_transfers_count_in_crm => [:environment] do
  students = Student.where(id: Course.current_and_future_courses.map {|c| c.students}.flatten)
  students.each do |student|
    student.crm_lead.update({ Rails.application.config.x.crm_fields['TRANSFERS'] => [student.enrolled_fulltime_cohorts.count - 1, 0].max })
  end
end