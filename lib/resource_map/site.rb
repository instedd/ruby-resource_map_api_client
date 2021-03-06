module ResourceMap
  class Site
    def initialize(collection, id_or_hash)
      @collection = collection

      if id_or_hash.is_a?(Hash)
        @id = id_or_hash['id']
        @data = id_or_hash
      else
        @id = id_or_hash.to_i
        @data = nil
      end
    end

    attr_reader :collection
    attr_reader :id

    def api
      collection.api
    end

    def data
      @data ||= api.json("api/sites/#{id}.json")
    end

    def to_hash
      data
    end

    def name
      data['name']
    end

    def lat
      data['lat']
    end

    def long
      data['long']
    end

    def properties
      data['properties']
    end

    def update_property(code, value)
      api.post("api/sites/#{id}/update_property", {
        es_code: collection.field_by_code(code).id,
        value: value
        })
    end

    def update_properties(hash)
      hash.delete :createdAt
      hash.delete :updatedAt
      p = {}
      (hash[:properties] || {}).each do |k,v|
        p[collection.field_by_code(k).id] = v
      end
      hash[:properties] = p
      # from json api location is lat/long but for update is lat/lng
      # enforce lat/long as convention from outside
      if hash.has_key?(:long)
        hash[:lng] = hash[:long]
        hash.delete(:long)
      end
      api.post("api/sites/#{id}/partial_update.json", {site: hash.to_json})
    end

    def destroy
      api.delete("api/sites/#{id}")
    end

    def history
      @history ||= api.json("api/collections/#{@collection.id}/sites/#{@id}/histories.json")
    end
  end
end
