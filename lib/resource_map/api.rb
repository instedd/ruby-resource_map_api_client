require "guisso/api"

module ResourceMap
  class ResourceMapApiError < StandardError
    attr_reader :message
    attr_reader :error_code
    attr_reader :http_status_code

    def initialize(opts)
      @message = opts[:message] || "Resource Map API exception"
      @error_code = opts[:error_code] || 0
      @http_status_code = opts[:http_status_code] || 0
    end
  end

  class SiteValidationError < ResourceMapApiError
    attr_reader :error_object

    def initialize(opts)
      super(opts)
      @error_object = opts[:error_object] || {}
    end

    def errors_by_property_code
      return {} if @error_object.nil? || @error_object["properties"].nil?

      @error_object["properties"].map {|error| { field_id: error.keys.first, message: error[error.keys.first] } }
    end
  end

  class Api < Guisso::Api
    extend Memoist
    # RestClient.log = 'stdout'

    def self.default_host
      "resourcemap.instedd.org"
    end

    def self.default_use_ssl
      true
    end

    def collections
      CollectionRelation.new(self)
    end
    memoize :collections

    protected

    def process_response(response)
      if response.status >= 400
        error_obj = ActiveSupport::JSON.decode response.body

        if error_obj["error_object"]
          raise SiteValidationError.new(message: error_obj["message"], error_code: error_obj["error_code"], http_status_code: response.status, error_object: error_obj["error_object"])
        else
          raise ResourceMapApiError.new(message: error_obj["message"], error_code: error_obj["error_code"], http_status_code: response.status)
        end
      end

      response.body
    end
  end
end
