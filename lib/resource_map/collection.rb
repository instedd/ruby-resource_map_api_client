module ResourceMap
  class Collection
    extend Memoist

    def initialize(api, id, name = nil, site_count = nil)
      @api = api
      @id = id
      @name = name
      @site_count = site_count
    end

    def self.create(api, params)
      Collection.new(api, api.json_post('/api/collections', collection: params)['id'])
    end

    def destroy
      api.delete("api/collections/#{id}")
    end

    def reload
      @fields = nil
      @layer_names = nil
      self.flush_cache
    end

    def details
      api.json("api/collections/#{id}", page: 'all')
    end
    memoize :details

    attr_reader :api
    attr_reader :id
    attr_reader :site_count

    def site_count
      @site_count || api.json("api/collections/#{id}")['count']
    end
    memoize :site_count

    def name
      @name || api.json("api/collections/#{id}")['name']
    end
    memoize :name

    def sites
      SiteRelation.new(self)
    end
    memoize :sites

    def members
      MembersRelation.new(self)
    end
    memoize :members

    def fields
      @fields ||= begin
        fields_mapping = api.json("api/collections/#{id}/fields/mapping")
        fields_mapping.map { |fm| Field.new(self, fm) }
      end
    end

    def layers
      @layers ||= api.json("api/collections/#{id}/layers").map { |l| Layer.new(self, l) }
    end

    def find_or_create_layer_by_name(name)
      res = layers.detect { |l| l.name == name }

      if res.nil?
        data = { layer: { name: name, ord: layers.length + 1 } }
        api.post("api/collections/#{id}/layers", data)
        @layers = nil
        res = layers.detect { |l| l.name == name }
      end

      res
    end

    def field_by_id(id)
      fields.detect { |f| f.id == id }
    end

    def field_by_code(code)
      fields.detect { |f| f.code == code }
    end

    def show_url
      api.url("en/collections?collection_id=#{id}")
    end

    def csv_url
      api.url("api/collections/#{id}.csv")
    end

    def layers_url
      api.url("en/collections/#{id}/layers")
    end

    def import_wizard_url
      api.url("en/collections/#{id}/import_wizard")
    end

    def import_wizard
      ImportWizard.new self
    end
    memoize :import_wizard

    class MembersRelation
      attr_reader :collection

      def initialize(collection)
        @collection = collection
      end

      def api
        collection.api
      end

      def all
        members_data = api.json("api/collections/#{collection.id}/memberships")
        members_data.map { |member_hash|
          Member.new(collection, member_hash)
        }
      end

      def find_by_email(email)
        all.find { |m| m.email == email }
      end

      def create_by_email(email)
        member_hash = api.json_post("api/collections/#{collection.id}/memberships", email: email)
        Member.new(collection, member_hash)
      end

      def find_or_create_by_email(email)
        member = find_by_email(email)
        if member.nil?
          member = create_by_email(email)
        end

        member
      end

      def invitable(term)
        api.json("api/collections/#{collection.id}/memberships/invitable", term: term)
      end
    end

  end
end
