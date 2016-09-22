class CodeReviewExportController < ApplicationController

  def show
    @code_review = CodeReview.find(params[:code_review_id])
    @submissions = @code_review.submissions.needing_review.includes(:student)
    filename = File.join(Rails.root.join('tmp'), "students.txt")
    File.open(filename, 'w') do |file|
      @submissions.each do |submission|
        file.puts submission.student.name.parameterize + " " + submission.link
      end
    end
    send_file(filename)
  end

end