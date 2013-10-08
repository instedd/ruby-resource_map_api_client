module ResourceMap
  class Api
    extend Memoist
    # RestClient.log = 'stdout'

    DefaultHost = "resourcemap.instedd.org"

    def self.basic_auth(username, password, host = DefaultHost, https = true)
      BasicAuth.new(username, password, host, https)
    end

    def self.oauth(access_token, host = DefaultHost, https = true)
      Oauth.new(access_token, host, https)
    end

    def self.trusted(user_email, host = DefaultHost, https = true)
      if host !~ /\Ahttp:|https:/
        app_host = URI("http://#{host}").host
      else
        app_host = URI(host).host
      end

      guisso_uri = URI(Guisso.url)

      client = Rack::OAuth2::Client.new(
        identifier: Guisso.client_id,
        secret: Guisso.client_secret,
        host: guisso_uri.host,
        port: guisso_uri.port,
        scheme: guisso_uri.scheme,
      )
      client.scope = %W(app=#{app_host} user=#{user_email})
      access_token = client.access_token!

      oauth access_token, host, https
    end

    def use_https=(https)
      @protocol = https ? 'https' : 'http'
    end

    def collections
      CollectionRelation.new(self)
    end
    memoize :collections

    def url(url='', query = nil)
      if url !~ /\Ahttp:|https:/
        url = "/#{url}" unless url.start_with? "/"
        url = "#{@protocol}://#{@host}#{url}"
      end

      if query && !query.empty?
        "#{url}?#{URI.encode_www_form(query)}"
      else
        url
      end
    end

    def get(url, query = {})
      process_response(execute(:get, url, query, nil))
    end

    def post(url, body = {})
      process_response(execute(:post, url, nil, body))
    end

    def put(url, body = {})
      process_response(execute(:put, url, nil, body))
    end

    def delete(url)
      process_response(execute(:delete, url, nil, nil))
    end

    def json(url, query = {})
      JSON.parse get("#{url}.json", query)
    end

    def json_post(url, query = {})
      JSON.parse post("#{url}.json", query)
    end

    protected

    def process_response(response)
      response.body
    end
  end
end
