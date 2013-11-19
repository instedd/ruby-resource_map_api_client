module ResourceMap
  class SiteRelation
    attr_reader :collection
    delegate :api, to: :collection

    def initialize(collection)
      @collection = collection
    end

    def all
      self.where({}).to_a
    end

    def count
      # force a little page_size to only some sites are returned.
      # we just expect the total_count
      self.where({}).page_size(2).total_count
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
      # TODO params seems to need es_code, should be mapped to field codes
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
      append_search_attribute page: page
    end

    def page_size(page_size)
      append_search_attribute page_size: page_size
    end

    def where(attrs)
      append_search_attribute attrs
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

    def url
      api.url("api/collections/#{collection.id}.json", @attrs)
    end

    private

    def append_search_attribute(new_attrs)
      raise "Invalid operation. SiteResult was created from url" if @attrs.nil?
      SiteResult.new(collection, @attrs.merge(new_attrs))
    end

    def page_data
      @page_data ||= api.json("api/collections/#{collection.id}", @attrs)
    end

    def is_paged?
      @attrs == nil || @attrs.include?(:page) || @attrs.include?(:page_size)
    end
  end
end
