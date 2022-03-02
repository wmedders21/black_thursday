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
      expect(@sales_analyst.merchant_items_hash.count).to eq(475)
      expect(@sales_analyst.merchant_items_hash.class).to eq(Hash)
    end

    it 'makes a list of the number of items offered by each merchant' do
      @sales_analyst.items_per_merchant
      expect(@sales_analyst.num_items_per_merchant.class).to be(Array)
      expect(@sales_analyst.num_items_per_merchant.count).to be(475)
      expect(@sales_analyst.num_items_per_merchant.sum).to be(1367)
    end

    it 'what is the average items per merchant' do
      expect(@sales_analyst.average_items_per_merchant).to eq(2.88)
    end

    it 'collects squared differences of each item count and mean of item counts' do
      @sales_analyst.square_differences
      expect(@sales_analyst.set_of_square_differences.count).to eq(475)
      expect(@sales_analyst.set_of_square_differences.class).to eq(Array)
      expect(@sales_analyst.set_of_square_differences[0].class).to eq(Float)
    end

    it 'what is the standard deviation' do
      expect(@sales_analyst.average_items_per_merchant_standard_deviation).to eq(3.26)
    end

    xit 'which merchants have above one st. dev. avg products offered' do
      expect(@sales_analyst.merchants_with_high_item_count).to eq("ummmmm i don't know")
    end

    xit 'what is the avg item price for a merchant' do
      expect(@sales_analyst.average_item_price_for_merchant(12334159)).to eq("ummmmm i don't know")
    end

    xit 'what is the avg avg price for a merchant' do
      expect(@sales_analyst.average_average_price_for_merchant).to eq("ummmmm i don't know")
    end

    xit 'what items are over two st. devs above avg item price' do
      expect(@sales_analyst.golden_items).to eq("ummmmm i don't know")
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

  end
end
