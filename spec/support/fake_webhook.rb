class FakeWebhook
  def initialize(params)
    @fixture = params[:fixture]
    @host = params[:host]
    @path = params[:path]
    @port = params[:port]
    @token = params[:token] # optional (used for authenticating withdraw_callbacks)
    load_fixture
  end

  def send
    RestClient.post("http://#{@host}:#{@port}#{@path}", @body.to_json, {content_type: :json, accept: :json})
  end

private

  attr_accessor(:body, :connection, :fixture, :headers, :path, :session)

  def load_fixture
    fixture_json = JSON.parse(File.read("#{Rails.root}/spec/fixtures/#{fixture}"))
    @headers = fixture_json.fetch("headers")
    @body = fixture_json.fetch("body").merge(token: @token)
  end
end
