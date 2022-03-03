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
    transaction = @transaction_repo.all.find { |transaction| transaction.invoice_id == invoice_id }
    if transaction == nil
      return false
    end

    transaction.result == :success
  end

  def invoice_total(invoice_id)
    if invoice_paid_in_full?(invoice_id)
      invoice_items = @invoice_item_repo.all.find_all { |i_item| i_item.invoice_id == invoice_id }
      price_list = invoice_items.map { |i_item| i_item.unit_price * i_item.quantity }
      price_list.sum
    end
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
    created_at_dates.each { |date| days_of_week << Date.parse(date).wday }
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
end
