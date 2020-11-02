describe Github, :vcr do
  it 'updates code review content based on Github repo name & list of file paths' do
    code_review = FactoryBot.create(:code_review, github_path: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md")
    Github.update_code_reviews({ repo: 'testing', modified: ['README.md'], removed: [] })
    expect(code_review.reload.content).to include 'testing'
  end

  it 'clears code review content when removed from Github repo' do
    code_review = FactoryBot.create(:code_review, github_path: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md")
    Github.update_code_reviews({ repo: 'testing', modified: [], removed: ['README.md'] })
    expect(code_review.reload.content).to eq ''
  end

  it 'updates content for multiple code reviews' do
    code_review_1 = FactoryBot.create(:code_review, github_path: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md")
    code_review_2 = FactoryBot.create(:code_review, github_path: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md")
    Github.update_code_reviews({ repo: 'testing', modified: ['README.md'], removed: [] })
    expect(code_review_1.reload.content).to include 'testing'
    expect(code_review_2.reload.content).to include 'testing'
  end

  it 'clears content for multiple code reviews' do
    code_review_1 = FactoryBot.create(:code_review, github_path: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md")
    code_review_2 = FactoryBot.create(:code_review, github_path: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md")
    Github.update_code_reviews({ repo: 'testing', modified: [], removed: ['README.md'] })
    expect(code_review_1.reload.content).to include ''
    expect(code_review_2.reload.content).to include ''
  end

  it 'fetches code review content from Github given github_path' do
    github_path = "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md"
    expect(Github.get_content(github_path)[:content]).to include 'testing'
  end

  it 'gets cohort layout params based on layout file path' do
    layout_file_path = "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/pt_intro_cohort_layout.yaml"
    params = Github.get_layout_params(layout_file_path)
    expect(params['track']).to eq 'Part-Time Intro to Programming'
    expect(params['course_layout_files']).to eq ["https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/pt_intro_layout.yaml"]
  end

  it 'gets course layout params based on layout file path' do
    layout_file_path = "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/pt_intro_layout.yaml"
    params = Github.get_layout_params(layout_file_path)
    expect(params['part_time']).to eq true
    expect(params['internship']).to eq false
    expect(params['number_of_days']).to eq 23
    expect(params['class_times']['Sunday']).to eq '9:00-17:00'
    expect(params['class_times']['Monday']).to eq '18:00-21:00'
    expect(params['class_times']['Tuesday']).to eq '18:00-21:00'
    expect(params['class_times']['Wednesday']).to eq '18:00-21:00'
    expect(params['code_reviews'].count).to eq 3
  end

  it 'gets course code review layout params based on layout file path' do
    layout_file_path = "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/pt_intro_layout.yaml"
    code_review_params = Github.get_layout_params(layout_file_path)['code_reviews']
    expect(code_review_params.count).to eq 3
    expect(code_review_params.first['title']).to eq 'First PT Intro Code Review'
    expect(code_review_params.first['week']).to eq 2
    expect(code_review_params.first['filename']).to eq "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/test_week/code_review.md"
    expect(code_review_params.first['submissions_not_required']).to eq false
    expect(code_review_params.first['always_visible']).to eq false
    expect(code_review_params.first['objectives']).to eq ['Test objective 1']
    expect(code_review_params.last['title']).to eq 'Third PT Intro Code Review'
    expect(code_review_params.last['week']).to eq 6
    expect(code_review_params.last['filename']).to eq "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/test_week/code_review.md"
    expect(code_review_params.last['submissions_not_required']).to eq false
    expect(code_review_params.last['always_visible']).to eq false
    expect(code_review_params.last['objectives']).to eq ['Test objective 1 for third cr', 'Test objective 2 for third cr', 'Test objective 3 for third cr']
  end

  it 'returns an error when unable to retrieve layout file from Github' do
    allow(Github).to receive(:get_content).and_return({error: true})
    layout_file_path = "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/pt_intro_layout.yaml"
    expect { Github.get_layout_params(layout_file_path) }.to raise_error UncaughtThrowError
  end
end
