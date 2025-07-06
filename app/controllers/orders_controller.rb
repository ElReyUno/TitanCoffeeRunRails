class OrdersController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @orders = current_user.orders.includes(:order_items, :products)
  end
  
  def show
    @order = current_user.orders.find(params[:id])
  end
  
  def create
    @order = current_user.orders.build(order_params)
    
    if @order.save
      process_cart_items
      session[:cart] = nil
      redirect_to @order, notice: 'Order was successfully created.'
    else
      redirect_to products_path, alert: 'There was an error creating your order.'
    end
  end
  
  private
  
  def order_params
    params.require(:order).permit(:notes, :titan_fund_donation)
  end
  
  def process_cart_items
    cart_items = session[:cart] || {}
    cart_items.each do |product_id, item_data|
      product = Product.find(product_id)
      @order.order_items.create!(
        product: product,
        size: item_data['size'],
        quantity: item_data['quantity'],
        unit_price: product.price
      )
    end
  end
end
