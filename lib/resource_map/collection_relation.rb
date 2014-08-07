module ResourceMap
  class CollectionRelation
    def initialize(api)
      @api = api
    end

    attr_reader :api

    def all
      api.json("/api/collections").map { |h| build_collection(h['id'].to_i, h['name'], h['count']) }
    end

    def create(params)
      # required { name }
      # allowed { description: string, public: 0|1, icon: 'default'|string }
      raise 'missing name attribute' unless params.has_key? :name
      Collection.create api, params
    end

    def find(id)
      build_collection id
    end

    protected

    def build_collection(id, name = nil, site_count = nil)
      Collection.new api, id, name, site_count
    end
  end
end
