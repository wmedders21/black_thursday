require 'pry'
require_relative './sales_engine.rb'
require_relative './findable.rb'
require_relative './item.rb'
require_relative './crudable.rb'
require 'BigDecimal'
# This class takes one argument at initialization, an array of all Item instances. It is intended that the SalesEngine instance will take care of creating this array from its given CSV directory, and pass that array to this instance of ItemRepository at time of creation (when SalesEngine#items(item_object_array) is called)
class ItemRepository
  include Findable
  include Crudable
  attr_reader :all
  attr_accessor :new_object

  def initialize array
    @all = array
    @new_object = Item
  end

  def inspect
  end

  def find_all_with_description(descriptive_string)
    @all.find_all { |item| item.description.downcase.include?(descriptive_string.downcase) }
  end

  # note- price in this hash is stored in cents, not dollars!
  def find_all_by_price(desired_price)
    @all.find_all { |item| item.unit_price.to_i == desired_price }
  end

  def find_all_by_price_in_range(price_range_object)
    @all.find_all { |item| price_range_object.member?(item.unit_price.to_i) }
  end

  def find_all_by_merchant_id(merchant_id_string)
    @all.find_all { |item| item.merchant_id == merchant_id_string }
  end
end
