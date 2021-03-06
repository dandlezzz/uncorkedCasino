require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'tables' do
before(:each) do
  ApplicationController.any_instance.stub(:restrict_access => true)
 	@house = House.create()
  @user = FactoryGirl.create(:user)
  @user1 = FactoryGirl.create(:user)
  @user2 = FactoryGirl.create(:user)
  @user3 = FactoryGirl.create(:user)
  @user4 = FactoryGirl.create(:user)
  @house.games << Game.create(name: "blackjack")
  @table1 = Table.create(number: 1)
  @table2 = Table.create(number: 2)
  @house.games.first.tables << @table1
  @house.games.first.tables << @table2
	@user1.sit(@table1)
	@user2.sit(@table1)
	@user3.sit(@table1)
	@user4.sit(@table1)
	@user.sign_in
	@user.sit(@table2)
end

put 'api/tables/:id' do
	example "Sit at a table" do
		do_request({:id => @table1.id, :sit => 'any', :token => @user.api_key.access_token})
		response_body.should include '2'
	end
end

put 'api/tables/:id' do
	example "Place an initial bet" do
		@user1.sign_in
		@table1.deal
		do_request({:id => @table1.id, :bet => '10', :token => @user1.api_key.access_token})
		response_body.should include '10'
		response_body.should include @user1.seat.placed_bet.to_s
		response_body.should include "rank"
		response_body.should include @user1.seat.table.cards.to_json.to_s
	end
end

	put 'api/tables/:id' do
		example "Request a hit" do
			@user1.sign_in
			@user1.seat.place_bet(10)
			@user1.seat.cards << Card.new(rank: 4)
			@user1.seat.cards << Card.new(rank: 4)
			do_request({:id => @table1.id, :decision => "hit",:token => @user1.api_key.access_token})
			JSON.parse(response_body)["Hand"].count.should eq 3
		end
	end

	put 'api/tables/:id' do
		example 'Player stands with hand' do
			@user.seat.place_bet(10)
			@user.cards.count.should == 2
			do_request({:id => @table2.id, :decision => "stand",:token => @user.api_key.access_token})
			JSON.parse(response_body)["Hand"].count.should eq 2
		end
	end
end











