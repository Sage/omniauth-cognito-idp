# omniauth-cognito-idp

[![Build Status](https://travis-ci.org/Sage/omniauth-cognito-idp.svg?branch=master)](https://travis-ci.org/Sage/omniauth-cognito-idp)
[![Maintainability](https://api.codeclimate.com/v1/badges/fc91c64f9d7b63724714/maintainability)](https://codeclimate.com/github/Sage/omniauth-cognito-idp/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/fc91c64f9d7b63724714/test_coverage)](https://codeclimate.com/github/Sage/omniauth-cognito-idp/test_coverage)
[![Gem Version](https://badge.fury.io/rb/omniauth-cognito-idp.svg)](https://badge.fury.io/rb/omniauth-cognito-idp)

This is an [OmniAuth](https://github.com/omniauth/omniauth) strategy based on
[omniauth-oauth2](https://github.com/omniauth/omniauth-oauth2) for authenticating against the
[Amazon Cognito IdP](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-userpools-server-contract-reference.html).

## Setup

### Cognito User Pool

The User Pool needs to have a domain assigned. You also have to create a client application for the User Pool. The
client application should have a secret.

### Ruby Application

Add the gem to your bundle as usual. Then, OmniAuth is used as Rack middleware:

```ruby
# for instance, in config.ru
require 'omniauth-cognito-idp'

use Rack::Session::Cookie # OmniAuth requires session support

use OmniAuth::Strategies::CognitoIdP,
  ENV['CLIENT_ID'],
  ENV['CLIENT_SECRET'],
  client_options: {
    site: ENV['COGNITO_USER_POOL_SITE']
  },
  scope: 'email openid aws.cognito.signin.user.admin profile',
  user_pool_id: ENV['COGNITO_USER_POOL_ID'],
  aws_region: ENV['AWS_REGION']

run MyApplication
```

The following configuration options are available:

1. `client_options` (required)

   This is a Hash that is used to configure the OAuth2 client. You have to include the `site` key and specify the domain
   you assigned to the Cognito User Pool.
2. `scope` (required)

   A space separated list of scopes you want to request. Make sure to include `openid` and some openid attributes if you
   want to get an ID token (which gives you information about the user without additional request). When you include
   `aws.cognito.signin.user.admin`, you can use the access token to get or update the user's attributes in the
   User Pool.
   
   See https://docs.aws.amazon.com/cognito/latest/developerguide/authorization-endpoint.html
3. `user_pool_id` (optional)

   When specified together with `aws_region`, the ID token returned by Cognito will be verified to really belong to the
   User Pool you expect.
4. `aws_region` (optional)
   When specified together with `user_pool_id`, the ID token returned by Cognito will be verified to really belong to
   the given AWS region.
5. `jwt_leeway` (optional)

   Each JWT has it's own expiration and do not use before dates. As the issuer's clock might be off a bit from your's,
   you can allow some leeway for the JWT validation. Must be a positive integer. Default is 60 seconds. 

## Development

The repository contains a small Sinatra application that can be used to test the strategy. Just run `rackup` with the
following ENV variables set:

* `COGNITO_CLIENT_ID`: The id of the client application
* `COGNITO_CLIENT_SECRET`: The client application's secret
* `COGNITO_POOL_SITE`: The domain attached to the user pool.

The application will start at `http://localhost:8678`. You will have to add a callback URL
`http://localhost:8678/auth/cognito_idp/callback` to the client application in the AWS Console. The test app stores the
tokens in memory, so you will need to sign in again after restarting the server.
