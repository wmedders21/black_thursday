class Item
  attr_accessor :name,
                :description,
                :unit_price,
                :updated_at

  attr_reader :id,
              :created_at,
              :merchant_id

  def initialize(info_hash)
    @id          = info_hash[:id]
    @name        = info_hash[:name]
    @description = info_hash[:description]
    @unit_price  = info_hash[:unit_price]
    @created_at  = info_hash[:created_at]
    @updated_at  = info_hash[:updated_at]
    @merchant_id = info_hash[:merchant_id]
  end

  def unit_price_to_dollars
    unit_price.to_f.round(2)
  end
end
