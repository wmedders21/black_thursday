class Item
  attr_reader :id,
              :name,
              :description,
              :unit_price,
              :created_at,
              :updated_at,
              :merchant_id

  def initialize(info_hash)
    @id          = info_hash[:id]
    @name        = info_hash[:name]
    @description = info_hash[:description]
    @unit_price  = BigDecimal(info_hash[:unit_price]) / 100
    @created_at  = info_hash[:created_at]
    @updated_at  = info_hash[:updated_at]
    @merchant_id = info_hash[:merchant_id]
  end

  def unit_price_to_dollars
    unit_price.to_f.round(2)
  end

  # def update(attributes)
  #   attributes[:updated_at] = Time.now
  #   @name = attributes[:name] || @name
  #   @description = attributes[:description] || @description
  #   @unit_price = attributes[:unit_price] || @unit_price
  #   @updated_at = attributes[:updated_at]
  # end
end
