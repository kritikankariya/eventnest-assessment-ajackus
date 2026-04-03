FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    role { "attendee" }

    trait :organizer do
      role { "organizer" }
    end

    trait :admin do
      role { "admin" }
    end
  end

  factory :event do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    venue { "#{Faker::Address.street_address}, #{Faker::Address.city}" }
    city { Faker::Address.city }
    starts_at { 2.weeks.from_now }
    ends_at { 2.weeks.from_now + 3.hours }
    status { "published" }
    category { %w[music conference workshop sports].sample }
    association :user, factory: [:user, :organizer]
  end

  factory :ticket_tier do
    name { "General Admission" }
    price { 29.99 }
    quantity { 100 }
    sold_count { 0 }
    association :event
  end

  factory :order do
    association :user
    association :event
    status { "pending" }
    total_amount { 59.98 }
    confirmation_number { "EVN-#{SecureRandom.hex(4).upcase}" }
  end

  factory :order_item do
    association :order
    association :ticket_tier
    quantity { 2 }
    unit_price { 29.99 }
  end

  factory :payment do
    association :order
    amount { 59.98 }
    status { "pending" }
    provider { "stripe" }
  end
end
