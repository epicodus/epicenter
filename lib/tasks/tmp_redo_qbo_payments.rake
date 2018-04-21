desc "Redo logging of QBO payments"
task :tmp_redo_qbo_payments => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'tmp_redo_qbo_payments.txt')
  File.open(filename, 'w') do |file|

    # Payment.order(:created_at).each do |payment|
    #   if payment.category == 'upfront'
    #     date = Date.parse(payment.description.split('; ')[1])
    #     if date.year == 2018
    #       student = Student.with_deleted.find_by_id(payment.student_id)
    #       unless student.starting_cohort == student.cohort && student.cohort == student.ending_cohort
    #         puts "#{student.email} | #{payment.description}"
    #       end
    #     end
    #   end
    # end

    Student.where.not(ending_cohort: nil).each do |student|
      if student.courses.fulltime_courses.any? && student.courses.parttime_courses.empty?
        start_date = student.courses.fulltime_courses.order(:start_date).first.start_date
        end_date = student.courses.fulltime_courses.order(:start_date).last.end_date
        puts "#{student.ending_cohort.end_date.to_s} | #{end_date.to_s} | #{student.email}"
      end
    end

  end

  # if Rails.env.production?
  #   mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
  #   mb_obj = Mailgun::MessageBuilder.new()
  #   mb_obj.set_from_address("it@epicodus.com");
  #   mb_obj.add_recipient(:to, "mike@epicodus.com");
  #   mb_obj.set_subject("rake task: tmp_redo_qbo_payments");
  #   mb_obj.set_text_body("rake task: tmp_redo_qbo_payments");
  #   mb_obj.add_attachment(filename, "tmp_redo_qbo_payments.txt");
  #   result = mg_client.send_message("epicodus.com", mb_obj)
  #   puts result.body.to_s
  #   puts "Sent #{filename.to_s}"
  # else
  #   puts "Exported #{filename.to_s}"
  # end
end
