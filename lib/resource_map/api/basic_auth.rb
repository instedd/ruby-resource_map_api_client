module ResourceMap
  class Api::BasicAuth < Api
    def initialize(username, password, host, https)
      @auth = {username: username, password: password}
      @host = host
      self.use_https = https
    end

    protected

    def execute(method, url, query, payload)
      options = {
        :user => @auth[:username],
        :password => @auth[:password],

        :method => method,
        :url => self.url(url, query)
      }

      options[:payload] = payload if payload

      RestClient::Request.execute options do |response, request, result, &block|
        # follow-redirections on POST (required for import wizard)
        # but ignore payload (file)
        if request.method == :post && [301, 302, 307].include?(response.code)
          self.get(response.headers[:location])
        else
          response.return!(request, result, &block)
        end
      end
    end
  end
end
