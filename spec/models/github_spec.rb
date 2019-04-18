describe Github do
  it 'updates code review content based on Github repo name & list of file paths', vcr: true do
    code_review = FactoryBot.create(:code_review, github_path: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md")
    Github.update_code_reviews({ repo: 'testing', modified: ['README.md'], removed: [] })
    expect(code_review.reload.content).to include 'testing'
  end

  it 'clears code review content when removed from Github repo', vcr: true do
    code_review = FactoryBot.create(:code_review, github_path: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md")
    Github.update_code_reviews({ repo: 'testing', modified: [], removed: ['README.md'] })
    expect(code_review.reload.content).to eq ''
  end

  it 'fetches code review content from Github given github_path', vcr: true do
    github_path = "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md"
    expect(Github.get_content(github_path)[:content]).to include 'testing'
  end
end
