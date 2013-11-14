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
    end

    def count
      api.json("api/collections/#{collection.id}")['count']
    end

    def where(attrs)
      SiteResult.new(collection, attrs)
    end

    def from_url(url)
      SiteResult.new(collection, url)
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

  class SiteResult
    attr_reader :collection
    delegate :api, to: :collection

    include Enumerable

    def initialize(collection, attrs_or_url)
      @collection = collection
      if attrs_or_url.is_a?(String)
        @page_data = JSON.parse(api.get(attrs_or_url))
        @attrs = nil
      else
        @attrs = attrs_or_url
      end
    end

    def page(page)
      @attrs[:page] = page
      self
    end

    def page_size(page_size)
      @attrs[:page_size] = page_size
      self
    end

    def each
      page_data['sites'].each do |s|
        yield Site.new(collection, s)
      end

      if !is_paged?
        current_page = self.next_page
        while current_page
          current_page.each do |s|
            yield s
          end
          current_page = current_page.next_page
        end
      end
    end

    def total_count
      page_data['count']
    end

    def next_page
      if next_page_url
        @collection.sites.from_url(next_page_url)
      else
        nil
      end
    end

    def next_page_url
      unless page_data['nextPage'].blank?
        url = URI.parse(page_data['nextPage'])
        "#{url.path}?#{url.query}"
      else
        nil
      end
    end

    private

    def page_data
      @page_data ||= api.json("api/collections/#{collection.id}", @attrs)
    end

    def is_paged?
      @attrs == nil || @attrs.include?(:page) || @attrs.include?(:page_size)
    end
  end
end
