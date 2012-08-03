require 'rubygems'
require 'Qt'

# Other Project Files
require_relative 'database'
require_relative 'gui_draw'
require_relative 'gui_records'
require_relative 'gui_npc_lookup'
require_relative 'gui_events'

class GrabBagGUI < Qt::Widget
	attr_reader :database

	def initialize
		super

		@database = GrabBagDatabase.new
		self.set_window_title

		@layout = Qt::GridLayout.new(self)

		@tabs = {}
		#@tabs[:config]  = ConfigTab.new(self,@database)
		@tabs[:events]   = EventTab.new(    self, @database)
		@tabs[:draw]     = DrawTab.new(     self, @database)
		@tabs[:records]  = RecordsTab.new(  self, @database)
		@tabs[:npcs]     = NPCLookupTab.new(self, @database)
		
		@tabbar = Qt::TabWidget.new(self)
		#@tabbar.add_tab(@tabs[:config],  'Config')
		@tabbar.add_tab(@tabs[:events],  'Events')
		@tabbar.add_tab(@tabs[:draw],    'Draw')
		@tabbar.add_tab(@tabs[:records], 'Records')
		@tabbar.add_tab(@tabs[:npcs],    'NPC Lookup')

		@layout.add_widget(@tabbar)
	end

	def set_window_title
		self.window_title = "NERO Indy Grab Bag - #{@database.event_name}"
	end

	def update
		@tabs.each_value { |tab| tab.update }
	end

	def update_only tab
		@tabs[tab].update if @tabs.has_key? tab
	end

	def update_others me
		@tabs.each { |key, tab|
			tab.update unless key == me
		}
	end

	def dialog(title,text)
		failnotice = Qt::Dialog.new()
		failnotice.modal = true
		layout = Qt::VBoxLayout.new(failnotice)
		layout.add_widget(Qt::Label.new(text))
		ok_button = Qt::PushButton.new("OK",failnotice)
		ok_button.connect(SIGNAL(:clicked)) {
			failnotice.close
		}
		layout.add_widget(ok_button)
		failnotice.window_title = title
		failnotice.show
	end
end

if __FILE__ == $0
	app = Qt::Application.new ARGV
	frame = GrabBagGUI.new
	frame.show
	app.exec
end
