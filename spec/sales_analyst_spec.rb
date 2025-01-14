require 'pry'
require 'simplecov'
require 'rspec'
require_relative '../lib/sales_engine'
require_relative '../lib/sales_analyst'
require_relative '../lib/merchant'
require_relative '../lib/merchant_repository'

SimpleCov.start

RSpec.describe SalesAnalyst do
  context 'iteration 1' do
    it 'exists' do
      sa = SalesAnalyst.new(1, 2, 3, 4, 5, 6)
      expect(sa).to be_a(SalesAnalyst)
    end
    before :each do
      @sales_engine = SalesEngine.from_csv({ :items => "./data/items.csv", :merchants => "./data/merchants.csv",
                                             :transactions => "./data/transactions.csv", :invoice_items => "./data/invoice_items.csv", :invoices => "./data/invoices.csv", :customers => "./data/customers.csv" })
      @sales_analyst = @sales_engine.analyst
    end

    it 'groups items by merchant id' do
      @sales_analyst.group_items_by_merchant_id
      expect(@sales_analyst.group_items_by_merchant_id.count).to eq(475)
      expect(@sales_analyst.group_items_by_merchant_id.class).to eq(Hash)
    end

    it 'makes a list of the number of items offered by each merchant' do
      @sales_analyst.items_per_merchant
      expect(@sales_analyst.items_per_merchant.class).to be(Array)
      expect(@sales_analyst.items_per_merchant.count).to be(475)
      expect(@sales_analyst.items_per_merchant.sum).to be(1367)
    end

    it 'what is the average items per merchant' do
      expect(@sales_analyst.average_items_per_merchant).to eq(2.88)
    end

    it 'what is the standard deviation' do
      expect(@sales_analyst.average_items_per_merchant_standard_deviation).to eq(3.26)
    end

    it 'which merchants have above one st. dev. avg products offered' do
      expect(@sales_analyst.merchants_with_high_item_count.class).to eq(Array)
      sample1 = @sales_analyst.merchant_repo.find_by_id(@sales_analyst.merchants_with_high_item_count[0].id).id
      sample2 = @sales_analyst.merchant_repo.find_by_id(@sales_analyst.merchants_with_high_item_count[1].id).id
      sample3 = @sales_analyst.merchant_repo.find_by_id(@sales_analyst.merchants_with_high_item_count[2].id).id
      expect(@sales_analyst.group_items_by_merchant_id[sample1].count).to be > 6.14
      expect(@sales_analyst.group_items_by_merchant_id[sample2].count).to be > 6.14
      expect(@sales_analyst.group_items_by_merchant_id[sample3].count).to be > 6.14
    end

    it 'what is the avg item price for a merchant' do
      @sales_analyst.merchants_with_high_item_count
      sample1 = @sales_analyst.big_box_ids[0]
      sample2 = @sales_analyst.big_box_ids[1]
      expect(@sales_analyst.average_item_price_for_merchant(sample1).class).to eq(BigDecimal)
      expect(@sales_analyst.average_item_price_for_merchant(sample2).class).to eq(BigDecimal)
    end

    it 'what is the avg avg price for a merchant' do
      expect(@sales_analyst.average_average_price_per_merchant.class).to eq(BigDecimal)
    end

    it 'average_item_price_standard_deviation' do
      expect(@sales_analyst.average_item_price_standard_deviation).to be_a(Float)
    end

    it 'what items are over two st. devs above avg item price' do
      expect(@sales_analyst.golden_items.class).to eq(Array)
      expect(@sales_analyst.golden_items.count).to eq(5)
      expect(@sales_analyst.golden_items[0].class).to eq(Item)
    end
  end

  context "iteration 2" do
    before :each do
      @sales_engine = SalesEngine.from_csv({ :items => "./data/items.csv", :merchants => "./data/merchants.csv",
                                             :transactions => "./data/transactions.csv", :invoice_items => "./data/invoice_items.csv", :invoices => "./data/invoices.csv", :customers => "./data/customers.csv" })
      @sales_analyst = @sales_engine.analyst
    end
    it 'groups invoices by merchant id' do
      @sales_analyst.group_items_by_merchant_id
      expect(@sales_analyst.group_invoices_by_merchant_id.count).to eq(475)
      expect(@sales_analyst.group_invoices_by_merchant_id.class).to eq(Hash)
    end

    it 'makes a list of the number of invoices offered by each merchant' do
      @sales_analyst.invoices_per_merchant
      expect(@sales_analyst.invoices_per_merchant.class).to be(Array)
      expect(@sales_analyst.invoices_per_merchant.count).to be(475)
      expect(@sales_analyst.invoices_per_merchant.sum).to be(4985)
    end

    it "#average_invoices_per_merchant returns average number of invoices per merchant" do
      expect(@sales_analyst.average_invoices_per_merchant).to eq(10.49)
      expect(@sales_analyst.average_invoices_per_merchant).to be_a(Float)
    end

    it "#average_invoices_per_merchant_standard_deviation returns the standard deviation" do
      expect(@sales_analyst.average_invoices_per_merchant_standard_deviation).to eq(3.29)
      expect(@sales_analyst.average_invoices_per_merchant_standard_deviation).to be_a(Float)
    end

    it "#top_merchants_by_invoice_count returns merchants that are two standard deviations above the mean" do
      expect(@sales_analyst.top_merchants_by_invoice_count.length).to eq(12)
      expect(@sales_analyst.top_merchants_by_invoice_count.first.class).to eq(Merchant)
    end

    it "#bottom_merchants_by_invoice_count returns merchants that are two standard deviations below the mean" do
      expect(@sales_analyst.bottom_merchants_by_invoice_count.length).to eq(4)
      expect(@sales_analyst.bottom_merchants_by_invoice_count.first.class).to eq(Merchant)
    end

    it 'can find invoices by day of the week' do
      expect(@sales_analyst.invoices_by_days_of_the_week[2].length).to eq(692)
    end

    it 'can find the standard deviation of the invoices per day of week' do
      expect(@sales_analyst.invoices_per_day_of_week_standard_deviation).to eq(18)
    end

    it 'can define numbers to corresponding days' do
      expect(@sales_analyst.num_to_days(4)).to eq("Thursday")
      expect(@sales_analyst.num_to_days(5)).to eq("Friday")
      expect(@sales_analyst.num_to_days(6)).to eq("Saturday")
    end

    it "#top_days_by_invoice_count returns days with an invoice count more than one standard deviation above the mean" do
      expect(@sales_analyst.top_days_by_invoice_count.length).to eq(1)
      expect(@sales_analyst.top_days_by_invoice_count.first).to eq("Wednesday")
      expect(@sales_analyst.top_days_by_invoice_count.first.class).to eq(String)
    end

    it "#invoice_status returns the percentage of invoices with given status" do
      expect(@sales_analyst.invoice_status(:pending)).to eq 29.55

      expect(@sales_analyst.invoice_status(:shipped)).to eq 56.95

      expect(@sales_analyst.invoice_status(:returned)).to eq 13.5
    end
  end

  context 'iteration 3' do
    before :each do
      @sales_engine = SalesEngine.from_csv({ :items => "./data/items.csv", :merchants => "./data/merchants.csv",
                                             :transactions => "./data/transactions.csv", :invoice_items => "./data/invoice_items.csv", :invoices => "./data/invoices.csv", :customers => "./data/customers.csv" })
      @sales_analyst = @sales_engine.analyst
      @sample1 = Invoice.new({ id: 1, customer_id: 1, merchant_id: 12335938, status: :pending,
                               created_at: "	2009-02-07", updated_at: "2014-03-15" })
      @sample2 = Invoice.new({ id: 9, customer_id: 2, merchant_id: 12336965, status: :shipped,
                               created_at: "2003-03-07", updated_at: "2008-10-09" })
    end

    it 'invoice_paid_in_full?' do
      expect(@sales_analyst.invoice_paid_in_full?(@sample1.id)).to eq(true)
      expect(@sales_analyst.invoice_paid_in_full?(@sample2.id)).to eq(false)
    end

    it 'returns the total $ amount of the Invoice with the corresponding id' do
      expect(@sales_analyst.invoice_total(@sample1.id).class).to eq(BigDecimal)
      expect(@sales_analyst.invoice_total(@sample1.id)).to eq(21067.77)
    end
  end

  context 'Iteration 4' do
    before :each do
      @sales_engine = SalesEngine.from_csv({ :items => "./data/items.csv", :merchants => "./data/merchants.csv",
                                             :transactions => "./data/transactions.csv", :invoice_items => "./data/invoice_items.csv", :invoices => "./data/invoices.csv", :customers => "./data/customers.csv" })
      @sales_analyst = @sales_engine.analyst
    end

    it 'gives total revenue by date' do
      revenue = @sales_analyst.total_revenue_by_date(Time.parse("2012-11-23"))
      expect(revenue.class).to eq(BigDecimal)
    end

    it 'returns the top revenue earners as a list of merchants' do
      top = @sales_analyst.top_revenue_earners(4)
      expect(top.class).to eq(Array)
      expect(top.length).to eq(4)
      expect(top[2].class).to eq(Merchant)
    end

    it 'returns merchants with pending invoices' do
      pending = @sales_analyst.merchants_with_pending_invoices
      expect(pending).to be_a(Array)
      expect(pending.first).to be_a(Merchant)
    end

    it 'returns merchants with only one item in their inventory' do
      expected = @sales_analyst.merchants_with_only_one_item
      expect(expected).to be_a(Array)
      expect(expected.first).to be_a(Merchant)
    end

    it 'returns merchants that only sell one item by the month of their creation' do
      expected = @sales_analyst.merchants_with_only_one_item_registered_in_month("March")

      expect(expected).to be_a(Array)
      expect(expected.last).to be_a(Merchant)
    end

    it 'returns total revenue for a single merchant' do
      expected = @sales_analyst.revenue_by_merchant(12335345)

      expect(expected).to be_a(BigDecimal)
    end

    it 'returns paid invoice items for a given merchant' do
      expected = @sales_analyst.helper_get_profitable_invoices(12335024)

      expect(expected.first).to be_a(InvoiceItem)
    end

    it 'returns an array of items from a formatted hash' do
      formatted_hash = {263451719 => 14, 263509232 => 9, 12337005 => 25}
      max_measure = {measure: 0, items: []}
      expected = @sales_analyst.helper_get_greatest_measure(formatted_hash, max_measure)
      expect(expected).to be_a(Array)
      expect(expected.length).to eq(1)
    end
  end
end
