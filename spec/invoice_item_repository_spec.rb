require 'RSpec'
require 'SimpleCov'
require_relative '../lib/invoice_item.rb'
require_relative '../lib/invoice_item_repository.rb'
require_relative '../lib/sales_engine.rb'
SimpleCov.start

RSpec.describe InvoiceRepository do
  # declares variables to be used by following tests
  before :each do
  @invoice_item_1 = InvoiceItem.new({ id: 6, item_id: 7, invoice_id: 8, quantity: 1, unit_price: 1 , created_at: "2022-02-25 17:49:56.871723", updated_at: "2022-02-26 00:51:07 UTC" })
  @invoice_item_2 = InvoiceItem.new({ id: 7, item_id: 8, invoice_id: 9, quantity: 2, unit_price: 2 , created_at: "2022-02-25 17:49:56.871723", updated_at: "2022-02-26 00:51:07 UTC"})
  @invoice_item_3 = InvoiceItem.new({ id: 8, item_id: 9, invoice_id: 10, quantity: 3, unit_price: 3 , created_at: "2022-02-25 17:49:56.871723", updated_at: "2022-02-26 00:51:07 UTC"})
  @iir = InvoiceRepository.new([invoice_item_1, invoice_item_2, invoice_item_3])
  end

  it 'exists' do
    expect(@iir).to be_a(InvoiceItemRepository)
  end

  it 'finds by invoice_item id' do
    expect(@iir.find_by_id(6)).to eq(@invoice_item_1)
    expect(@iir.find_by_id(7)).to eq(@invoice_item_2)
    expect(@iir.find_by_id(8)).to eq(@invoice_item_3)
  end

  it 'find all by item_id' do
    expect(@iir.find_all_by_item_id(7)).to eq(@invoice_item_1)
    eexpect(@iir.find_all_by_item_id(8)).to eq(@invoice_item_2)
    expect(@iir.find_all_by_item_id(9)).to eq(@invoice_item_3)
  end

  it 'find all by invoice_id' do
    expect(@iir.find_all_by_invoice_id(8)).to eq(@invoice_item_1)
    eexpect(@iir.find_all_by_invoice_id(9)).to eq(@invoice_item_2)
    expect(@iir.find_all_by_invoice_id(10)).to eq(@invoice_item_3)
  end

  it 'can create new invoice_items' do
    @iir.create({ id: 9, item_id: 10, invoice_id: 11, quantity: 4, unit_price: 3 , created_at: "2022-02-25 17:49:56.871723", updated_at: "2022-02-26 00:51:07 UTC"})
    expect(@iir.all.length).to eq(4)
    expect(@iir.all.last).to be_a(InvoiceItem)
    expect(@iir.all.last.id).to be_a(9)
  end

  it 'initializes from SalesEngine#invoices()' do
    se = SalesEngine.from_csv({:invoice_items => "./data/invoice_item.csv"})
    iir = se.invoice_items
    expect(@iir).to be_a(InvoiceItemRepository)
    expect(@iir.find_by_id(22)).to be_a(InvoiceItem)

  end
end
