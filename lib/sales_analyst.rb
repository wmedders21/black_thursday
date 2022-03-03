
require_relative './sales_engine.rb'
require 'date'


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
      transaction = @transaction_repo.all.find_all { |transaction| transaction.invoice_id == invoice_id }
      if transaction == []
        return false
      end
      transaction.any? { |k| k.result == :success }
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

  def group_invoices_by_merchant_id
    @invoice_repo.all.group_by { |invoice| invoice.merchant_id }
  end

  def invoices_per_merchant
    group_invoices_by_merchant_id.map { |merchant_id, invoices| invoices.count }
  end

  def average_invoices_per_merchant
    invoices_per_merchant
    (invoices_per_merchant.sum.to_f / invoices_per_merchant.count).round(2)
  end

  def average_invoices_per_merchant_standard_deviation
    calculate_st_dev(invoices_per_merchant)
  end

  def top_merchants_by_invoice_count
    result_array = []
    high_count = average_invoices_per_merchant + (average_invoices_per_merchant_standard_deviation * 2)
    group_invoices_by_merchant_id.each do |id, invoices|
      if invoices.count > high_count
        result_array << id
      end
    end
    result_array = @merchant_repo.all.find_all { |merchant| result_array.include?(merchant.id) }
  end

  def bottom_merchants_by_invoice_count
    result_array = []
    bottom_count = average_invoices_per_merchant - (average_invoices_per_merchant_standard_deviation * 2)
    group_invoices_by_merchant_id.each do |id, invoices|
      if invoices.count < bottom_count
        result_array << id
      end
    end
    result_array = @merchant_repo.all.find_all { |merchant| result_array.include?(merchant.id) }
  end

  def invoices_by_days_of_the_week
    created_at_dates = []
    @invoice_repo.all.each { |invoice| created_at_dates << invoice.created_at }
    days_of_week = []
    created_at_dates.each { |date| days_of_week << date.wday }
    days_in_order = []
    (0..6).each { |num| days_in_order << days_of_week.find_all { |day| day == num } }
    days_in_order
  end

  def average_invoices_per_day_of_week
    days_of_week = invoices_by_days_of_the_week
    @invoices_per_day = []
    days_of_week.each { |day| @invoices_per_day << day.length }
    @invoices_per_day.sum / days_of_week.length
  end

  def invoices_per_day_of_week_standard_deviation
    days_of_week = invoices_by_days_of_the_week
    avg = average_invoices_per_day_of_week
    maths = []
    days_of_week.each { |day| maths << (day.length - avg)**2 }
    Math.sqrt((maths.sum) / (invoices_by_days_of_the_week.length - 1)).round(0)
  end

  def num_to_days(num)
    return "Sunday" if num == 0
    return "Monday" if num == 1
    return "Tuesday" if num == 2
    return "Wednesday" if num == 3
    return "Thursday" if num == 4
    return "Friday" if num == 5
    return "Saturday" if num == 6
  end

  def top_days_by_invoice_count
    avg = average_invoices_per_day_of_week
    std_dev = invoices_per_day_of_week_standard_deviation
    top_days = []
    @invoices_per_day.each_with_index { |day, index|
      if day > (std_dev + avg)
        top_days << num_to_days(index)
      end
    }
    top_days
  end

  def invoice_status(status)
    invoice_by_status = @invoice_repo.all.find_all { |invoice| invoice.status == status }
    (((invoice_by_status.length).to_f / (@invoice_repo.all.length).to_f) * 100).round(2)
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
                                              max_item[:quantity] = q
                                            end}
    output = max_item[:items].map {|item_num| @item_repo.find_by_id(item_num)}
    # return max_item[:items] # return the array of max items
  end

  def best_item_for_merchant(id)
    merchants_invoices = @invoice_repo.find_all_by_merchant_id(merchant_id) # all invoices for merchant
    merchants_invoices.keep_if {|invoice| invoice_paid_in_full(invoice.id)} # keep only if invoice made profit
    merchants_invoice_items = merchants_invoices.map{ |invoice| @invoice_item_repo.find_all_by_invoice_id(invoice.id)}.flatten #convert remaining invoices to InvoiceItems
    item_profits = {}
    merchants_invoice_items.each {|invoice_item| item_profits[invoice_item.item_id] ? item_profits[invoice_item.item_id] += (invoice_item.quantity * invoice_item.unit_price) : item_profits[invoice_item.item_id] = (invoice_item.quantity *invoice_item.unit_price)}
    max_profit = {profit: 0 items: []} #comparison hash holder
    item_profits.each_pair {|i, p|  if p == max_profit[:profit] #compare each item in hash to comparison hash and either add item if quantities equal or clear items, add new item, and set new quantity
                                      max_profit[:items] << i
                                    elsif p > max_profit[:profit]
                                      max_profit[:items].clear
                                      max_profit[:items] << i
                                      max_profit[:profit] = p
                                    end}
    output = max_profit[:items].map {|item_num| @item_repo.find_by_id(item_num)}
  end

end

sales_engine = SalesEngine.from_csv({ :items => "./data/items.csv", :merchants => "./data/merchants.csv",
                                       :transactions => "./data/transactions.csv", :invoice_items => "./data/invoice_items.csv", :invoices => "./data/invoices.csv", :customers => "./data/customers.csv"})

puts sales_engine.analyst.most_sold_item_for_merchant(12334684)
puts sales_engine.analyst.best_item_for_merchant(12334684)
