describe GithubCallback do
  it 'returns true if event is push to main branch' do
    github_callback = GithubCallback.new({ 'ref' => 'refs/heads/main' })
    expect(github_callback.push_to_main?).to be true
  end

  it 'calls Github.update_code_reviews with repo and list of files modified' do
    github_callback = GithubCallback.new({ 'ref' => 'refs/heads/main', 'repository' => { 'name' => 'testing' }, 'commits' => [ 'modified' => ['MODIFIED.txt'], 'added' => ['ADDED.txt'], 'removed' => [] ] })
    expect(Github).to receive(:update_code_reviews).with({ repo: 'testing', modified: ['ADDED.txt', 'MODIFIED.txt'], removed: [] })
    github_callback.update_code_reviews
  end

  it 'calls Github.update_code_reviews with repo and list of files removed' do
    github_callback = GithubCallback.new({ 'ref' => 'refs/heads/main', 'repository' => { 'name' => 'testing' }, 'commits' => [ 'modified' => [], 'added' => [], 'removed' => ['REMOVED.txt'] ] })
    expect(Github).to receive(:update_code_reviews).with({ repo: 'testing', modified: [], removed: ['REMOVED.txt'] })
    github_callback.update_code_reviews
  end
end
