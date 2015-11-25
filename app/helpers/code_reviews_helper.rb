module CodeReviewsHelper
  def markdown(text)
    html = HTMLRenderer.new(:prettify => true)
    markdown = Redcarpet::Markdown.new(html, :space_after_headers => true,
                                             :fenced_code_blocks => true)
    markdown.render(text).html_safe
  end

  def tr_for_grade(grade, &block)
    case grade.score.value
    when 1
      score_class = 'danger'
    when 2
      score_class = 'warning'
    else
      score_class = 'success'
    end
    content_tag(:tr, class: score_class, &block)
  end

  def submissions_count_badge(code_review)
    unless code_review.submissions.needing_review.empty?
      link_to code_review_submissions_path(code_review) do
        content_tag :span, class: 'pull-right badge badge-info code-review-status' do
          pluralize code_review.submissions.needing_review.count, 'new submission'
        end
      end
    end
  end
end
