# frozen_string_literal: true
#\ -w -p 8678

require 'bundler'
Bundler.setup

require 'omniauth-cognito-idp'
require 'rack/utils'
require 'rack/session/pool'
require 'sinatra/base'

require 'aws-sdk-cognitoidentityprovider'

require 'pry-byebug'
require 'pp'

class TestApp < Sinatra::Base
  use OmniAuth::Strategies::CognitoIdP,
    ENV['COGNITO_CLIENT_ID'],
    ENV['COGNITO_CLIENT_SECRET'],
    client_options: {
      site: ENV['COGNITO_POOL_SITE']
    },
    scope: 'phone email openid aws.cognito.signin.user.admin profile',
    user_pool_id: ENV['COGNITO_POOL_ID'],
    aws_region: ENV['AWS_REGION']

  helpers do
    def h(text)
      Rack::Utils.escape_html(text)
    end

    def cognito_idp_client
      Aws::CognitoIdentityProvider::Client.new(region: ENV['AWS_REGION'])
    end
  end

  get '/' do
    <<-HTML
    <html>
      <head>
        <title>Cognito IdP Test</title>
      </head>
      <body>
        <h1>Welcome</h1>
        <h2>Session Auth</h2>
        <pre>#{session[:auth].pretty_inspect}</pre>
        <h2>Links</h2>
        <ul>
          <li><a href="/auth/cognito_idp">Sign In</a></li>
          <li><a href="/userinfo">Userinfo</a></li>
        </ul>
      </body>
    </html>
    HTML
  end

  get '/userinfo' do
    redirect '/' unless session[:auth]

    userinfo = cognito_idp_client.get_user(access_token: session[:auth][:credentials][:token])

    form_fields = userinfo.user_attributes.reject do |attr|
      %w[sub].include?(attr.name) || attr.name.end_with?('_verified')
    end

    form_inputs = form_fields.map { |attr| <<-HTML }.join("\n")
      <dt><label for="#{attr.name}">#{attr.name}</label></dt>
      <dd><input type="text" name="#{attr.name}" value="#{h(attr.value)}" /></dd>
    HTML

    <<-HTML
    <html>
      <head>
        <title>Cognito IdP Test</title>
      </head>
      <body>
        <h1>User Info From Cognito</h1>
        <pre>#{userinfo.to_h.pretty_inspect}</pre>
        <form action="/userinfo" method="POST">
          #{form_inputs}
          <input type="submit" value="Update" />
        </form>
        <h2>Links</h2>
        <ul>
          <li><a href="/">Home</a></li>
        </ul>
      </body>
    </html>
    HTML
  end

  post '/userinfo' do
    redirect '/' unless session[:auth]

    attributes = params.map { |k, v| {name: k, value: v} }

    result = cognito_idp_client.update_user_attributes(
      user_attributes: attributes,
      access_token: session[:auth][:credentials][:token]
    )

    <<-HTML
    <html>
      <head>
        <title>Cognito IdP Test</title>
      </head>
      <body>
        <h1>Updated User Attributes at Cognito</h1>
        <pre>#{result.to_h.pretty_inspect}</pre>
        <h2>Links</h2>
        <ul>
          <li><a href="/userinfo">Userinfo</a>
          <li><a href="/">Home</a></li>
        </ul>
      </body>
    </html>
    HTML
  end

  get '/auth/:name/callback' do
    auth = request.env['omniauth.auth']

    session[:auth] = auth

    <<-HTML
    <html>
      <head>
        <title>Cognito IdP Test</title>
      </head>
      <body>
        <h1>Authenticated with #{params[:name]}</h1>
        <h2>Authentication Object</h2>
        <pre>#{auth.pretty_inspect}</pre>
        <h2>Links</h2>
        <ul>
          <li><a href="/">Home</a></li>
          <li><a href="/userinfo">Userinfo</a></li>
        </ul>
      </body>
    </html>
    HTML
  end
end

sessioned_app = Rack::Session::Pool.new(TestApp.new, domain: 'localhost')

run sessioned_app
