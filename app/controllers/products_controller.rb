class ProductsController < ApplicationController
  before_action :authenticate_user!

  def index
    @products = Product.where(active: true)
    @cart_items = session[:cart] || {}
  end
end
