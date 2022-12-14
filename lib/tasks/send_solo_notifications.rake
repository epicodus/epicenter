desc "notify teacher of students who signed in solo or with unreciprocated pair today"
$body = ''
task :send_solo_notifications => [:environment] do
  today = Time.zone.now.to_date
  Course.current_courses.non_internship_courses.where.not(track_id: nil).each do |course|
    solo_students = []
    students_who_claimed_extra_pairs = []
    if course.is_class_day? && !today.friday?
      solo_students = Student.where(id: course.students.select {|s| s.signed_in_today? && s.pairs_today.empty?})
      students_who_claimed_extra_pairs = Student.where(id: course.students.select {|s| s.orphan_pairs_today.any?})
      if solo_students.any? || students_who_claimed_extra_pairs.any?

        # generate report
        output("#{today.to_s(:long_ordinal)} Pairing Report", 'h2')
        output(course.description, 'h2')
        if solo_students.any?
          output("#{'Solo'.pluralize(solo_students.count)} today:", 'h3')
          solo_students.reorder(:name).each do |student|
            output(student.name, 'br') unless student.email.include?('example.com') || student.email.include?('epicodus.com')
          end
        end
        if students_who_claimed_extra_pairs.any?
          output("#{students_who_claimed_extra_pairs.count} #{'student'.pluralize(students_who_claimed_extra_pairs.count)} claimed extra pair(s) today:", 'h3')
          students_who_claimed_extra_pairs.reorder(:name).each do |student|
            orphan_pairs = student.orphan_pairs_today.where.not(name: '* ATTENDANCE CORRECTION *')
            output(student.name + ' claimed ' + orphan_pairs.map {|s| s.name}.join(' & '), 'br') unless student.email.include?('example.com') || student.email.include?('epicodus.com')
            end
        end
        output "<a href='#{Rails.application.routes.url_helpers.root_url.delete_suffix('/')}#{Rails.application.routes.url_helpers.course_day_attendance_records_path(course, day: today.to_s)}'>View in Epicenter</a>"

        # output report
        subject = "#{course.description} pairing on #{today.strftime('%b')} #{today.day.ordinalize}: #{solo_students.count} / #{students_who_claimed_extra_pairs.count}"
        if Rails.env.production?
          WebhookEmail.new(email: course.admin.email, subject: subject, body: $body)
        else
          puts "Subject: #{subject}"
          puts $body
          puts ''
        end
        $body = ''

      end
    end
  end
end

def output(text, tag='p')
  if tag == 'br'
    $body << text + '<br>'
  else
    $body << "<#{tag}>" + text + "</#{tag}>"
  end
end