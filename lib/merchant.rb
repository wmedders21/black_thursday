class Merchant
  attr_accessor :name, :updated_at
  attr_reader :id, :created_at

  def initialize(info_hash)
    @id = info_hash[:id]
    @name = info_hash[:name]
    @created_at = info_hash[:created_at]
    @updated_at = info_hash[:updated_at]
  end
end
