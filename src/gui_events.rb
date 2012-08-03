require 'rubygems'
require 'Qt'

require_relative 'gui_config'

class EventTab < Qt::Widget
	attr :config

	def initialize(parent, database)
		super(parent)

		@database = database
		@parent   = parent

		#
		# Define objects
		#
		@layout = Qt::GridLayout.new(self)

		button_newevent        = Qt::PushButton.new('Add Event',self)
		@cbo_eventlist         = Qt::ComboBox.new(self)
		@lbl_event_total_draws = Qt::Label.new("0",self)
		@lbl_event_left_draws  = Qt::Label.new("0",self)
		@spacer                = Qt::Label.new('',self)

		@npc_widgets = []
		@spacer_vert = 1

		#
		# Connect Actions
		#
		button_newevent.connect(SIGNAL(:clicked)) {
			config = ConfigGUI.new(nil,@database, self)
			config.show
		}
		@cbo_eventlist.connect(SIGNAL('currentIndexChanged(int)')) {
			unless @updating
				@database.event_name = @cbo_eventlist.current_text
				self.update_event_data
				@parent.update_only(:draw)
				@parent.set_window_title
			end
		}

		#
		# Define layout
		#
		gb_event_data  = Qt::GroupBox.new("Event Data", self)
		event_layout   = Qt::GridLayout.new(gb_event_data)
		event_layout.add_widget(Qt::Label.new('Total Draws',self),0,0)
		event_layout.add_widget(Qt::Label.new('Still in Bag',self),1,0)
		event_layout.add_widget(@lbl_event_total_draws,0,1)
		event_layout.add_widget(@lbl_event_left_draws,1,1)
		gb_npc_data    = Qt::GroupBox.new("NPC Data",self)
		@npcs_layout   = Qt::GridLayout.new(gb_npc_data)
		event_layout.add_widget(gb_npc_data,2,0,1,2)
		event_layout.setRowStretch(2,10)

		@npcs_layout.add_widget(Qt::Label.new('<b>NPC Name</b>',self),0,0)
		@npcs_layout.add_widget(Qt::Label.new('<b>Draws</b>',self),0,1)
		@npcs_layout.add_widget(Qt::Label.new('<b>Redeemed</b>',self),0,2)
		@npcs_layout.add_widget(Qt::Label.new('<b>Transferred</b>',self),0,3)
		@npcs_layout.add_widget(@spacer,1,0)

		@layout.add_widget(button_newevent,0,0,1,2)
		@layout.add_widget(Qt::Label.new('Select Event',self),1,0)
		@layout.add_widget(@cbo_eventlist,1,1)
		@layout.add_widget(gb_event_data,2,0,1,2)

		@layout.setColumnStretch(1,1)

		#
		# Fill with proper values
		#
		self.update
	end

	def update
		@updating = true

		@cbo_eventlist.clear
		event_list = @database.get_event_list
		unless event_list.empty?
			@cbo_eventlist.add_items(event_list)
			@cbo_eventlist.current_index = event_list.index(@database.event_name)
			self.update_event_data
		end

		@updating = false
	end

	def update_event_data
		@updating = true

		@lbl_event_total_draws.text = @database.lookup_event_total.to_s
		@lbl_event_left_draws.text = @database.lookup_event_left.to_s

		@npcs_layout.setRowStretch(@spacer_vert,0)
		@npcs_layout.remove_widget(@spacer)

		@npc_widgets.each { |widget|
			@npcs_layout.remove_widget(widget)
			widget.close
		}

		npc_list = @database.lookup_npcs_at_event
		npc_list.each_with_index{ |npc, i|
			lbl_name  = Qt::Label.new(npc,self)
			lbl_drew  = Qt::Label.new(@database.lookup_npc_draw_count(npc).to_s,self)
			lbl_spent = Qt::Label.new(@database.lookup_npc_spend_count(npc).to_s,self)
			lbl_trans = Qt::Label.new(@database.lookup_npc_transfer_count(npc).to_s,self)
			@npcs_layout.add_widget(lbl_name, 1+i, 0)
			@npcs_layout.add_widget(lbl_drew, 1+i, 1)
			@npcs_layout.add_widget(lbl_spent, 1+i, 2)
			@npcs_layout.add_widget(lbl_trans, 1+i, 3)
			@npc_widgets.concat([lbl_name,lbl_drew,lbl_spent,lbl_trans])
		}

		@spacer_vert = npc_list.count + 1
		@npcs_layout.add_widget(@spacer,@spacer_vert,0)
		@npcs_layout.setRowStretch(@spacer_vert,10)

		@updating = false
	end

end


if __FILE__ == $0
	class TestEvents < Qt::Widget
		def initialize
			super(nil)
			db = GrabBagDatabase.new
			layout = Qt::VBoxLayout.new(self)
			layout.add_widget(EventTab.new(self,db))
		end
	end
	app = Qt::Application.new ARGV
	frame = TestEvents.new()
	#frame = EventTab.new(TestConfig.new)
	frame.show
	app.exec
end

