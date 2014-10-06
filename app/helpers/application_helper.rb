module ApplicationHelper
  def flash_notice(flash)
    if flash[:notice]
      content_tag :div, class: 'alert alert-success' do
        flash[:notice].html_safe
      end
    elsif flash[:alert]
      content_tag :div, class: 'alert alert-warning' do
        flash[:alert]
      end
    end
  end
end
