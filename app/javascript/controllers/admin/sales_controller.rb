class Admin::SalesController < Admin::BaseController
  def index
    @orders = Order.includes(:user, :order_items, :products)
    @sales_data = calculate_sales_data
  end

  private

  def calculate_sales_data
    current_month_range = Time.current.beginning_of_month..Time.current.end_of_month
    current_month_orders = Order.where(created_at: current_month_range)

    {
      total_orders:       Order.count,
      total_revenue:      Order.sum(:total_amount),
      this_month_orders:  current_month_orders.count,
      this_month_revenue: current_month_orders.sum(:total_amount),
    }
  end
end
