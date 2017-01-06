class CodeReviewExportController < ApplicationController

  def show
    authorize! :manage, CodeReview
    code_review = CodeReview.find(params[:code_review_id])
    all = params[:all] != nil
    filename = Rails.root.join('tmp','students.txt')
    code_review.export_submissions(filename, all)
    send_file(filename)
  end

end
