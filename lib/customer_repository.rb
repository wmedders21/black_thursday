require_relative '../lib/findable.rb'
require_relative '../lib/crudable.rb'
require_relative '../lib/customer.rb'

class CustomerRepository
  include Findable
  include Crudable
  attr_reader :all, :new_object

  def initialize(customer_array)
    @all = customer_array
    @new_object = Customer
  end

  def find_all_by_first_name(first_name)
    @all.find_all do |customer|
      customer.first_name.downcase.include?(first_name.downcase)
    end
  end

  def find_all_by_last_name(last_name)
    @all.find_all do |customer|
      customer.last_name.downcase.include?(last_name.downcase)
    end
  end

  def inspect
  end
end
