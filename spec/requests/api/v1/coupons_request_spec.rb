require "rails_helper"
RSpec.describe "Merchant Coupon endpoints" do
  before :each do
    @merchant1 = create(:merchant)
    @merchant2 = create(:merchant)
    @merchant3 = create(:merchant)
    @merchant4 = create(:merchant)

    @coupon1 = create(:coupon, merchant_id: @merchant1.id)
    @coupon2 = create(:coupon, merchant_id: @merchant1.id)
    @coupon3 = create(:coupon, merchant_id: @merchant1.id)
    @coupon4 = create(:coupon, merchant_id: @merchant2.id)

    @invoice1 = create(:invoice, merchant_id: @merchant1.id, coupon_id:@coupon1.id)
    @invoice2 = create(:invoice, merchant_id: @merchant2.id, coupon_id:@coupon1.id)
  end

  describe "Get All of a Merchant's Coupons" do
    it "should return all of a merchant's coupons" do
      get "/api/v1/merchants/#{@merchant1.id}/coupons"
      
      json = JSON.parse(response.body, symbolize_names: true)
      
      expect(response).to be_successful
      expect(json[:data].count).to eq(3)
      expect(json[:data][0][:id]).to eq(@coupon1.id.to_s)
      expect(json[:data][0][:type]).to eq("coupon")
      expect(json[:data][0][:attributes][:name]).to eq(@coupon1.name)
      expect(json[:data][0][:attributes][:code]).to eq(@coupon1.code)
      expect(json[:data][0][:attributes][:discount_type]).to eq(@coupon1.discount_type)
      expect(json[:data][0][:attributes][:active]).to eq(@coupon1.active)
    end

    it "should return an error message when a merchant is not found" do
      get "/api/v1/merchants/999999/coupons"

      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:not_found)
      expect(json[:message]).to eq("Your query could not be completed")
      expect(json[:errors]).to be_an Array
      expect(json[:errors].first).to eq("This merchant does not have any coupons")
    end
  end

  describe "Get One Coupon For a Given Merchant" do
    it "should return one coupon for a given merchant" do
      get "/api/v1/merchants/#{@merchant1.id}/coupons/#{@coupon1.id}"

      json = JSON.parse(response.body, symbolize_names: true)
      
      expect(response).to be_successful
      expect(json[:data]).to be_a(Hash)
      expect(json[:data][:id]).to eq("#{@coupon1.id}")
      expect(json[:data][:type]).to eq("coupon")
      expect(json[:data][:attributes][:name]).to eq(@coupon1.name)
      expect(json[:data][:attributes][:code]).to eq(@coupon1.code)
      expect(json[:data][:attributes][:discount]).to eq(@coupon1.discount)
      expect(json[:data][:attributes][:discount_type]).to eq(@coupon1.discount_type)
      expect(json[:data][:attributes][:active]).to eq(@coupon1.active)
      expect(json[:data][:attributes][:merchant_id]).to eq(@merchant1.id)
    end

    it "should return one coupon and show how many times that coupon has been used" do
      get "/api/v1/merchants/#{@merchant1.id}/coupons/#{@coupon1.id}"

      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:meta]).to be_a(Hash)
      expect(json[:meta][:coupon_use_count]).to eq(2)
    end

    it "should return an error message when coupon is not found" do
      get "/api/v1/merchants/#{@merchant1.id}/coupons/999999"

      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:not_found)
      expect(json[:message]).to eq("Your query could not be completed")
      expect(json[:errors]).to be_a Array
      expect(json[:errors].first).to eq("Couldn't find Coupon with 'id'=999999 [WHERE \"coupons\".\"merchant_id\" = $1]")
    end
  end

  describe "Create a New Coupon:" do
    it "should create a new coupon" do
      new_coupon = {
        name: "Spring Sale",
        code: "SPRING2025",
        discount: 10,
        discount_type: "percent",
        active: true,
        merchant_id: @merchant1.id
      }

      post "/api/v1/merchants/#{@merchant1.id}/coupons", params: new_coupon, as: :json
      json = JSON.parse(response.body, symbolize_names: true)
      expect(response).to have_http_status(:created)
      expect(json[:data][:attributes][:name]).to eq(new_coupon[:name])
      expect(json[:data][:attributes][:code]).to eq(new_coupon[:code])
      expect(json[:data][:attributes][:discount]).to eq(new_coupon[:discount])
      expect(json[:data][:attributes][:discount_type]).to eq(new_coupon[:discount_type])
      expect(json[:data][:attributes][:active]).to eq(new_coupon[:active])
      expect(json[:data][:attributes][:merchant_id]).to eq(new_coupon[:merchant_id])
    end

    it "should return an error when there are more than 5 active coupons" do
      coupon4 = create(:coupon, merchant_id: @merchant1.id)
      coupon5 = create(:coupon, merchant_id: @merchant1.id)

      new_coupon = {
        name: "Holiday Discount",
        code: "HOLIDAY15",
        discount: 15,
        discount_type: "percent",
        active: true,
        merchant_id: @merchant1.id
      }

      post "/api/v1/merchants/#{@merchant1.id}/coupons", params: new_coupon, as: :json

      expect(response).to have_http_status(:too_many_requests)
    end

    it "should return an error if the code is not unique" do
      new_coupon1 = {
        name: "Free Shipping",
        code: "FREESHIP",
        discount: 0,
        discount_type: "free_shipping",
        active: true,
        merchant_id: @merchant1.id
      }

      new_coupon2 = {
        name: "Free Shipping",
        code: "FREESHIP",
        discount: 0,
        discount_type: "free_shipping",
        active: true,
        merchant_id: @merchant1.id
      }

      post "/api/v1/merchants/#{@merchant1.id}/coupons", params: new_coupon1, as: :json
      expect(response).to have_http_status(:created)

      post "/api/v1/merchants/#{@merchant1.id}/coupons", params: new_coupon2, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "Update an existing Coupon:" do
    it "can update a coupon's active status" do      
      updated_coupon = {
        name: "Free Shipping",
        code: "FREESHIP",
        discount: 0,
        discount_type: "free_shipping",
        active: false,
      }

      patch "/api/v1/merchants/#{@merchant2.id}/coupons/#{@coupon4.id}", params: { coupon: updated_coupon }

      json = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_successful
      expect(json[:data]).to be_a(Hash)
      expect(json[:data][:id]).to eq("#{@coupon4.id}")
      expect(json[:data][:type]).to eq("coupon")
      expect(json[:data][:attributes][:name]).to eq(updated_coupon[:name])
      expect(json[:data][:attributes][:code]).to eq(updated_coupon[:code])
      expect(json[:data][:attributes][:discount]).to eq(updated_coupon[:discount])
      expect(json[:data][:attributes][:discount]).to eq(updated_coupon[:discount])
      expect(json[:data][:attributes][:active]).to eq(updated_coupon[:active])
      expect(json[:data][:attributes][:merchant_id]).to eq(@merchant2.id)
    end

    it "should not deactivate if there are pending invoices" do
      invoice_1 = create(:invoice, status: 'packaged', merchant_id: @merchant2.id, coupon_id: @coupon4.id)
      
      updated_coupon = {
        coupon: {
          name: "Free Shipping",
          code: "FREESHIP",
          discount: 0,
          discount_type: "free_shipping",
          active: false,
          merchant_id: @merchant2.id
        }
      }
      patch "/api/v1/merchants/#{@merchant2.id}/coupons/#{@coupon4.id}", params: updated_coupon
      
      json = JSON.parse(response.body, symbolize_names: true)
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json[:error]).to eq("This coupon has a pending invoice therefore cannot be activated")
    end
  end

  describe "Filter by Active Status" do
    it "can filter by active status" do
      update_coupon3 = {
        active: false,
      }
      patch "/api/v1/merchants/#{@merchant1.id}/coupons/#{@coupon3.id}", params: { coupon: update_coupon3 }

      get "/api/v1/merchants/#{@merchant1.id}/coupons", params: { filter: "active" }

      expect(response).to be_successful
      coupons = JSON.parse(response.body, symbolize_names: true)[:data]
      expect(coupons.count).to eq(2)

      get "/api/v1/merchants/#{@merchant1.id}/coupons", params: { filter: 'inactive' }

      expect(response).to be_successful
      coupons = JSON.parse(response.body, symbolize_names: true)[:data]
      expect(coupons.count).to eq(1)
    end
  end
end

