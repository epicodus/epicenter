class CodeReviewsController < ApplicationController
  authorize_resource

  def new
    @code_review = CodeReview.new
    @course = Course.find(params[:course_id])
    3.times { @code_review.objectives.build }
  end

  def create
    @code_review = CodeReview.new(code_review_params)
    if @code_review.save
      redirect_to @code_review, notice: "Code review has been saved!"
    else
      @course = Course.find(params[:course_id])
      render 'new'
    end
  end

  def show
    @code_review = CodeReview.find(params[:id])
    @submission = @code_review.submission_for(current_student) || Submission.new(code_review: @code_review)
  end

  def edit
    @code_review = CodeReview.find(params[:id])
    @course = Course.find(params[:course_id])
  end

  def update
    @code_review = CodeReview.find(params[:id])
    if @code_review.update(code_review_params)
      redirect_to @code_review, notice: "Code review updated."
    else
      @course = Course.find(params[:course_id])
      render 'edit'
    end
  end

  def destroy
    @code_review = CodeReview.find(params[:id])
    if @code_review.destroy
      redirect_to course_path(current_admin.current_course), alert: "#{@code_review.title} has been deleted."
    else
      @submission = @code_review.submission_for(current_student) || Submission.new(code_review: @code_review)
      render 'show'
    end
  end

  def update_multiple
    CodeReview.update(params[:code_reviews].keys, params[:code_reviews].values)
    redirect_to :back, notice: 'Order has been saved.'
  end

private

  def code_review_params
    params.require(:code_review).permit(:course_id, :title, :section, :url, :submissions_not_required, objectives_attributes: [:id, :content, :_destroy])
  end
end
