class Member
  attr_reader :collection
  delegate :api, to: :collection

  def initialize(collection, hash)
    @collection = collection
    @hash = hash
  end

  def id
    @hash['user_id']
  end

  def email
    @hash['user_display_name']
  end

  def admin?
    @hash['admin']
  end

  def set_admin!
    api.post("collections/#{collection.id}/memberships/#{id}/set_admin.json")
  end

  def delete!
    # rescue due to 302 Found
    api.delete("collections/#{collection.id}/memberships/#{id}.json") rescue nil
  end
end
