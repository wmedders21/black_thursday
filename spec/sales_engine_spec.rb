require './lib/sales_engine'

RSpec.describe SalesEngine do

  before :each do
    @se = SalesEngine.new(@data_hash)
    @data_hash = {
      items:      './data/items.csv',
      merchants:  './data/merchants.csv'
    }

  end

  it 'exists' do
    # se = SalesEngine.new(@data_hash)
    expect(@se).to be_an_instance(SalesEngine)
  end

  it 'can receive data from the csv' do
    # se = SalesEngine.new(@data_hash)
    expect(@se).to be_an_instance(SalesEngine)
    expect(@se.items).to be_an_instance(ItemRepository)
    expect(@se.merchants).to be_an_instance(MerchantRepository)
  end
end
