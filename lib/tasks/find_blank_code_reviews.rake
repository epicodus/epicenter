desc "find code reviews with no content"
task :find_blank_code_reviews => [:environment] do
  crs = CodeReview.where(course: Course.current_and_future_courses).where(content:'').where.not(title: 'Sign Internship Agreement')
  if crs.any?
    filename = File.join(Rails.root.join('tmp'), 'blank_code_reviews.txt')

    File.open(filename, 'w') do |file|
      crs.each do |cr|
        file.puts "https://epicenter.epicodus.com/courses/#{cr.course.id}/code_reviews/#{cr.id}"
      end
    end

    if Rails.env.production?
      mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      mb_obj = Mailgun::MessageBuilder.new()
      mb_obj.set_from_address("it@epicodus.com");
      mb_obj.add_recipient(:to, "mike@epicodus.com");
      mb_obj.set_subject("Code Reviews with empty content");
      mb_obj.set_text_body("rake task: blank_code_reviews");
      mb_obj.add_attachment(filename, "blank_code_reviews.txt");
      result = mg_client.send_message("epicodus.com", mb_obj)
      puts result.body.to_s
      puts "Sent #{filename.to_s}"
    else
      puts "Exported #{filename.to_s}"
    end
  end
end
