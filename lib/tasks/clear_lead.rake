desc "clear all CRM lead fields filled in by Epicenter"
task :clear_lead, [:email] => [:environment] do |t, args|
  email = args.email || ""
  while email == ""
    puts "Enter email:"
    email = STDIN.gets.chomp
  end
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  lead_id = close_io_client.list_leads('email: "' + email + '"')['data'].first['id']
  close_io_client.update_lead(lead_id, { 'custom.Cohort - Starting': nil })
  close_io_client.update_lead(lead_id, { 'custom.Cohort - Current': nil })
  close_io_client.update_lead(lead_id, { 'custom.Start Date': nil })
  close_io_client.update_lead(lead_id, { 'custom.End Date': nil })
  close_io_client.update_lead(lead_id, { 'custom.Payment plan': nil })
  close_io_client.update_lead(lead_id, { 'custom.Amount paid': nil })
  close_io_client.update_lead(lead_id, { 'custom.Signed internship agreement?': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Birth Date': nil })
  close_io_client.update_lead(lead_id, { 'custom.* Internship class': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Disability': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Veteran': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Education': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - CS Degree': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Previous job': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Previous salary': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Shirt size': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Gender': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Pronouns': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Race': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - After graduation plan': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Time off planned': nil })
  close_io_client.update_lead(lead_id, { 'custom.Demographics - Encrypted SSN': nil })
  close_io_client.update_lead(lead_id, { 'addresses': nil })
end
