class Api::V1::Merchants::CouponsController < ApplicationController  
  def index
    merchant = Merchant.find_by(id: params[:merchant_id])

    if merchant.nil?
      render json: ErrorSerializer.format_errors(["This merchant does not have any coupons"]), status: :not_found
      return
    end

    coupons = merchant.coupons

    if params[:filter]
      filtered_coupons = coupons.filter_status(params)
      render json: CouponSerializer.new(filtered_coupons)
    else
      render json: CouponSerializer.new(coupons), status: :ok
    end
  end

  def show
    merchant = Merchant.find(params[:merchant_id])
    coupon = merchant.coupons.find(params[:id])
    render json: coupon.serialized_with_counter
  end

   def create
    merchant = Merchant.find(params[:merchant_id])
    if Coupon.active_coupon_limit(merchant)
      render json: ErrorSerializer.format_errors(["This merchant already has 5 active coupons"]), status: :too_many_requests
      return
    else
      coupon = merchant.coupons.create!(coupon_params)
      render json: CouponSerializer.new(coupon), status: :created
    end
  end

  def update
    coupon = Coupon.find(params[:id])
    merchant = Merchant.find(params[:merchant_id])

    if coupon_params[:active].to_s == "true" && Coupon.active_coupon_limit(merchant)
      render json: ErrorSerializer.format_errors(["This merchant already has 5 active coupons"]), status: :too_many_requests
      return
    end

    if coupon_params[:active].to_s == "false" && Coupon.packaged_invoices.exists?(id: coupon.id)
      render json: { error: "This coupon has a pending invoice therefore cannot be activated" }, status: :unprocessable_entity
      return
    end
    
    if coupon.update(coupon_params)
      render json: CouponSerializer.new(coupon), status: :ok
    else 
      render json: { error: "Failed to update coupon" }, status: :unprocessable_entity
    end
  end

  private

  def coupon_params
    params.require(:coupon).permit(:name, :code, :discount, :discount_type, :active, :merchant_id)
  end
end