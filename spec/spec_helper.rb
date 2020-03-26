require 'simplecov'
SimpleCov.start do
  add_filter 'spec/'
  add_filter 'lib/omniauth-cognito-idp/version'
end
#
require 'pry'
require 'omniauth-cognito-idp'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.raise_errors_for_deprecations!
  config.order = 'random'
end
