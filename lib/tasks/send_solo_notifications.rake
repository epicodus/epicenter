desc "notify teacher of full-time students soloing today"
task :send_solo_notifications => [:environment] do
  Course.current_courses.fulltime_courses.non_internship_courses.where.not(track_id: nil).each do |course|
    if course.is_class_day? && !Time.zone.now.to_date.friday? && Time.zone.now > (course.start_time_today + 105.minutes) && Time.zone.now < (course.start_time_today + 160.minutes)
      students = []
      course.students.each do |student|
        students << student if student.signed_in_today? && student.attendance_records.today.first.pair_ids.empty?
      end
      if students.any? && Rails.env.production?
        Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
          { :from => "no-reply@epicodus.com",
            :to => "#{course.admin.email}",
            :subject => "#{course.description}: #{students.count} solo today",
            :text => students.map {|s| s.name}.join(', ') })
      elsif students.any?
        puts "#{course.description}: #{students.count} solo today"
        puts students.map {|s| s.name}.join(', ')
        puts ''
      end
    end
  end
end
