module ResourceMap
  class SiteRelation
    attr_reader :collection

    def initialize(collection)
      @collection = collection
    end

    def api
      collection.api
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
      result = api.post("api/collections/#{collection.id}/sites.json", site: params.to_json)
      Site.new(collection, result)
    end
  end

  class SiteResult
    attr_reader :collection

    include Enumerable

    def initialize(collection, attrs_or_url)
      @collection = collection
      if attrs_or_url.is_a?(String)
        @page_data = api.json("#{attrs_or_url}.json")
        @attrs = nil
      else
        @attrs = attrs_or_url
      end
    end

    def api
      collection.api
    end

    def page(page)
      append_search_attribute page: page
    end

    def page_size(page_size)
      new_attrs = { page_size: page_size }

      #page_size doesn't really play well without a page param, so we default to the first page if the attr isn't provided
      new_attrs[:page] = 1 unless @attrs.include?(:page)

      append_search_attribute new_attrs
    end

    def where(attrs)
      append_search_attribute attrs
    end

    def all
      r = []
      self.each(true) do |e|
        r.push e
      end
      r
    end

    def each(seamless_paging=false)
      page_data['sites'].each do |s|
        yield Site.new(collection, s)
      end

      if !is_paged? || seamless_paging
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

    def update(update_attrs)
      api.post("api/collections/#{collection.id}/update_sites.json", @attrs.merge({updates: update_attrs}))
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
      @page_data ||= api.json("api/collections/#{collection.id}.json", @attrs)
    end

    def is_paged?
      @attrs == nil || @attrs.include?(:page)
    end
  end
end
