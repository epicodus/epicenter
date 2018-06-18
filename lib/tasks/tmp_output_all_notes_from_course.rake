desc "Output all notes from submissions for a course"
task :tmp_output_all_notes_from_course => [:environment] do
  puts "Enter course id"
  course_id = STDIN.gets.chomp
  course = Course.find(course_id)
  filename = File.join(Rails.root.join('tmp'), 'tmp_output_all_notes_from_course.txt')
  File.open(filename, 'w') do |file|
    file.puts ""
    file.puts course.description.upcase
    file.puts ""
    course.code_reviews.each do |cr|
      file.puts cr.title.upcase
      file.puts ""
      cr.submissions.each do |submission|
        submission.notes.each do |note|
          file.puts ""
          file.puts note.content
          file.puts ""
        end
      end
      file.puts "-------------------------------"
    end
  end
  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: tmp_output_all_notes_from_course");
    mb_obj.set_text_body("rake task: tmp_output_all_notes_from_course");
    mb_obj.add_attachment(filename, "tmp_output_all_notes_from_course.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end
