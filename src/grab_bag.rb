#!/usr/bin/env ruby

# grab_bag.rb
# This program simulates a grab bag based off of a provided csv file
# On the command line:
# ruby grab_bag.rb -n [number of draws] -f [filepath]

require 'rubygems'
require 'optparse'
require 'fastercsv'

class GrabBag
	def initialize options
		@options = options

		@data = FasterCSV.read(@options[:csv])

		# Count up the number of absolute and repeatable draws:
		absolute = 0
		repeated = 0
		@data[1..-1].each do |row|
			if row[2] == "TRUE"
				absolute += row[1].to_i
			else
				repeated += row[1].to_i
			end
		end


		# Generate the bag:
		cycles = 1 + ((@options[:total_draws] - absolute) / repeated).floor
		@bag = []

		@data[1..-1].each do |row|
			num = row[1].to_i
			num *= cycles if row[2] != "TRUE"
			num.times do
				@bag << row[0]
			end
		end
	end

	def draw num = 1
		draws = []
		num.times do
			i = rand(@bag.length)
			draws << @bag[i]
			@bag.delete_at(i)
		end
		return draws
	end
end



if __FILE__ == $0
	options = {}
	OptionParser.new do |opts|
		opts.banner = "Usage: ruby fth2pi.rb -s [SOURCEFILE] -o [OUTPUTFILE]"

		opts.separator ""
		opts.separator "Specific options:"

		opts.on("-f", "--file FILE", "Set csv file") do |csv|
			options[:csv] = csv
		end
		opts.on("-d","--draws N", "Set number of draws per NPC") do |n|
			options[:draws] = n.to_i
		end
		opts.on("-n","--npcs N", "Set total number of NPCs") do |n|
			options[:npcs] = n.to_i
		end
		opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
			options[:verbose] = v
		end
		opts.on_tail("-h", "--help", "Show this message") do
			puts opts
			exit
		end
		opts.on_tail("--version", "Show version") do
			puts "grab_bag.rb version 0.1"
			exit
		end
	end.parse!
	if options.empty?
		exit
	end
	options[:draws] = 4 unless options.has_key? :draws
	options[:npcs] = 5 unless options.has_key? :npcs
	options[:total_draws] = options[:draws] * options[:npcs]

	#srand
	grab_bag = GrabBag.new options

	# Drawing Loop
	options[:npcs].times do |npc_index|
		#puts "NPC #{npc_index}" if options[:verbose]
		puts "#{options[:verbose] ? "NPC #{npc_index}: " : ''}#{grab_bag.draw(options[:draws]).join(', ')}"
	end


end
