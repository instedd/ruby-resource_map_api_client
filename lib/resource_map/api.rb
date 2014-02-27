module ResourceMap
  class Api
    extend Memoist
    RestClient.log = 'stdout'

    DefaultHost = "resourcemap.instedd.org"

    def self.basic_auth(username, password, host = DefaultHost, https = true)
      BasicAuth.new(username, password, host, https)
    end

    def self.from_authorization_code(authorization_code, redirect_uri, host = DefaultHost, https = true)
      self.from_oauth_client(host, https, redirect_uri: redirect_uri) do |client|
        client.authorization_code = authorization_code
      end
    end

    def self.trusted(user_email, host = DefaultHost, https = true)
      from_oauth_client(host, https) do |client, app_host|
        client.scope = %W(app=#{app_host} user=#{user_email})
      end
    end

    def self.from_oauth_client(host, https, options = {})
      if host !~ /\Ahttp:|https:/
        app_uri = URI("http://#{host}")
      else
        app_uri = URI(host)
      end

      if app_uri.default_port == app_uri.port
        app_host = app_uri.host
      else
        app_host = "#{app_uri.host}:#{app_uri.port}"
      end

      guisso_uri = URI(Guisso.url)

      client = Rack::OAuth2::Client.new(options.merge({
        identifier: Guisso.client_id,
        secret: Guisso.client_secret,
        host: guisso_uri.host,
        port: guisso_uri.port,
        scheme: guisso_uri.scheme,
      }))
      yield client, app_host

      access_token = client.access_token!

      oauth access_token, host, https
    end

    def self.oauth(access_token, host = DefaultHost, https = true)
      Oauth.new(access_token, host, https)
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
        "#{url}?#{query.to_query}"
      else
        url
      end
    end

    def get(url, query = {})
      process_response(execute(:get, url, query, nil))
    end

    def get_with_payload(url, query = {})
      process_response(execute(:get, url, nil, query))
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
      u = url 
      q = query

      if u.index("?") && q == {}
        u, q = u.split("?")
        query_bytesize = q.bytesize
      else
        query_bytesize = URI.encode_www_form(q).bytesize
      end

      u = "#{u}.json" unless u.end_with?(".json")   

      # Send query in the payload if it'd yield a too long URI
      response = if query_bytesize > 4000
        get_with_payload u, q
      else
        get u, q
      end        

      JSON.parse response
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
