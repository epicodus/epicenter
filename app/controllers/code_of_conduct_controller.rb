class CodeOfConductController < SignaturesController

  def new
    if current_user.completed_signatures == 0
      signature = CodeOfConduct.create(student_id: current_student.id)
      @sign_url = signature.sign_url
      @controller_for_next_page = 'refund_policy'
      super
    else
      redirect_to root_path
    end
  end
end
