# frozen_string_literal: true

# Copyright 2018 The Sage Group Plc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'omniauth-oauth2'
require 'jwt'

module OmniAuth
  module Strategies
    # OmniAuth strategy that authenticates against an Amazon Cognito User Pool
    class CognitoIdP < OmniAuth::Strategies::OAuth2
      option :name, 'cognito_idp'
      option :client_options,
        {
          authorize_url: '/oauth2/authorize',
          token_url: '/oauth2/token',
          auth_scheme: :basic_auth
        }
      option :jwt_leeway, 60
      option :user_pool_id, nil
      option :aws_region, nil

      uid do
        parsed_id_token['sub'] if parsed_id_token
      end

      info do
        if parsed_id_token
          {
            name: parsed_id_token['name'],
            email: parsed_id_token['email'],
            phone: parsed_id_token['phone_number']
          }
        end
      end

      credentials do
        { token: access_token.token }.tap do |hash|
          hash[:refresh_token] = access_token.refresh_token if access_token.expires? && access_token.refresh_token
          hash[:expires_at] = access_token.expires_at if access_token.expires?
          hash[:expires] = access_token.expires?
          hash[:id_token] = id_token if id_token
        end
      end

      extra do
        { raw_info: parsed_id_token.reject { |key| %w[iss aud exp iat token_use nbf].include?(key) } }
      end

      private

      # Override this method to remove the query string from the callback_url because Cognito
      # requires an exact match
      def build_access_token
        client.auth_code.get_token(
          request.params['code'],
          { redirect_uri: callback_url.split('?').first }.merge(token_params.to_hash(symbolize_keys: true)),
          deep_symbolize(options.auth_token_params)
        )
      end

      def id_token
        access_token['id_token']
      end

      def parsed_id_token
        return nil unless id_token

        @parsed_id_token ||= ::JWT.decode(
          id_token,
          nil,
          false,
          verify_iss: options[:aws_region] && options[:user_pool_id],
          iss: "https://cognito-idp.#{options[:aws_region]}.amazonaws.com/#{options[:user_pool_id]}",
          verify_aud: true,
          aud: options[:client_id],
          verify_sub: true,
          verify_expiration: true,
          verify_not_before: true,
          verify_iat: true,
          verify_jti: false,
          leeway: options[:jwt_leeway]).first
      end
    end
  end
end

OmniAuth.config.add_camelization 'cognito_idp', 'CognitoIdP'
