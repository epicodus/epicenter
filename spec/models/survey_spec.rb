describe Survey do
  let!(:course) { FactoryBot.create(:course) }

  it 'saves survey URL correctly when full code pasted in from surveymonkey' do
    input = '<script>(function(t,e,s,n){var o,a,c;t.SMCX=t.SMCX||[],e.getElementById(n)||(o=e.getElementsByTagName(s),a=o[o.length-1],c=e.createElement(s),c.type="text/javascript",c.async=!0,c.id=n,c.src=["https:"===location.protocol?"https://":"http://","widget.surveymonkey.com/collect/website/js/tRaiETqnLgj758hTBazgd4JtpE_2BzvN0y_2F5yj2I6l3GecJTVxOlGlsNUZGz_2F9oNyq.js"].join(""),a.parentNode.insertBefore(c,a))})(window,document,"script","smcx-sdk");</script><a style="font: 12px Helvetica, sans-serif; color: #999; text-decoration: none;" href=https://www.surveymonkey.com> Create your own user feedback survey </a>'
    code_review = FactoryBot.create(:code_review, course: course, visible_date: Time.zone.now.beginning_of_week + 4.days)
    survey = Survey.new(input: input)
    expect(code_review.reload.survey).to eq 'tRaiETqnLgj758hTBazgd4JtpE_2BzvN0y_2F5yj2I6l3GecJTVxOlGlsNUZGz_2F9oNyq.js'
  end

  it 'does not update survey url for invalid URL' do
    input = 'bad code'
    code_review = FactoryBot.create(:code_review, course: course, visible_date: Time.zone.now.beginning_of_week + 4.days, survey: 'foo.js')
    survey = Survey.new(input: input)
    expect(code_review.reload.survey).to eq 'foo.js'
  end

  it 'does not update survey URL for always visible code reviews' do
    always_visible_code_review = FactoryBot.create(:code_review, course: course, visible_date: nil)
    input = '<script>(function(t,e,s,n){var o,a,c;t.SMCX=t.SMCX||[],e.getElementById(n)||(o=e.getElementsByTagName(s),a=o[o.length-1],c=e.createElement(s),c.type="text/javascript",c.async=!0,c.id=n,c.src=["https:"===location.protocol?"https://":"http://","widget.surveymonkey.com/collect/website/js/tRaiETqnLgj758hTBazgd4JtpE_2BzvN0y_2F5yj2I6l3GecJTVxOlGlsNUZGz_2F9oNyq.js"].join(""),a.parentNode.insertBefore(c,a))})(window,document,"script","smcx-sdk");</script><a style="font: 12px Helvetica, sans-serif; color: #999; text-decoration: none;" href=https://www.surveymonkey.com> Create your own user feedback survey </a>'
    survey = Survey.new(input: input)
    expect(always_visible_code_review.reload.survey).to eq nil
  end

  it 'does not update survey URL for code review not visible this week' do
    previous_week_code_review = FactoryBot.create(:code_review, course: course, visible_date: Time.zone.now - 1.week)
    input = '<script>(function(t,e,s,n){var o,a,c;t.SMCX=t.SMCX||[],e.getElementById(n)||(o=e.getElementsByTagName(s),a=o[o.length-1],c=e.createElement(s),c.type="text/javascript",c.async=!0,c.id=n,c.src=["https:"===location.protocol?"https://":"http://","widget.surveymonkey.com/collect/website/js/tRaiETqnLgj758hTBazgd4JtpE_2BzvN0y_2F5yj2I6l3GecJTVxOlGlsNUZGz_2F9oNyq.js"].join(""),a.parentNode.insertBefore(c,a))})(window,document,"script","smcx-sdk");</script><a style="font: 12px Helvetica, sans-serif; color: #999; text-decoration: none;" href=https://www.surveymonkey.com> Create your own user feedback survey </a>'
    survey = Survey.new(input: input)
    expect(previous_week_code_review.reload.survey).to eq nil
  end
end
