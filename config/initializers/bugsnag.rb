require 'bugsnag'
Bugsnag.configure do |config|
  config.discard_classes << "ActiveRecord::RecordNotFound"
  config.discard_classes << "ActionController::RoutingError"
end
