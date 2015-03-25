module ApplicationHelper
  def flash_notice(flash, &block)
    flash_class = 'alert alert-success' if flash[:notice]
    flash_class = 'alert alert-danger'  if flash[:alert]
    content_tag(:div, class: flash_class, &block)
  end

  def fix_url(url)
    unless url.include?("http")
      "http://" + url
    end
  end

  def spacer
    " | "
  end
end
