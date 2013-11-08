module ResourceMap
  class SiteRelation
    attr_reader :collection
    delegate :api, to: :collection

    def initialize(collection)
      @collection = collection
    end

    def all
      sites_data = collection.details['sites']
      sites_data.map { |site_hash| Site.new(collection, site_hash) }
      # armar un each en lugar de un all?
    end

    def count
      api.json("api/collections/#{collection.id}")['count']
    end

    def where(attrs)
      SitePagedResult.new(collection, attrs)
    end

    def from_url(url)
      SitePagedResult.new(collection, url)
    end

    def find(site_id)
      Site.new(collection, site_id)
    end

    def create(params)
      raise 'missing name attribute' unless params.has_key?(:name) || params.has_key?('name')
      result = api.json_post("/collections/#{collection.id}/sites", site: params.to_json)
      Site.new(collection, result)
    end
  end

  class SitePagedResult
    attr_reader :collection
    delegate :api, to: :collection

    def initialize(collection, attrs_or_url)
      @collection = collection
      if attrs_or_url.is_a?(String)
        @page = JSON.parse(api.get(attrs_or_url))
      else
        @page = api.json("api/collections/#{collection.id}", attrs_or_url)
      end
    end

    def each
      @page['sites'].each do |s|
        yield s
      end
    end

    def total_count
      @page['count']
    end

    def next_page
      SitePagedResult.from_url(@collection, next_page_url)
    end

    def next_page_url
      unless @page['nextPage'].blank?
        url = URI.parse(@page['nextPage'])
        "#{url.path}?#{url.query}"
      else
        nil
      end
    end
  end
end
