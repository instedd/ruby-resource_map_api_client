class ResourceMap::Field
  def initialize(collection, mapping)
    @collection = collection
    @mapping = mapping
  end

  delegate :api, to: :collection

  attr_reader :collection
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

  def uniq_values
    h = api.json("/api/collections/#{collection.id}/histogram/#{id}")
    Hash[h.sort]
  end

  def metadata
    @metadata ||= api.json("/collections/#{collection.id}/fields/#{id}")
  end

  def hierarchy
    metadata['config']['hierarchy']
  end
end
