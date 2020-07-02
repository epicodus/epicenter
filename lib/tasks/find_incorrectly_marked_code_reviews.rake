desc "find CRs where needs_review == false && review_status == pending"
task :find_incorrectly_marked_code_reviews => [:environment] do
  submissions = Submission.where(needs_review:false, review_status:'pending').select {|sub| sub.student_id != 3986 && sub.student && sub.student.courses.include?(sub.code_review.course)}

  filename = File.join(Rails.root.join('tmp'), 'find_incorrectly_marked_code_reviews.txt')
  File.open(filename, 'w') do |file|
    submissions.each do |submission|
      file.puts "#{submission.student.email} | #{submission.code_review.course.description} | #{submission.code_review.title}"
    end
  end

  if Rails.env.production? && submissions.any?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("find_incorrectly_marked_code_reviews");
    mb_obj.set_text_body("These code reviews are marked as pending but needs_review may be incorrectly set to false.");
    mb_obj.add_attachment(filename, "find_incorrectly_marked_code_reviews.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  elsif submissions.any?
    puts "Exported #{filename.to_s}"
  else
    puts "No CRs with needs_review incorrectly set to false. :)"
  end
end
