class CouponSerializer
  include JSONAPI::Serializer
  attributes :name, :code, :discount, :discount_type, :merchant_id, :active, :use_count
end