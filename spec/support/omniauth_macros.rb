module OmniauthMacros
  def mock_auth_hash
     OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
      :provider => 'github',
      :uid => '123545',
      :info => {nickname: 'test-nickname'},
    })
  end

  def mock_auth_hash_fail
    OmniAuth.config.mock_auth[:github] = :invalid_credentials
  end
end
