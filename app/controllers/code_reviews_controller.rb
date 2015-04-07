class CodeReviewsController < ApplicationController
  authorize_resource

  def index
    cohort = Cohort.find(params[:cohort_id])
    @code_reviews = cohort.code_reviews
    authorize! :read, cohort # I don't know what this is necessary. Should be handled by authorize_resource above.
  end

  def new
    @code_review = CodeReview.new
    3.times { @code_review.requirements.build }
  end

  def create
    @code_review = CodeReview.new(code_review_params)
    if @code_review.save
      redirect_to @code_review, notice: "Code review has been saved!"
    else
      render 'new'
    end
  end

  def show
    @code_review = CodeReview.find(params[:id])
    @submission = @code_review.submission_for(current_student) || Submission.new(code_review: @code_review)
    authorize! :show, @code_review # I don't know what this is necessary. Should be handled by authorize_resource above.
  end

  def edit
    @code_review = CodeReview.find(params[:id])
  end

  def update
    @code_review = CodeReview.find(params[:id])
    if @code_review.update(code_review_params)
      redirect_to @code_review, notice: "Code review updated."
    else
      render 'edit'
    end
  end

  def destroy
    @code_review = CodeReview.find(params[:id])
    @code_review.destroy
    redirect_to cohort_code_reviews_path(current_admin.current_cohort), alert: "#{@code_review.title} has been deleted."
  end

  def update_multiple
    CodeReview.update(params[:code_reviews].keys, params[:code_reviews].values)
    redirect_to :back, notice: 'Order has been saved.'
  end

private

  def code_review_params
    params.require(:code_review).permit(:title, :section, :url, requirements_attributes: [:id, :content, :_destroy]).merge(cohort_id: current_admin.current_cohort.id)
  end
end
