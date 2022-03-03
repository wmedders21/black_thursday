require_relative './sales_engine.rb'

class SalesAnalyst
  attr_reader :merchant_repo, :item_repo, :transaction_repo, :invoice_item_repo, :invoice_repo, :customer_repo,
              :big_box_ids

  def initialize(merchant_repo, item_repo, transaction_repo, invoice_item_repo, invoice_repo, customer_repo)
    @merchant_repo = merchant_repo
    @item_repo = item_repo
    @transaction_repo = transaction_repo
    @invoice_item_repo = invoice_item_repo
    @invoice_repo = invoice_repo
    @customer_repo = customer_repo
    @big_box_ids = []
  end

  def group_items_by_merchant_id
    @item_repo.all.group_by { |item| item.merchant_id }
  end

  def items_per_merchant
    group_items_by_merchant_id.map { |merchant_id, items| items.count }
  end

  def average_items_per_merchant
    items_per_merchant
    (items_per_merchant.sum.to_f / items_per_merchant.count).round(2)
  end

  def average_items_per_merchant_standard_deviation
    calculate_st_dev(items_per_merchant)
  end

  def calculate_st_dev(numbers_array)
    mean = numbers_array.sum.to_f / numbers_array.count
    differences = numbers_array.map { |number| number - mean }
    square_differences = differences.map { |difference| difference**2 }
    sum_square_differences = square_differences.sum
    quotient = sum_square_differences / (numbers_array.count - 1)
    Math.sqrt(quotient).round(2)
  end

  def merchants_with_high_item_count
    high_count = average_items_per_merchant + average_items_per_merchant_standard_deviation
    group_items_by_merchant_id.each do |id, items|
      if items.count > high_count
        @big_box_ids << id
      end
    end
    big_boxes = @merchant_repo.all.find_all { |merchant| @big_box_ids.include?(merchant.id) }
  end

  def average_item_price_for_merchant(merchant_id)
    prices = group_items_by_merchant_id[merchant_id].map { |item| item.unit_price }
    (prices.sum / prices.count).round(2)
  end

  def average_average_price_per_merchant
    all_merchant_ids = @merchant_repo.all.map { |merchant| merchant.id }
    merchant_averages = all_merchant_ids.map { |id| average_item_price_for_merchant(id) }
    (merchant_averages.sum / merchant_averages.count).round(2)
  end

  def average_item_price_standard_deviation
    all_item_prices = @item_repo.all.map { |item| item.unit_price }
    calculate_st_dev(all_item_prices)
  end

  def golden_items
    all_item_prices = @item_repo.all.map { |item| item.unit_price }
    mean = all_item_prices.sum / all_item_prices.count
    golden_price = mean + (average_item_price_standard_deviation * 2)
    @item_repo.all.find_all { |item| item.unit_price > golden_price }
  end

  def invoice_paid_in_full?(invoice_id)
    transaction = @transaction_repo.all.find { |transaction| transaction.invoice_id == invoice_id }
    if transaction == nil
      return false
    elsif transaction.result == :failed
      return false
    end

    transaction.result == :success
  end

  def invoice_total(invoice_id)
    if invoice_paid_in_full?(invoice_id)
      invoice_items = @invoice_item_repo.all.find_all { |i_item| i_item.invoice_id == invoice_id }
      price_list = invoice_items.map { |i_item| i_item.unit_price * i_item.quantity }
      price_list.sum
    else
      0
    end
  end

  def total_revenue_by_date (time_obj) #passing
      # require 'pry';binding.pry
    invoices_from_year = @invoice_repo.all.find_all {|invoice| invoice.created_at.year == time_obj.year}
    invoices_from_month = invoices_from_year.keep_if {|invoice| invoice.created_at.month == time_obj.month}
    invoices_from_day = invoices_from_month.keep_if {|invoice| invoice.created_at.day == time_obj.day}

    invoices_from_day.flatten!.sum {|invoice_item| invoice_item.unit_price * invoice_item.quantity}
    # return revenue
  end

  def top_revenue_earners(x=20)


    merchant_hashes = @merchant_repo.all.map{ |merchant| {merchant: merchant, revenue: @invoice_repo.find_all_by_merchant_id(merchant.id)}}
    merchant_hashes.each { |hash| hash[:revenue] = hash[:revenue].map {|invoice| @invoice_item_repo.find_all_by_invoice_id(invoice.id)}.flatten}
    merchant_hashes.each { |hash| hash[:revenue] = hash[:revenue].map {|invoice_item| invoice_item.unit_price * invoice_item.quantity}}
    merchant_hashes.each { |hash| hash[:revenue] = hash[:revenue].sum}
    short_list = merchant_hashes.max(x) { |ahash, bhash| ahash[:revenue] <=> bhash[:revenue]}
    short_list.map! { |hash| hash[:merchant]}
    require 'pry';binding.pry
    short_list

  end

  def merchants_with_pending_invoices
    all_pending_invoices = @invoice_repo.find_all_by_status(:pending).map{|invoice| @merchant_repo.find_by_id(invoice.merchant_id)}
    all_failed_transactions = @transaction_repo.find_all_by_result(:failed).map do |transaction|
      id = @invoice_repo.find_by_id(transaction.invoice_id).merchant_id
      @merchant_repo.find_by_id(id)
    end
    all_pending_merchants = (all_pending_invoices + all_failed_transactions).uniq
  end

  def merchants_with_only_one_item
    merchant_ids = @item_repo.all.map {|item| item.merchant_id} #make a hash of merchant IDs from all Invoices
    returned_ids = merchant_ids #copy collection
    returned_ids.delete_if{|returned_id| merchant_ids.find_all{|merchant_id| merchant_id == returned_id}.length > 1} #delete from copy if not unique
    returned_merchants = returned_ids.map{|id| @merchant_repo.find_by_id(id)} #convert IDs to Merchants
  end

  def merchants_with_only_one_item_registered_in_month (month_str)
    applicable_invoices = @invoice_repo.all.find_all{|invoice| invoice.created_at.month == Time.parse(month_str).month}
    applicable_invoices.map! {|invoice| {invoice: invoice, merchant: @merchant_repo.find_by_id(invoice.merchant_id)}}
    applicable_invoices.delete_if{|hash| hash[:invoice].created_at.year != hash[:merchant].created_at.year} #leaves only invoices from month of creation
    returned_merchants = applicable_invoices
    returned_merchants.delete_if{ |returned_hash| (applicable_invoices.find_all{ |applicable_hash| applicable_hash[:merchant] == returned_hash[:merchant]}).length > 1}
    returned_merchants.map{|hash| hash[:merchant]}
  end

  def revenue_by_merchant (merchant_id) #passig
    merchant_invoices = @invoice_repo.find_all_by_merchant_id(merchant_id)
    merchant_invoices.keep_if {|invoice| invoice_paid_in_full?(invoice.id)}
    merchant_invoices.map! { |invoice| @invoice_item_repo.find_all_by_invoice_id(invoice.id)}
    merchant_invoices.flatten!
    # require 'pry'; binding.pry
    merchant_invoices.sum {|invoice_item| invoice_item.unit_price * invoice_item.quantity}
  end

  def most_sold_item_for_merchant(merchant_id)
    merchants_invoices = @invoice_repo.find_all_by_merchant_id(merchant_id) # get all merchant's invoices in an array
    merchants_invoice_items = merchants_invoices.map{ |invoice| @invoice_item_repo.find_all_by_invoice_id(invoice.id)}.flatten # convert to an array of arrays of invoice items, and flatten
    summed_invoice_items = {} # new hash
    # for each invoice item, if the item ID exists as a key in new hash, increment the value by invoice item quantity, or else create the key and set the value to quantity. Creates hash of unique item keys and sums of sales quantities
    merchants_invoice_items.each {|invoice_item| summed_invoice_items[invoice_item.item_id] ? summed_invoice_items[invoice_item.item_id] += invoice_item.quantity : summed_invoice_items[invoice_item.item_id] = invoice_item.quantity}
    max_item = {quantity: 0, items: []} #comparison holder hash
    summed_invoice_items.each_pair {|i, q|  if q == max_item[:quantity] #compare each item in hash to comparison hash and either add item if quantities equal or clear items, add new item, and set new quantity
                                              max_item[:items] << i
                                            elsif q > max_item[:quantity]
                                              max_item[:items].clear
                                              max_item[:items] << i
                                              max_items[:quantity] = q
                                            end}
    return max_items[:items] # return the array of max items
  end

end

sales_engine = SalesEngine.from_csv({ :items => "./data/items.csv", :merchants => "./data/merchants.csv",
                                       :transactions => "./data/transactions.csv", :invoice_items => "./data/invoice_items.csv", :invoices => "./data/invoices.csv", :customers => "./data/customers.csv"})

puts sales_engine.analyst.most_sold_item_for_merchant(12334257)
