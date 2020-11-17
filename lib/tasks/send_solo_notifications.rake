desc "notify teacher of full-time students soloing today"
task :send_solo_notifications => [:environment] do
  today = Time.zone.now.to_date
  filename = File.join(Rails.root.join('tmp'), 'pairing_report.txt')
  Course.current_courses.non_internship_courses.where.not(track_id: nil).each do |course|
    solo_students = []
    students_who_claimed_extra_pairs = []
    File.open(filename, 'w') do |file|
      if course.is_class_day? && !today.friday? && Time.zone.now > (course.start_time_today + 105.minutes) && Time.zone.now < (course.start_time_today + 160.minutes)
        course.students.each do |student|
          solo_students << student if student.signed_in_today? && student.attendance_records.today.first.pairings.empty?
          students_who_claimed_extra_pairs << student if student.orphan_pairs_today.any?
        end
        puts "Course: #{course.description}"
        file.puts "Course: #{course.description}"
        puts ''
        file.puts ''
        if solo_students.any?
          puts "#{solo_students.count} solo today:"
          file.puts "#{solo_students.count} solo today:"
          puts solo_students.map {|s| s.name}.join(', ')
          file.puts solo_students.map {|s| s.name}.join(', ')
          puts ''
          file.puts ''
        end
        if students_who_claimed_extra_pairs.any?
          puts "#{students_who_claimed_extra_pairs.count} claimed extra pair(s) today:"
          file.puts "#{students_who_claimed_extra_pairs.count} claimed extra pair(s) today:"
          puts students_who_claimed_extra_pairs.map {|s| s.name}.join(', ')
          file.puts students_who_claimed_extra_pairs.map {|s| s.name}.join(', ')
          puts ''
          file.puts ''
        end
      end
    end
    if Rails.env.production? && (solo_students.any? || students_who_claimed_extra_pairs.any?)
      mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      mb_obj = Mailgun::MessageBuilder.new()
      mb_obj.set_from_address("no-reply@epicodus.com");
      mb_obj.add_recipient(:to, "#{course.admin.email}");
      mb_obj.set_subject("#{course.description}: #{solo_students.count} solos; #{students_who_claimed_extra_pairs.count} claimed extra pairs");
      mb_obj.set_html_body("<p>#{today.to_s} pairing report for #{course.description}:<br>Snapshot attached or <a href='#{Rails.application.routes.url_helpers.root_url.delete_suffix('/')}#{Rails.application.routes.url_helpers.course_day_attendance_records_path(course, day: today.to_s)}'>view in Epicenter</a> for up-to-date stats.</p>");
      mb_obj.add_attachment(filename, "pairing_report.txt");
      result = mg_client.send_message("epicodus.com", mb_obj)
      puts result.body.to_s
      puts "Sent #{filename.to_s}"
      File.delete(filename)
    end
  end
end
