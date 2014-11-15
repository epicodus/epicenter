class AssessmentsController < ApplicationController
  authorize_resource

  def index
    cohort = Cohort.find(params[:cohort_id])
    @assessments = cohort.assessments
    authorize! :read, cohort
  end

  def new
    @assessment = Assessment.new
    3.times { @assessment.requirements.build }
  end

  def create
    @assessment = Assessment.new(assessment_params)
    if @assessment.save
      redirect_to @assessment, notice: "Assessment has been saved!"
    else
      render 'new'
    end
  end

  def show
    @assessment = Assessment.find(params[:id])
    @submission = @assessment.submission_for(current_student) || Submission.new(assessment: @assessment)
    authorize! :show, @assessment # I dont't know what this is necessary. Should be handled by authorize_resource above.
  end

  def edit
    @assessment = Assessment.find(params[:id])
  end

  def update
    @assessment = Assessment.find(params[:id])
    if @assessment.update(assessment_params)
      redirect_to @assessment, notice: "Assessment updated."
    else
      render 'edit'
    end
  end

  def destroy
    @assessment = Assessment.find(params[:id])
    @assessment.destroy
    redirect_to cohort_assessments_path(current_admin.current_cohort), alert: "#{@assessment.title} has been deleted."
  end

  def update_multiple
    Assessment.update(params[:assessments].keys, params[:assessments].values)
    redirect_to :back, notice: 'Order has been saved.'
  end

private

  def assessment_params
    params.require(:assessment).permit(:title, :section, :url, requirements_attributes: [:id, :content, :_destroy]).merge(cohort_id: current_admin.current_cohort.id)
  end
end
