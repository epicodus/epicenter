desc "Update custom field"
task :tmp_update_custom_field => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'tmp_update_custom_field.txt')
  File.open(filename, 'w') do |file|
    close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
    leads = close_io_client.list_leads('"custom.Key Card #":*', 5000)[:data]
    leads.each do |lead|
      email = lead['contacts'].first['emails'].first['email']
      value = lead['custom']['Key Card #'].to_i.to_s
      puts "Updating #{email} Keycard Number field with #{value}"
      close_io_client.update_lead(lead['id'], { 'custom.Keycard Number': value })
    end
  end
end
