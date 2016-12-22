class CodeReviewExportController < ApplicationController

  def show
    authorize! :manage, CodeReview
    code_review = CodeReview.find(params[:code_review_id])
    filename = Rails.root.join('tmp','students.txt')
    code_review.export_submissions(filename)
    send_file(filename)
  end

end
