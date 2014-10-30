module ApplicationHelper
  def flash_notice(flash, &block)
    flash_class = 'alert alert-success' if flash[:notice]
    flash_class = 'alert alert-danger'  if flash[:alert]
    content_tag(:div, class: flash_class, &block)
  end

  def markdown(text)
    html = HTMLRenderer.new(:prettify => true)
    markdown = Redcarpet::Markdown.new(html, :space_after_headers => true,
                                             :fenced_code_blocks => true)
    markdown.render(text).html_safe
  end

  def colorize_grade(grade)
    grade_class = grade.score.value > 1 ? 'happy-grade' : 'sad-grade'
    content_tag(:span, grade.score.description, class: [grade_class, 'pull-right'])
  end
end
