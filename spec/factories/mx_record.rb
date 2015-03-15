
FactoryGirl.define do
  factory :mx_record do
    sequence(:hostname) {|n| "mx#{n}.example.com" }
    sequence(:address) {|n| "1.2.3.#{n}" }
  end
end
