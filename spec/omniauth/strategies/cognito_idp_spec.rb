# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniAuth::Strategies::CognitoIdP do
  subject { strategy }

  let(:strategy) { described_class.new(app, client_id, client_secret, options) }

  let(:app) { ->(_env) { [200, '', {}] } }
  let(:options) { {} }
  let(:client_id) { 'ABCDE' }
  let(:client_secret) { '987654321' }
  let(:site) { "http://localhost/auth/cognito-idp/callback" }

  around do |example|
    OmniAuth.config.test_mode = true

    example.run

    OmniAuth.config.test_mode = false
  end

  it_behaves_like 'an oauth2 strategy'

  describe '#build_access_token' do
    subject do
      described_class.new(client_id, client_secret, options).tap do |strategy|
        allow(strategy).to receive(:client).and_return(oauth_client)
        allow(strategy).to receive(:request).and_return(request)
        allow(strategy).to receive(:callback_url).and_return(callback_url)
      end
    end

    let(:oauth_client) { double('OAuth2::Client', auth_code: auth_code, site: site) }
    let(:auth_code) { double('OAuth2::AuthCode', get_token: access_token_object) }
    let(:access_token_object) { double('OAuth2::AccessToken') }
    let(:callback_url) { "#{site}?code=1234" }

    let(:request) { double('Rack::Request', params: params) }
    let(:params) { { 'code' => '12345' } }

    it 'does not send the query part of the request URL as callback URL' do
      expect(auth_code).to receive(:get_token).with(
        params['code'],
        { redirect_uri: callback_url.split('?').first }.merge(subject.token_params.to_hash(symbolize_keys: true)),
        subject.__send__(:deep_symbolize, subject.options.auth_token_params)).and_return(access_token_object)

      expect(subject.__send__(:build_access_token)).to eql access_token_object
    end
  end

  describe 'auth hash' do
    let(:options) { { aws_region: 'eu-west-1', user_pool_id: 'user_pool_id' } }

    let(:auth_hash) { env['omniauth.auth'] }

    let(:env) { {} }
    let(:request) { double('Rack::Request', params: {'state' => strategy.session['omniauth.state']}) }
    let(:session) { { 'omniauth.state' => 'some_state' } }
    let(:oauth_client) { double('OAuth2::Client', auth_code: auth_code, site: site) }
    let(:auth_code) { double('OAuth2::AuthCode') }
    let(:access_token_object) { OAuth2::AccessToken.from_hash(oauth_client, token_hash) }

    let(:token_hash) do
      {
        'expires_at' => token_expires.to_i,
        'access_token' => access_token_string,
        'refresh_token' => refresh_token_string,
        'id_token' => id_token_string
      }
    end

    let(:now) { Time.now }
    let(:token_expires) { now + 3600 }
    let(:access_token_string) { 'access_token' }
    let(:refresh_token_string) { 'refresh_token' }

    let(:id_sub) { '1234-5678-9012' }
    let(:id_phone) { 'some phone number' }
    let(:id_email) { 'some email address' }
    let(:id_name) { 'Some Name' }

    let(:id_token_string) do
      JWT.encode(
        {
          sub: id_sub,
          iat: now.to_i,
          iss: "https://cognito-idp.eu-west-1.amazonaws.com/user_pool_id",
          nbf: now.to_i,
          exp: token_expires.to_i,
          aud: strategy.options[:client_id],
          phone_number: id_phone,
          email: id_email,
          name: id_name
        },
        '12345'
      )
    end

    let(:callback_url) { 'http://localhost/auth/cognito-idp/callback?code=1234' }

    before do
      allow(strategy).to receive(:env).and_return(env)
      allow(strategy).to receive(:session).and_return(session)
      allow(strategy).to receive(:request).and_return(request)
      allow(strategy).to receive(:callback_url).and_return(callback_url)
      allow(strategy).to receive(:client).and_return(oauth_client)

      allow(auth_code).to receive(:get_token).and_return(access_token_object)

      strategy.callback_phase
    end

    describe ':uid' do
      it 'includes the `sub` claim from the ID token' do
        expect(auth_hash[:uid]).to eql id_sub
      end
    end

    describe ':info' do
      it 'includes name, email and phone' do
        expect(auth_hash[:info]).to eql('name' => id_name, 'email' => id_email, 'phone' => id_phone)
      end
    end

    describe ':credentials' do
      it 'contains all tokens' do
        expect(auth_hash[:credentials]).to eql(
          'expires' => true,
          'expires_at' => token_expires.to_i,
          'id_token' => id_token_string,
          'refresh_token' => refresh_token_string,
          'token' => access_token_string
        )
      end
    end

    describe ':extra' do
      it 'contains the parsed data from the id token' do
        expect(auth_hash[:extra])
          .to eql('raw_info' => {'sub' => id_sub, 'phone_number' => id_phone, 'email' => id_email, 'name' => id_name})
      end
    end
  end
end
