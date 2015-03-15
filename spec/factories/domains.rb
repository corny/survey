
FactoryGirl.define do
  factory :domain do
    sequence(:name) {|n| "#{n}.example.com" }
  end
end
