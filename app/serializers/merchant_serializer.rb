class MerchantSerializer
  include JSONAPI::Serializer
  attributes :name

  attribute :item_count, if: Proc.new { |merchant, params|
    params && params[:count] == true
  } do |merchant|
    merchant.item_count
  end

  attribute :coupon_count, if: Proc.new { |merchant, params| 
    params && params[:coupon_count] == true
  } do |merchant|
    merchant.coupon_count
  end

  attribute :invoice_coupon_count, if: Proc.new { |merchant, params|
    params && params[:invoice_coupon_count] == true
  } do |merchant|
    merchant.invoice_coupon_count
  end
end
