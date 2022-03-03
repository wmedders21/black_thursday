require_relative '../lib/findable.rb'
require_relative '../lib/invoice.rb'
require_relative '../lib/crudable.rb'
require 'pry'

class InvoiceRepository
  include Findable
  include Crudable
  attr_reader :all

  def initialize(invoice_array)
    @all = invoice_array
    @new_object = Invoice
  end

  def inspect
  end

  def find_all_by_customer_id(id_integer)
    @all.find_all { |invoice| invoice.customer_id == id_integer }
  end

  def find_all_by_merchant_id(id_integer)
    @all.find_all { |invoice| invoice.merchant_id == id_integer }
  end

  def find_all_by_status(status_symbol)
    @all.find_all { |invoice| invoice.status == status_symbol }
  end
end
