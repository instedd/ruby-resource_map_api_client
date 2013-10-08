module ResourceMap
  class Api::Oauth < Api
    def initialize(access_token, host, https)
      @token = access_token
      @host = host
      self.use_https = https
    end

    protected

    def execute(method, url, query, payload)
      response = @token.request method, url(url, query), nil, payload
      if method == :post && [301, 302, 307].include?(response.code)
        self.get(response.headers[:location])
      else
        response
      end
    end
  end
end
