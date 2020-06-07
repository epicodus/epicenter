desc "clear test leads from Epicenter & Close"
task :clear_test_leads => [:environment] do
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  Student.where('name LIKE ?', '%Manual Test%').each do |student|
    lead_id = close_io_client.list_leads('email: "' + student.email + '"')['data'].first['id']
    student.enrollments.destroy_all
    student.really_destroy!
    close_io_client.delete_lead(lead_id)
  end
end
