class SalesAnalyst
  attr_reader :merchant_repo, :item_repo, :transaction_repo, :invoice_item_repo, :invoice_repo, :customer_repo, :merchant_items_hash, :num_items_per_merchant, :set_of_square_differences

  def initialize(merchant_repo, item_repo, transaction_repo, invoice_item_repo, invoice_repo, customer_repo)
    @merchant_repo = merchant_repo
    @item_repo = item_repo
    @transaction_repo = transaction_repo
    @invoice_item_repo = invoice_item_repo
    @invoice_repo = invoice_repo
    @customer_repo = customer_repo
    @merchant_items_hash = {}
    @num_items_per_merchant = []
    @mean = 0
    @set_of_square_differences = []
  end

  def group_items_by_merchant_id
    @merchant_items_hash = @item_repo.all.group_by { |item| item.merchant_id }
  end

  def items_per_merchant
    group_items_by_merchant_id
    @num_items_per_merchant = @merchant_items_hash.map do |merchant, items|
      items.count
    end
  end

  def average_items_per_merchant
    items_per_merchant
    avg = items_per_merchant.sum.to_f / items_per_merchant.count
    @mean = avg.round(2)
  end

  def square_differences
    average_items_per_merchant
    differences = @num_items_per_merchant.map { |number| number - @mean }
    @set_of_square_differences = differences.map { |difference| (difference**2).round(2) }
  end

  def average_items_per_merchant_standard_deviation
    square_differences
    sum_sq_diff = @set_of_square_differences.sum
    result = sum_sq_diff / (@num_items_per_merchant.count - 1)
    Math.sqrt(result).round(2)
  end

  def total_revenue_by_date (time_obj)
      # require 'pry';binding.pry
    invoices_from_year = @invoice_repo.all.find_all {|invoice| invoice.created_at.year == time_obj.year}
    invoices_from_month = invoices_from_year.keep_if {|invoice| invoice.created_at.month == time_obj.month}
    invoices_from_day = invoices_from_month.keep_if {|invoice| invoice.created_at.day == time_obj.day}
    invoices_from_day.map! {|invoice| @invoice_item_repo.all.find_all{|invoice_item| invoice_item.invoice_id == invoice.id}}
    invoices_from_day.flatten!.sum {|invoice_item| invoice_item.unit_price * invoice_item.quantity}
    # return revenue
  end

  def top_revenue_earners(x=20)
    merchant_revenues = @merchant_repo.all.map{|merchant| {merchant: merchant.id, revenue: revenue_by_merchant(merchant.id)}} #array of hashes w/ id and revenue
    top_x = merchant_revenues.max(x) {|ahash, bhash| ahash[:revenue] <=> bhash[:revenue]}
    top_x.map! {|hash| @merchant_repo.find_by_id(hash[:merchant])}
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

  def revenue_by_merchant (merchant_id)
    merchant_invoices = @invoice_repo.find_all_by_merchant_id(merchant_id)
    merchant_invoices.map! { |invoice| @invoice_item_repo.find_all_by_invoice_id(invoice.id)}
    merchant_invoices.flatten!
    merchant_invoices.sum {|invoice_item| invoice_item.unit_price * invoice_item.quantity}
  end

end
