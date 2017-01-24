class DemographicsController < ApplicationController
  include SignatureUpdater

  before_filter :authenticate_student!

  def new
    update_signature_request
  end

  def create
    genders = params[:genders].select{ |input| ["Female", "Male", "Non-binary", "Transgender"].include?(input) } if params[:genders]
    age = params[:age].to_i if params[:age].to_i != 0
    education = params[:education] if ["High school diploma or equivalent", "Postsecondary certificate", "Some college, no degree", "Associate's degree", "Bachelor's degree", "Master's degree or higher"].include?(params[:education])
    job = params[:job][0...35] if params[:job] && params[:job] != ""
    salary = params[:salary].to_i if params[:salary].to_i != 0
    races = params[:races].select{ |input| ["Asian or Asian American", "American Indian or Alaska Native", "Black or African American", "Hispanic or Latino", "Middle Eastern", "Native Hawaiian or Other Pacific Islander", "White", "Other"].include?(input) } if params[:races]
    veteran = params[:veteran] if ["Yes", "No"].include?(params[:veteran])
    current_student.update_demographics({genders: genders, age: age, education: education, job: job, salary: salary, races: races, veteran: veteran})
    current_student.update(demographics: true)
    redirect_to payment_methods_path
  end
end
