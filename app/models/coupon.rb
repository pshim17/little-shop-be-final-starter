class Coupon < ApplicationRecord
  belongs_to :merchant
  has_many :invoices
  validates_presence_of :name 
  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :discount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates_presence_of :discount_type 
  validates :active, inclusion: { in: [true, false] }

  def serialized_with_counter
    coupon_with_count = CouponSerializer.new(self).serializable_hash
    {
      data: coupon_with_count[:data],
      meta: {
        coupon_use_count: invoices.count
      }
    }
  end

  def self.active_coupon_limit(merchant) 
    merchant.coupons.where(active: true).count >= 5
  end

  def self.packaged_invoices
    joins(:invoices).where(invoices: { status: "packaged" })
  end

  def self.filter_status(params)
    if params[:filter] == "active"
      where(active: true)
    elsif params[:filter] == "inactive"
      where(active: false)
    else
      all
    end
  end
end