module ApplicationHelper
  def flash_notice(flash, &block)
    flash_class = 'alert alert-success' if flash[:notice]
    flash_class = 'alert alert-danger'  if flash[:alert]
    content_tag(:div, class: flash_class, &block)
  end

  def set_internship_background(rating)
    if rating
      if rating.interest == "1"
        'green-background'
      elsif rating.interest == "2"
        'yellow-background'
      elsif rating.interest == "3"
        'red-background'
      end
    else
      nil
    end
  end
end
