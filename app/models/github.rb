class Github
  def self.get_content(github_path)
    repo = github_path.match(/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}\/(.*)\/blob\/master/).try(:values_at, 1).try(:first)
    file = github_path.match(/\/blob\/master\/(.*)/).try(:values_at, 1).try(:first)
    begin
      { content: client.contents("#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/#{repo}", path: "/#{file}", accept: 'application/vnd.github.3.raw') }
    rescue Faraday::Error => e
      { error: true }
    rescue Octokit::NotFound => e
      { error: true }
    end
  end

  def self.get_layout_params(layout_file_path)
    response = get_content(layout_file_path)
    if response[:error]
      throw(:abort)
    else
      YAML.load(response[:content])
    end
  end

  def self.update_code_reviews(params)
    update_modified_code_reviews(params[:repo], params[:modified]) if params[:modified].try(:any?)
    update_removed_code_reviews(params[:repo], params[:removed]) if params[:removed].try(:any?)
  end

  private_class_method def self.update_modified_code_reviews(repo, files)
    files.each do |file|
      code_reviews = CodeReview.where(github_path: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/#{repo}/blob/master/#{file}")
      code_reviews.each do |code_review|
        updated_content = client.contents("#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/#{repo}", path: "/#{file}", accept: 'application/vnd.github.3.raw')
        code_review.update_columns(content: updated_content)
      end
    end
  end

  private_class_method def self.update_removed_code_reviews(repo, files)
    files.each do |file|
      code_reviews = CodeReview.where(github_path: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/#{repo}/blob/master/#{file}")
      code_reviews.each do |code_review|
        code_review.update_columns(content: '')
      end
    end
  end

  private_class_method def self.client
    headers = { "Authorization": "Bearer #{new_jwt_token}", "Accept": 'application/vnd.github.machine-man-preview+json', "user-agent": 'Httparty' }
    access_tokens_url = "https://api.github.com/app/installations/#{ENV['GITHUB_INSTALLATION_ID']}/access_tokens"
    access_tokens_response = HTTParty.post(access_tokens_url, headers: headers)
    access_token = access_tokens_response['token']
    Octokit::Client.new(access_token: access_token)
  end

  private_class_method def self.new_jwt_token
    private_pem = ENV['GITHUB_APP_PEM']
    private_key = OpenSSL::PKey::RSA.new(private_pem)
    payload = { iat: Time.now.to_i, exp: 9.minutes.from_now.to_i, iss: ENV['GITHUB_APP_ID'] }
    JWT.encode(payload, private_key, "RS256")
  end
end
