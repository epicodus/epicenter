desc "update transfers count in CRM"
task :tmp_update_transfers_count_in_crm => [:environment] do
  crm_field = Rails.application.config.x.crm_fields['TRANSFERS']
  students = Student.select { |s| s.enrolled_fulltime_cohorts.count > 1 }
  students.each do |student|
    begin
      student.crm_lead.update({ crm_field => student.enrolled_fulltime_cohorts.count - 1 })
    rescue => e
      puts "Error updating transfers count for student #{student.email}: #{e.message}"
      Bugsnag.notify(e)
    end
  end
end
