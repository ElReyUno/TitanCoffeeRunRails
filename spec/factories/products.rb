FactoryBot.define do
  factory :product do
    name { "MyString" }
    price { "9.99" }
    available_sizes { "MyText" }
    active { false }
  end
end
