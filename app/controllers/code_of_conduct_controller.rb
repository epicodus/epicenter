class CodeOfConductController < SignaturesController

  def new
    signature = CodeOfConduct.create(student_id: current_student.id)
    @sign_url = signature.sign_url
    @controller_for_next_page = 'refund_policy'
    super
  end
end
