class ResourceMap::Api
  extend Memoist
  # RestClient.log = 'stdout'

  def initialize
    @auth = {
      :username => Settings.resource_map.username,
      :password => Settings.resource_map.password
    }
  end

  def collections
    CollectionRelation.new(self)
  end
  memoize :collections

  def url(url, query = nil)
    if url !~ /http:|https:/
      url = "http://#{Settings.resource_map.host}/#{url}"
    end

    "#{url}#{('?' + query.to_query) unless query.nil?}"
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

  def process_response(response)
    response.body
  end
end
