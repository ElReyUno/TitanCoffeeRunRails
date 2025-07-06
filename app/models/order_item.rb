class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :size, presence: true, inclusion: { in: %w[Small Medium Large] }
  validates :quantity, presence: true, numericality: { greater_than: 0, less_than: 100 }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validates :subtotal, presence: true, numericality: { greater_than: 0 }

  before_validation :set_unit_price
  before_save :calculate_subtotal

  def total_price
    quantity * unit_price
  end

  def formatted_unit_price
    "$#{unit_price.to_f}"
  end

  def formatted_subtotal
    "$#{subtotal.to_f}"
  end

  private

  def set_unit_price
    self.unit_price = product.price if product.present? && unit_price.blank?
  end

  def calculate_subtotal
    self.subtotal = quantity * unit_price
  end
end
