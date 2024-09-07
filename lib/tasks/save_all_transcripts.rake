# USAGE: before running, brew install wkhtmltopdf
require 'wicked_pdf'

task :save_all_transcripts => [:environment] do
  students = Student.select {|s| s.courses.any?}
  puts "Total students: #{students.count}"
  students.each do |student|
    puts student.email
    @student = student
    @completed_courses = student.courses.order(:start_date)

    html = ActionController::Base.new.render_to_string(
      template: 'transcripts/_transcript',
      locals: { student: @student, completed_courses: @completed_courses }
    )

    pdf = WickedPdf.new.pdf_from_string(html)

    file_path = Rails.root.join('transcripts-output', "#{student.name.parameterize}_#{student.email}.pdf")
    File.open(file_path, 'wb') do |file|
      file << pdf
    end
  end
end
