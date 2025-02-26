class OrdersController < ApplicationController
  before_action :authenticate_user!, only: [:create]

  def create
    @order = Order.new(order_params)
    @order.user = current_user
    @order.total = current_cart.total_price

    if @order.save

      current_cart.cart_items.each do |carts_item|
        product_list = ProdcutList.new
        product_list.order = @order
        product_list.product_name = cart_item.product.title
        product_list.product_price = cart_item.product.price
        product_list.quantity = cart_item.quantity
        product_list.save
      end
      current_cart.clean!
      OrderMailer.notify_order_placed(@order).deliver!

      redirect_to order_path(@order.token)
    else
      render 'carts/checkout'
    end
  end

  def show
    @order = Order.find_by_token(params[:id])
    @product_lists = @order.product_lists
  end

  def index
    @orders = current_user.orders.order("id DESC")
  end

  def pay_with_creditcard
    @order = Order.find_by_token(params[:id])
    @order.set_payment_with!("creditcard")
    @order.make_payment!

    redirect_to order_path(@order.token), notice: "使用信用卡成功完成付款"
  end

  def pay_with_ewallet
    @order = Order.find_by_token(params[:id])
    @order.set_payment_with!("ewallet")
    @order.make_payment!

    redirect_to order_path(@order.token), notice: "使用電子錢包成功完成付款"
  end

  private

  def order_params
    params.require(:order).permit(:billing_name, :billing_address, :shipping_name, :shipping_address)
  end
end
