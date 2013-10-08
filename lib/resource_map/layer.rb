class ResourceMap::Layer
  def initialize(collection, data)
    @collection = collection
    @data = data
  end

  delegate :api, to: :collection
  attr_reader :collection

  def name
    @data['name']
  end

  def id
    @data['id']
  end

  def ord
    @data['ord']
  end

  def public
    @data['public']
  end

  def ensure_fields(field_attributes)
    fields_data = {}

    field_attributes.each_with_index do |f, i|
      f[:ord] = i + 1
      f[:code] = f[:code] || f[:name]
      collection.field_by_code(f[:code]).tap do |existing|
        f[:id] = existing.id if existing
      end

      fields_data[i.to_s] = f
    end

    data = {
      layer: {
        id: id,
        name: name,
        ord: ord,
        public: public,
        fields_attributes: fields_data
      }
    }

    api.put("collections/#{collection.id}/layers/#{id}", data)

    collection.reload
  end

end
