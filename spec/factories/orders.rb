FactoryBot.define do
  factory :order do
    user { nil }
    total_amount { "9.99" }
    notes { "MyText" }
    status { 1 }
    titan_fund_donation { "9.99" }
  end
end
