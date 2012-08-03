require 'rubygems'
require 'sequel'
require 'csv'

#Prereqs:
#gem install sequel
#gem install sqlite3


class GrabBagDatabase
	attr_reader :db
	attr_accessor :gen_file,:npc_count, :max_draws, :event_name
	def initialize(filename = "gb.db")
		puts "Creating Grab Bag Database"
		db_exists = File.exists?(filename)
		@db = Sequel.sqlite(filename)

		@gen_file   = "grab_bag.csv"
		@npc_count  = 5
		@max_draws  = 4
		@event_name = "No Events"

		self.initialize_database # unless db_exists
		
		last_tagid  = @db[:bag].max(:id)
		@event_name = @db[:bag][:id => last_tagid][:event] unless last_tagid.nil?
	end

	def initialize_database
		puts "Initializing Database Tables"
		@db.create_table? :bag do
			primary_key :id
			#column :event, :draw, :is_drawn
			String :event, :null => false
			String :draw
			boolean :is_drawn, :default => false
		end
		@db.create_table? :npcs do
			primary_key :name, :auto_increment => false, :type => :text
			#column :name, :email, :chapter
			String :email
			String :chapter
		end
		#This table was equivalent to @db[:tag_log].filter(:change_type => 'draw')
		#@db.create_table? :draws do
		#	primary_key :id
		#	#column :npc_name
		#	foreign_key :npc_name, :npcs
		#	foreign_key :id, :bag
		#end
		# Used to determine who has which tag
		@db.create_table? :tags do
			foreign_key :draw_id, :bag, :key => :id
			boolean :spent, :default => false
			foreign_key :npc_name, :npcs, :key => :name, :type => :text
		end
		# 
		@db.create_table? :tag_log do
			primary_key :log_id
			String :change_type # acceptable values are 'draw', 'transfer', 'redeem', 'unredeem', and 'goblin'
			#enum :change_type, :elements=>['draw','transfer','redeem','goblin']
			foreign_key :draw_id, :bag, :key => :id
			foreign_key :npc_name, :npcs, :key => :name, :type => :text
			foreign_key :target_npc_name, :npcs, :key => :name, :type => :text
		end
		puts "Tables are Initialized"
	end


	# Lookup functions

	def get_npc_list
		@db[:npcs].map(:name).sort
	end

	def get_event_list
		@db[:bag].map(:event).uniq
	end

	def lookup_draw(draw_id)
		@db[:bag][:id => draw_id][:draw]
	end

	# Returns the total number of tickets in the grab bag for the current event
	def lookup_event_total(event = @event_name)
		@db[:bag].filter(:event => event).count
	end

	def lookup_event_left(event = @event_name)
		@db[:bag].filter(:event => event,:is_drawn => false).count
	end

	def lookup_npcs_at_event(event = @event_name)
		@db[:bag].filter(:event => event).join(:tag_log, :draw_id => :id).map(:npc_name).uniq
	end

	def lookup_npc_draw_count(npc, event = @event_name)
		@db[:bag].filter(:event => event).join(:tag_log, :draw_id => :id).filter(:change_type => "draw", :npc_name => npc).count
	end

	def lookup_npc_spend_count(npc, event = @event_name)
		@db[:bag].filter(:event => event).join(:tag_log, :draw_id => :id).filter(:change_type => "redeem", :npc_name => npc).count
	end

	def lookup_npc_transfer_count(npc, event = @event_name)
		@db[:bag].filter(:event => event).join(:tag_log, :draw_id => :id).filter(:change_type => "transfer", :npc_name => npc).count
	end

	def lookup_npc_chapter(name)
		@db[:npcs][:name => name].to_hash[:chapter]
	end

	def lookup_npc_email(name)
		@db[:npcs][:name => name].to_hash[:email]
	end

	# Lookup draws for an NPC at the passed event (or all, if :event == nil)
	def lookup_npc_draws(name, event = @event_name)
		#@db[:draws][:npc => name].to_a
		if event.nil?
			tag_ids = @db[:tag_log].filter(:change_type => 'draw', :npc_name => name).join(:bag, :id => :draw_id).map(:draw)
		else
			@db[:tag_log].filter(:change_type => 'draw', :event => event, :npc_name => name).join(:bag, :id => :draw_id).map(:draw)
		end
	end

	def lookup_npc_draw_ids(name, event = @event_name)
		@db[:tag_log].join(:bag,:id => :draw_id).filter(:change_type => 'draw', :event => event, :npc_name => name).map(:draw_id)
	end


	def lookup_npc_tagids(name, spent)
		@db[:tags].filter(:npc_name => name, :spent => spent).map(:draw_id)
	end

	# Lookup the tags an NPC currently has
	def lookup_npc_tags(name, spent = false)
		tagids = @db[:tags].filter(:npc_name => name, :spent => spent)
		tagids.join(:bag,:id=>:draw_id).map(:draw)
	end


	def lookup_log_for_npc(name)
		log = @db[:tag_log].join(:bag,:id => :draw_id).filter(:npc_name => name).all
		return self.parse_log(log)
	end

	def lookup_log_for_event(event = @event_name)
		log = @db[:tag_log].join(:bag,:id=>:draw_id).filter(:event => event).all
		return self.parse_log(log)
	end

	def lookup_log_for_event_draws(event = @event_name)
		log = @db[:tag_log].join(:bag,:id=>:draw_id).filter(:event=>event,:change_type=>'draw').all
		return self.parse_log(log)
	end

	def parse_log(log)
		text=""
		log.each do |val|
			key = val[:log_id]
			draw_text = self.lookup_draw(val[:draw_id])
			case val[:change_type]
			when 'draw'
				line = "#{key.to_s}: #{val[:npc_name]} drew ticket ##{val[:draw_id]}, #{draw_text}"
				text << line + "\r"
			when 'undraw'
				line = "#{key.to_s}: #{val[:npc_name]} undrew ticket ##{val[:draw_id]}, #{draw_text}"
				text << line + "\r"
			when 'redeem' 
				line = "#{key.to_s}: #{val[:npc_name]} redeemed ticket ##{val[:draw_id]}, #{draw_text}"
				text << line + "\r"
			when 'unredeem'
				line = "#{key.to_s}: #{val[:npc_name]} unredeemed ticket ##{val[:draw_id]}, #{draw_text}"
				text << line + "\r"
			when 'goblin'
				line = "#{key.to_s}: #{val[:npc_name]} converted ticket ##{val[:draw_id]}, #{draw_text}, into goblins"
				text << line + "\r"
			when 'transfer'
				line = "#{key.to_s}: #{val[:npc_name]} transferred ticket ##{val[:draw_id]}, #{draw_text}, to #{val[:target_npc_name]}"
				text << line + "\r"
			end
		end
		return text
	end

	
	#
	#
	# THESE ACTIONS MUTATE THE DATABASE AND ARE LOGGED
	#
	#


	def spend_nth_tag(name,index)
		tagid = lookup_npc_tagids(name, false)[index]

		@db[:tags].filter(:draw_id => tagid).update(:spent => true)
		@db[:tag_log] << {:draw_id => tagid, :npc_name => name, :change_type => "redeem"}
	end

	def unspend_nth_tag(name,index)
		tagid = lookup_npc_tagids(name, true)[index]

		@db[:tags].filter(:draw_id => tagid).update(:spent => false)
		@db[:tag_log] << {:draw_id => tagid, :npc_name => name, :change_type => "unredeem"}
	end

	def transfer_nth_tag(name,name2,index)
		tagid = lookup_npc_tagids(name, false)[index]

		@db.transaction do
			@db[:tags].filter(:draw_id => tagid).update(:npc_name => name2)
			@db[:tag_log] << {:draw_id => tagid, :npc_name => name, :change_type => "transfer", :target_npc_name => name2}
		end
	end

	def add_or_update_npc(name,chapter,email)
		#puts "add_or_update_npc(#{name},#{chapter},#{email})"
		if @db[:npcs][:name => name].nil?
			@db[:npcs] << {:name => name, :chapter => chapter, :email => email}
		else
			@db[:npcs].filter(:name => name).update(:chapter => chapter, :email => email)
		end
	end

	def rename_npc(name,new_name)
		unless @db[:npcs][:name => name].nil?
			@db[:npcs].filter(:name => name).update(:name => new_name)
		end
	end

	def delete_npc(npc_name)
		@db[:npcs].filter(:name => npc_name).delete
	end

	def undraw npc_name, index, event = @event_name
		tagid = lookup_npc_draw_ids(npc_name,event)[index]
		# Verify there is only one entry in the log
		if @db[:tag_log].filter(:draw_id => tagid).count > 1
			return false
		end
		
		@db.transaction do
			# @db[:bag] - Change :is_drawn to false
			@db[:bag].filter(:id => tagid).update(:is_drawn => false)
			
			# @db[:tags] - Remove it from the NPC's list of tags
			@db[:tags].filter(:draw_id => tagid).delete

			# @db[:tag_log] - Unlog the "draw"
			@db[:tag_log].filter(:draw_id => tagid).delete
		end
		return true
	end

	# Draw(npc_name, event, num_of_draws)
	# Returns an array containing the draws
	# Updates the database appropriately
	def draw npc_name, event, num_of_draws = 1
		undrawn_items_query = @db[:bag].filter(:event => event, :is_drawn => false)
		undrawn_item_ids = undrawn_items_query.map(:id)
		undrawn_items = undrawn_items_query.map(:draw)

		if undrawn_items.count == 0
			raise "Grab Bag is Empty"
		end

		@db.transaction do
			num_of_draws.times do
				if undrawn_items.count == 0
					raise "Insufficient items left in Grab Bag"
				end

				i = rand(undrawn_items.count)

				id = undrawn_item_ids[i]

				puts "Drew #{undrawn_items[i]}; ID: #{id}"

				# Update the database
				# @db[:bag] - Change :is_drawn to true
				undrawn_items_query.filter(:id => id).update(:is_drawn => true)
				
				# @db[:tags] - Add it to the NPC's list of tags
				@db[:tags] << {:draw_id => id, :npc_name => npc_name, :spent => false}

				# @db[:tag_log] - Log the "draw"
				@db[:tag_log] << {:draw_id => id, :change_type => 'draw', :npc_name => npc_name}

				# Remove that id so it's not chosen in future iterations
				undrawn_item_ids.delete_at(i)
				undrawn_items.delete_at(i)
			end
		end

	end


	# initialize_bag(min_draws)
	# Relevant options:
	# :min_draws - the total number of draws (minimum) to generate
	#
	# Sets up the bag database so that draws can be performed
	def initialize_bag min_draws
		if min_draws > @db[:bag].filter(:event => @event_name).count
			if @db[:bag].filter(:event => @event_name).count == 0
				self.build_bag(min_draws)
			else
				self.update_bag(min_draws)
			end
		end
	end

	# Build the bag in the first place
	def build_bag min_draws
		puts "Building new bag for event: #{@event_name}"
		build_data = CSV.read(@gen_file)

		# Count up the number of absolute and repeatable draws:
		absolute = 0
		repeated = 0
		build_data[1..-1].each do |row|
			if row[2] == "TRUE"
				absolute += row[1].to_i
			else
				repeated += row[1].to_i
			end
		end

		# Generate the bag:
		cycles = 1 + ((min_draws - absolute) / repeated).floor

		bag = @db[:bag]

		build_data[1..-1].each do |row|
			num = row[1].to_i
			num *= cycles if row[2] != "TRUE"
			num.times do
				bag.insert(:event => @event_name, :draw => row[0])
				#bag << row[0]
			end
		end
		puts "Built new bag for event"
	end

	# Add to the bag if necessary
	def update_bag(min_draws)
		build_data = CSV.read(@gen_file)

		current_count = @db[:bag].filter(:event => @event_name).count

		# Count up the number of absolute and repeatable draws:
		absolute = 0
		repeated = 0
		build_data[1..-1].each do |row|
			if row[2] == "TRUE"
				absolute += row[1].to_i
			else
				repeated += row[1].to_i
			end
		end

		# Generate the bag:
		cycles = ((min_draws - current_count) / repeated).ceil
		return if cycles <= 0

		bag = @db[:bag]

		build_data[1..-1].each do |row|
			num = row[1].to_i
			next if row[2] != "TRUE"
			num.times do
				bag.insert(:event => @event_name, :draw => row[0])
			end
		end
	end

	# This function manually creates a grab bag ticket and draws it as the given npc
	# If no NPC is given, it manually adds it to the bag and lists it as undrawn
	def add_tag(draw, npc = nil, event = @event_name)
		@db.transaction do
			@db[:bag] << {:event => event, :draw => draw}
			unless npc.nil?
				draw_id = db[:bag].count
				@db[:tags] << {:draw_id => draw_id, :npc_name => npc, :spent => false}
				@db[:tag_log] << {:draw_id => draw_id, :change_type => 'draw', :npc_name => npc}
				@db[:bag].filter(:draw_id => draw_id).update(:is_drawn => true)
			end
		end
	end

	# This takes a hash like the following:
	#
	# { "NPC 1" => ['Draw 1','Draw 2','Draw 3'], "NPC 2" => ['Draw 4', 'Draw 5'] }
	#
	# The NPCs must already exist (they will not be created).
	# This is transactional, so if any operation fails, everything done thus far is reversed.
	#
	def add_event_draws(eventdraws, event = @event_name)
		@db.transaction do
			edraws.each { |npc, draws|
				draws.each do |draw|
					self.add_tag(draw, npc, event)
				end
			}
		end
	end
end

