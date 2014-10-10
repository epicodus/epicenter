class SubmissionsController < ApplicationController
  def index
    @submissions = Submission.all
  end

  def new
    @submission = Submission.new
  end

  def create
    @assessment = Assessment.find(params[:assessment_id])
    @submission = @assessment.submissions.new(submission_params)
    if @submission.save
      redirect_to @assessment, notice: "Thank you for submitting."
    else
      render 'assessments/show'
    end
  end

  def show
    @submission = Submission.find(params[:id])
  end

  def edit
    @submission = Submission.find(params[:id])
  end

  def update
    @submission = Submission.find(params[:id])
    if @submission.update(submission_params)
      redirect_to submissions_url, notice: "Submission updated!"
    else
      render 'new'
    end
  end

  def destroy
  end

private

  def submission_params
    params.require(:submission).permit(:link)
  end

end
