require_relative 'lib/omniauth-cognito-idp/version'

Gem::Specification.new do |s|
  s.name          = 'omniauth-cognito-idp'
  s.version       = OmniAuthCognitoIdP::VERSION
  s.summary       = 'OmniAuth Strategy for Amazon Cognito'
  s.description   = 'Use the Amazon Cognito IdP with OmniAuth'
  s.homepage      = 'http://github.com/Sage/omniauth-cognito-idp'
  s.authors       = ['Sage Business Cloud Accounting API Team']
  s.email         = 'sageoneapi@sage.com'
  s.files         = Dir['{bin,lib}/**/*', 'README.md', 'RELEASE_NOTES.md', 'LICENSE.md']
  s.require_paths = ['lib']

  s.add_dependency 'jwt'
  s.add_dependency 'omniauth-oauth2'

  s.add_development_dependency 'aws-sdk-cognitoidentityprovider'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sinatra'
end
