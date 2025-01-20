require "rails_helper"
RSpec.describe "Merchant Coupon endpoints" do
  before :each do
    @merchant1 = Merchant.create!(name: "Acme Retailers")
    @merchant2 = Merchant.create!(name: "Tech Haven")

    @coupon1 = Coupon.create!(
      merchant: @merchant1,
      name: "Free Shipping on Orders Over $50",
      code: "FREESHIP50",
      discount: 20,
      discount_type: "percent-off",
      active: true,
    )

    @coupon2 = Coupon.create!(
      merchant: @merchant1,
      name: "Buy One Get One 50% Off",
      code: "BOGO50",
      discount: 50,
      discount_type: "percent-off",
      active: true,
    )

    @coupon3 = Coupon.create!(
      merchant: @merchant2,
      name: "10% Off Your First Purchase",
      code: "WELCOME10",
      discount: 10,
      discount_type: "percent-off",
      active: true
    )
  end
  
  it "should return all of a merchant's coupons" do
    get "/api/v1/merchants/#{@merchant1.id}/coupons"
    
    json = JSON.parse(response.body, symbolize_names: true)
    
    expect(response).to be_successful
    expect(json[:data].count).to eq(1)
    expect(json[:data][0][:id]).to eq(@coupon1.id.to_s)
    expect(json[:data][0][:type]).to eq("coupon")
    expect(json[:data][0][:attributes][:name]).to eq(@coupon1.name)
    expect(json[:data][0][:attributes][:code]).to eq(@coupon1.code)
    expect(json[:data][0][:attributes][:percent_off]).to eq(@coupon1.percent_off)
    expect(json[:data][0][:attributes][:dollar_off]).to eq(@coupon1.dollar_off)
  end
end