class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :orders, dependent: :destroy
  has_many :order_items, through: :orders
  has_many :products, through: :order_items

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  scope :admins, -> { where(admin: true) }
  scope :regular_users, -> { where(admin: false) }

  def admin?
    admin
  end

  def full_name
    email.split("@").first.titleize
  end

  def total_orders_count
    orders.count
  end

  def total_spent
    orders.sum(:total_amount)
  end
end
