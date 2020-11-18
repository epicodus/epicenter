task :tmp_check_pairings => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'tmp_check_pairings.txt')
  missing = []
  File.open(filename, 'w') do |file|
    AttendanceRecord.where.not(old_pair_ids: []).each do |ar|
      binding.pry unless ar.old_pair_ids.count == ar.pairings.count
      ar.old_pair_ids.each do |pair_id|
        missing << ar unless ar.pairings.find_by(pair_id: pair_id)
      end
    end
    file.puts(missing.pluck(:id).join(', '))
  end
  binding.pry
  puts 'Exported to ' + filename
end
