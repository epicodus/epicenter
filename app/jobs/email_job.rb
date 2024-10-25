# disable queueing!!
class EmailJob
  def self.perform_later(args)
    EmailClient.create.send_message(ENV['MAILGUN_DOMAIN'], args)
  end
end

# class EmailJob < ApplicationJob
#   queue_as :default
#   def perform(args)
#     EmailClient.create.send_message(ENV['MAILGUN_DOMAIN'], args)
#   end
# end
