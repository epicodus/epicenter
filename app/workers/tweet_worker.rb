class HardWorker
  include Sidekiq::Worker

  def save_tweet(name, count)
    puts 'Doing hard work'
  end
end
