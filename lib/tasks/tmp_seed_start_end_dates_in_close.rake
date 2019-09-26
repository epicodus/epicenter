desc "add start and end dates to Close"
task :tmp_seed_start_end_dates_in_close => [:environment] do
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  IGNORE_LIST = ["test@mortalwombat.net", "do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]

  students = Student.with_deleted.select { |s| s.starting_cohort || s.cohort }
  students.each do |student|
    unless IGNORE_LIST.include? student.email
      start_date = student.starting_cohort.try(:start_date)
      end_date  = student.cohort.try(:end_date)
      puts "#{student.email} | #{start_date.try(:to_s)} | #{end_date.try(:to_s)}"
      student.crm_lead.update({ Rails.application.config.x.crm_fields['START_DATE'] => start_date.try(:to_s), Rails.application.config.x.crm_fields['END_DATE'] => end_date.try(:to_s) })
    end
  end
end
