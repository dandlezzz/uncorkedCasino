FactoryGirl.define do
  factory :user do
    username { Faker::Name.name }
    email { Faker::Internet.email }
    chips 500
    password "123455678"
    password_confirmation { |u| u.password }
  end

  factory :api_key do
    access_token "fherohgre08gh09"
  end
   factory :game do
    name "blackjack"
    house_id 1
  end


 
end


