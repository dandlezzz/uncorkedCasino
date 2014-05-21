class Table < ActiveRecord::Base
	belongs_to :game
	has_one :shoe
	has_many :cards
	has_many :seats
	has_many :users, through: :seats

	before_create :setup

### Table setup ###
	
	def setup
		self.number = Table.count + 1
		self.shoe = Shoe.create
		self.low = 5
		self.high = 10
		5.times do |i|
			self.seats << Seat.create( number: i + 1  )
		end
		fill_shoe(3)
	end

	def fill_shoe(decks=1)
		decks.times do
			deck = Deck.create
			deck.cards.each do |card|
				self.shoe.cards << card
			end
		end
	end

	### Table behaviors ###

	def deal

		self.users.each do |user|
			if user.seat.in_hand?
				2.times do 
					user.seat.cards << random_card 
				end
			end
		end
		2.times { self.cards << random_card }
	end

	def hit(user)
		user.seat.cards << random_card
		if bust(self.handify(user.seat.cards))
			user.seat.cards = []
			bank = self.game.house.bank 
			bank += user.seat.placed_bet
			self.game.house.update(bank: bank) 
			user.seat.update(placed_bet: 0)
			stand(user)		
		else
			## Throw it back to the user to decide again
		end
	end

  def stand(user)
  	self.action += 1
  end

  def double_down(user)
  	user.seat.placed_bet *= 2
  	self.hit(user)
  	self.stand(user)
  end

  # def split(user)
  # 	## totally unfinished... problematic
  # 	if handify(user.seat.cards).uniq.count == 1
  # 		temp_seat = Seat.new(user_id: user.id, table_id: self.id)
  # 		temp_seat.cards << user.seat.cards.shift
  # 		temp_seat.cards << @rack.shift
  # 		## pass it to user decision
  # 		user.seat.cards << @rack.shift
  # 		## pass it to user decision
  # 	end
  # end

	def draw
		hand = handify(self.cards)
		if bust(hand)
			dealer_bust_payout
		else
			if hand.inject(:+) <= 16 
				self.cards << random_card
				draw
			else
				hand.inject(:+)
			end
		end
		handify(self.cards).inject(:+)
	end

	def next_hand
		self.cards = []
		self.action = 1
		if self.shoe.cards.where(played: false).count < 30
			fill_shoe
		end
	end

	def random_card
		cards = []
		self.shoe.cards.each { |card| cards << card if !card.played }
		cards.shuffle.shift.played!
	end

### Payout types ###

	def dealer_bust_payout
		self.users.each do |user|
			user.chips += user.seat.placed_bet * 2
		end
		next_hand
	end

	def winner(user_cards, house_cards)
		result = handify(user_cards).inject(:+) - handify(house_cards).inject(:+)
		if result == 0
			"Push"
		elsif result > 0
			"Win"
		elsif result < 0
			"Loss"
		end
	end
			
	def standard_payout
		self.users.each do |user|
			if handify(user.seat.cards) < draw
				user.chips += user.seat.placed_bet * 2
				user.seat.update(placed_bet: 0)
			elsif handify(user.seat.cards) == draw
				user.chips += user.seat.placed_bet
				user.seat.update(placed_bet: 0)
			else
				self.game.house.bank += user.seat.placed_bet
				user.seat.update(placed_bet: 0)
			end
		end
		next_hand
	end

	def house_blackjack_payouts
		users.each do |user|
			if blackjack(user.seat.cards)
				user.chips += user.seat.placed_bet
				user.seat.update(placed_bet: 0)
			else
				user.seat.update(placed_bet: 0)
			end
		end
		next_hand
	end

### Table state ###

	def first_to_act
		self.users.map{|user| user.seat.number if user.seat.in_hand?}.first
	end

	def handify(cards)
		cards.map { |card| card.rank.between?(10,13) ? 10 : card.rank }.sort
	end

	def blackjack(cards)
		jack = handify(cards) & [1,10,11,12,13]
		if jack.count == 2 && jack.include?(1)
			true
		end
	end

	def bust(hand)
		return true if hand.inject(:+) > 21
	end

	def player_count
		self.users.count
	end

	def game_name
		self.game.name
	end

	def vacancies
		vacants = []
		self.seats.each do |seat| 
			if !seat.occupied? 
				vacants << seat
			end
		end
		vacants
	end

	def first_vacant
		self.vacancies.sort.first
	end

	def seat_qty
		return 5 if self.game.name == "blackjack" 		
	end

	def full_table?
		self.vacancies.length == 0
	end
end
