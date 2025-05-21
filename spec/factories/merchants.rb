FactoryBot.define do
  factory :merchant do
    slug { Faker::Company.unique.name.parameterize }
  end
end
