desc "check if entries exist in Close for given emails"
task :tmp_check_close_entries_exist => [:environment] do
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  counter = 0
  emails = []
  emails.each do |email|
    leads = close_io_client.list_leads('email: "' + email + '"')
    if leads['total_results'] == 0
      puts email
      counter += 1
    end
  end
  puts counter == 0 ? "No missing entries :)" : "#{counter} missing from Close"
end
