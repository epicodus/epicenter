module ApplicationHelper
  def flash_notice(flash, &block)
    flash_class = 'alert alert-success' if flash[:notice]
    flash_class = 'alert alert-danger'  if flash[:alert]
    content_tag(:div, class: flash_class, &block)
  end

  def hide_navbar
    paths = [new_code_of_conduct_path, new_refund_policy_path, new_enrollment_agreement_path,
             certificate_path, transcript_path, welcome_path, user_session_path,
             new_user_password_path, root_path, new_company_registration_path,
             sign_out_path, sign_in_path, attendance_path]
    true if paths.map { |path| current_page?(path) }.include?(true)
  end

  def set_navbar_link_class(controller_name, &block)
    if params[:controller] == controller_name
      content_tag(:li, class: 'active', &block)
    else
      content_tag(:li, &block)
    end
  end

  def set_nav_link_class(param, &block)
    if params[param]
      content_tag(:li, class: 'active', &block)
    else
      content_tag(:li, &block)
    end
  end
end
