require_relative 'database'
	def test
		db = GrabBagDatabase.new()
		event = "December 2011"
		csv = "grab_bag.csv"
		max_draws = 25

		npc     = "Jacob Bissey"
		chapter = "NERO Indiana"
		email   = "dragonboy@yahoo.com"

		npc2     = "Josh Wagoner"
		chapter2 = "NERO Cincinnati"
		email2   = nil
		
		db.initialize_bag(csv,event,max_draws)


		db.add_or_update_npc(npc,chapter,email)
		db.add_or_update_npc(npc2,chapter2,email2)
		puts "Fail (lookup_npc_chapter)" if db.lookup_npc_chapter(npc) != chapter
		puts "Fail (lookup_npc_email)" if db.lookup_npc_email(npc) != email
		puts "Fail (lookup_npc_chapter on npc2)" if db.lookup_npc_chapter(npc) != chapter2
		puts "Fail (lookup_npc_email on npc2)" if db.lookup_npc_email(npc) != email2

		puts db.draw(npc,event,4).join(',')
		puts db.draw(npc2,event,2).join(',')

		puts db.db[:tags].map(:draw_id).join(',')
		puts db.db[:tags].map(:npc_name).join(',')
		puts db.db[:tags].map(:spent).join(',')

		puts db.lookup_npc_draws(npc, event).join(',')
		puts db.lookup_npc_draws(npc).join(',')
	end

	test
