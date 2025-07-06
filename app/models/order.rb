class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  
  enum status:
  
  validates :total_amount, 
            presence: true, 
            numericality: { greater_than: 0 }
  validates :status, presence: true
  validates :titan_fund_donation, 
            numericality: { greater_than_or_equal_to: 0 }, 
            allow_nil: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :with_donation, -> { where.not(titan_fund_donation: [nil, 0]) }
  
  before_save :calculate_total
  after_create :send_confirmation_email
  
  def order_number
    "TCR-#{id.to_s.rjust(6, '0')}"
  end
  
  def items_count
    order_items.sum(:quantity)
  end
  
  def subtotal
    order_items.sum(:subtotal)
  end
  
  def donation_amount
    titan_fund_donation || 0
  end
  
  def can_be_cancelled?
    pending? || confirmed?
  end
  
  private
  
  def calculate_total
    self.total_amount = subtotal + donation_amount
  end
  
  def send_confirmation_email
    # OrderMailer.confirmation(self).deliver_later
  end
end
