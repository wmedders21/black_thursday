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
    xit 'exists' do
      sa = SalesAnalyst.new(1, 2, 3, 4, 5, 6)
      expect(sa).to be_a(SalesAnalyst)
    end
    before :each do
      @sales_engine = SalesEngine.from_csv({ :items => "./data/items.csv", :merchants => "./data/merchants.csv",
                                             :transactions => "./data/transactions.csv", :invoice_items => "./data/invoice_items.csv", :invoices => "./data/invoices.csv", :customers => "./data/customers.csv" })
      @sales_analyst = @sales_engine.analyst
    end

    xit 'groups items by merchant id' do
      @sales_analyst.group_items_by_merchant_id
      expect(@sales_analyst.group_items_by_merchant_id.count).to eq(475)
      expect(@sales_analyst.group_items_by_merchant_id.class).to eq(Hash)
    end

    xit 'makes a list of the number of items offered by each merchant' do
      @sales_analyst.items_per_merchant
      expect(@sales_analyst.items_per_merchant.class).to be(Array)
      expect(@sales_analyst.items_per_merchant.count).to be(475)
      expect(@sales_analyst.items_per_merchant.sum).to be(1367)
    end

    xit 'what is the average items per merchant' do
      expect(@sales_analyst.average_items_per_merchant).to eq(2.88)
    end

    xit 'what is the standard deviation' do
      expect(@sales_analyst.average_items_per_merchant_standard_deviation).to eq(3.26)
    end

    xit 'which merchants have above one st. dev. avg products offered' do
      expect(@sales_analyst.merchants_with_high_item_count.class).to eq(Array)
      sample1 = @sales_analyst.merchant_repo.find_by_id(@sales_analyst.merchants_with_high_item_count[0].id).id
      sample2 = @sales_analyst.merchant_repo.find_by_id(@sales_analyst.merchants_with_high_item_count[1].id).id
      sample3 = @sales_analyst.merchant_repo.find_by_id(@sales_analyst.merchants_with_high_item_count[2].id).id
      expect(@sales_analyst.group_items_by_merchant_id[sample1].count).to be > 6.14
      expect(@sales_analyst.group_items_by_merchant_id[sample2].count).to be > 6.14
      expect(@sales_analyst.group_items_by_merchant_id[sample3].count).to be > 6.14
    end

    xit 'what is the avg item price for a merchant' do
      @sales_analyst.merchants_with_high_item_count
      sample1 = @sales_analyst.big_box_ids[0]
      sample2 = @sales_analyst.big_box_ids[1]
      expect(@sales_analyst.average_item_price_for_merchant(sample1).class).to eq(BigDecimal)
      expect(@sales_analyst.average_item_price_for_merchant(sample2).class).to eq(BigDecimal)
    end

    xit 'what is the avg avg price for a merchant' do
      expect(@sales_analyst.average_average_price_per_merchant.class).to eq(BigDecimal)
    end

    xit 'average_item_price_standard_deviation' do
      expect(@sales_analyst.average_item_price_standard_deviation).to be_a(Float)
    end

    xit 'what items are over two st. devs above avg item price' do
      expect(@sales_analyst.golden_items.class).to eq(Array)
      expect(@sales_analyst.golden_items.count).to eq(5)
      expect(@sales_analyst.golden_items[0].class).to eq(Item)
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

    xit 'invoice_paid_in_full?' do
      expect(@sales_analyst.invoice_paid_in_full?(@sample1.id)).to eq(true)
      expect(@sales_analyst.invoice_paid_in_full?(@sample2.id)).to eq(false)
    end

    xit 'returns the total $ amount of the Invoice with the corresponding id' do
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

    xit 'gives total revenue by date' do
      revenue = @sales_analyst.total_revenue_by_date(Time.parse("2012-11-23"))
      expect(revenue.class).to eq(BigDecimal)
    end

    it 'returns the top revenue earners as a list of merchants' do
      top = @sales_analyst.top_revenue_earners(4)
      expect(top.class).to eq(Array)
      expect(top.length).to eq(4)
      expect(top[2].class).to eq(Merchant)
    end

    xit 'returns merchants with pending invoices' do
      pending = @sales_analyst.merchants_with_pending_invoices
      expect(pending).to be_a(Array)
      expect(pending.first).to be_a(Merchant)
    end

    xit 'returns merchants with only one item in their inventory' do
      expected = @sales_analyst.merchants_with_only_one_item
      expect(expected).to be_a(Array)
      expect(expected.first).to be_a(Merchant)
    end

    xit 'returns merchants that only sell one item by the month of their creation' do
      expected = @sales_analyst.merchants_with_only_one_item_registered_in_month("March")

      expect(expected).to be_a(Array)
      expect(expected.last).to be_a(Merchant)
    end

    xit 'returns total revenue for a single merchant' do
      expected = @sales_analyst.revenue_by_merchant(12335345)

      expect(expected).to be_a(BigDecimal)
    end

  end
end
