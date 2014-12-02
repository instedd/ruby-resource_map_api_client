module ResourceMap
  class Field
    def initialize(collection, mapping)
      @collection = collection
      @mapping = mapping
    end

    attr_reader :collection

    def api
      collection.api
    end

    def id
      @mapping['id']
    end

    def code
      @mapping['code']
    end

    def kind
      @mapping['kind']
    end

    def name
      @mapping['name']
    end

    def uniq_values(filters={})
      h = api.json("/api/collections/#{collection.id}/histogram/#{id}.json",(filters.empty? ? nil : {filters: filters.to_json}))
      Hash[h.sort]
    end

    def metadata
      @metadata ||= api.json("/en/collections/#{collection.id}/fields/#{id}.json")
    end

    def hierarchy
      metadata['config']['hierarchy']
    end

    def options
      if kind == 'hierarchy'
      @options ||= flatten_hierarchy hierarchy
      else
        metadata['config']['options']
      end
    end

    private

    def flatten_hierarchy hierarchy
      hierarchy.inject [] do |options, item|
        options << {'code' => item['id'], 'label' => item['name']}
        options << (flatten_hierarchy item['sub']) if item['sub']
        options
      end.flatten
    end
  end
end
