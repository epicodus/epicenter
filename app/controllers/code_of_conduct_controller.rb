class CodeOfConductController < SignaturesController

  def new
    code_signature = CodeOfConduct.create(student_id: current_student.id)
    @sign_url = code_signature.sign_url
  end
end
