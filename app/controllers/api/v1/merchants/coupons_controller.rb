class Api::V1::Merchants::CouponsController < ApplicationController  
  def index
    merchant = Merchant.find_by(id: params[:merchant_id])
    coupons = merchant.coupons
    
  end
end