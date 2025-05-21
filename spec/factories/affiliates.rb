FactoryBot.define do
  factory :affiliate do
    association :merchant

    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    website_url { Faker::Internet.url }
    email { Faker::Internet.unique.email }
    commissions_total { Faker::Number.between(from: 0, to: 10_000_000) }
  end
end
