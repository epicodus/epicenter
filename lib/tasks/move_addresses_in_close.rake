desc "copy address field in Close"
task :move_addresses_in_close => [:environment] do
  counter = 0
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  filename = File.join(Rails.root.join('tmp'), 'addresses_moved.txt')
  File.open(filename, 'w') do |file|
    close_io_client.list_leads('"custom.Mailing Address":*', 5000)[:data].each do |lead|
      counter += 1
      if lead.custom['Mailing Address'] != lead['addresses'].first['address_1']
        file.puts "#{lead.contacts.first.name} | #{address}"
      end
      # close_io_client.update_lead(lead.id, addresses: [{ "address_1": address }])
    end
  end
  if counter > 0
    puts "Exported #{filename.to_s}"
  else
    puts "None found."
  end
end
