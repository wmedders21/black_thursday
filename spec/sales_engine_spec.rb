require 'pry'
require 'rspec'
require 'simplecov'
require './lib/sales_engine'
SimpleCov.start

RSpec.describe SalesEngine do
  it 'exists' do
    se = SalesEngine.from_csv({:items => "./data/items.csv", :merchants => "./data/merchants.csv"})
    expect(se.class).to eq(SalesEngine)
    binding.pry
  end
end
