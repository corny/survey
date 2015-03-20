
FactoryGirl.define do
  factory :mx_host do
    sequence(:address) {|n| "1.2.3.#{n}" }
  end
end
