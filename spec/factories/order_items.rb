FactoryBot.define do
  factory :order_item do
    order { nil }
    product { nil }
    size { "MyString" }
    quantity { 1 }
    unit_price { "9.99" }
    subtotal { "9.99" }
  end
end
