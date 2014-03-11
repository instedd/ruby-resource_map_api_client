module ResourceMap
  class Api::Oauth < Api
    def initialize(access_token, host, https)
      @token = access_token
      @host = host
      self.use_https = https
    end

    protected

    def execute(method, url, query, payload)
      tmp_dir = "#{Rails.root}/tmp/source_import"

      processed_payload = nil

      if payload
        processed_payload = payload
        
        if processed_payload.is_a?(Hash)
          if processed_payload[:file]
            original_filename = "#{Time.now.getutc.to_i}.csv"

            path = File.join(tmp_dir, original_filename)
            File.open(path, "wb") { |f| f.write(processed_payload[:file].read) }

            processed_payload[:file] = File.open("#{tmp_dir}/#{original_filename}")
          else
            processed_payload = processed_payload.to_query
          end
        end
      end

      response = @token.request method, url(url, query), nil, processed_payload, nil, true

      if method == :post && [301, 302, 307].include?(response.code)
        self.get(response.headers[:location])
      else
        response
      end
    end
  end
end
