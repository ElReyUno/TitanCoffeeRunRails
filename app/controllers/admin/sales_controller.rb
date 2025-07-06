class Admin::SalesController < Admin::BaseController
  def index
    @orders = Order.includes(:user, :order_items, :products)
    @sales_data = calculate_sales_data
  end

  private

  def calculate_sales_data
    {
      total_orders:       Order.count,
      total_revenue:      Order.sum(:total_amount),
      this_month_orders:  Order.where(created_at: Time.current.beginning_of_month..Time.current.end_of_month).count,
      this_month_revenue: Order.where(created_at: Time.current.beginning_of_month..Time.current.end_of_month).sum(:total_amount),
    }
  end
end
