class Product < ApplicationRecord
    has_many :order_items, dependent: :destroy
  has_many :orders, through: :order_items
  has_many :users, through: :orders

  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :available_sizes, presence: true

  scope :active, -> { where(active: true) }
  scope :by_popularity, -> { joins(:order_items).group(:id).order("COUNT(order_items.id) DESC") }

  before_validation :set_default_active

  def available_sizes_array
    JSON.parse(available_sizes || "[]")
  end

  def formatted_price
    "$#{price.to_f}"
  end

  def total_orders_count
    order_items.sum(:quantity)
  end

  def total_revenue
    order_items.sum(:subtotal)
  end

  private

  def set_default_active
    self.active = true if active.nil?
  end
end
