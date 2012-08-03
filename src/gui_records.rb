require 'rubygems'
require 'Qt'

class RecordsTab < Qt::Widget
	def initialize(parent, database)
		super(parent)

		@database = database
		@parent   = parent

		#
		# Define objects
		#
		@layout = Qt::GridLayout.new(self)

		@npc_active = Qt::ComboBox.new(self)
		@npc_recipient = Qt::ComboBox.new(self)
		@npc_owned_tags = Qt::ListWidget.new(self)
		@button_spend = Qt::PushButton.new("Spend",self)

		@npc_log = Qt::TextEdit.new('',self)
		@npc_log.readOnly = true
		@npc_log.acceptRichText = false
		gb_npc_log = Qt::GroupBox.new("NPC Log",self)
		layout_npc_log = Qt::VBoxLayout.new(gb_npc_log)

		@button_unspend = Qt::PushButton.new("Unspend",self)
		@button_transfer = Qt::PushButton.new("Transfer",self)
		@npc_spent_tags = Qt::ListWidget.new(self)

		gb_owned_tags = Qt::GroupBox.new("Current Tags",self)
		layout_owned_tags = Qt::VBoxLayout.new(gb_owned_tags)

		gb_spent_tags = Qt::GroupBox.new("Spent Tags",self)
		layout_spent_tags = Qt::VBoxLayout.new(gb_spent_tags)

		#
		# Connect actions
		#
		@npc_active.connect(SIGNAL('currentIndexChanged(int)')) {
			self.update_tags
		}
		@button_spend.connect(SIGNAL(:clicked)) {
			self.spend
		}
		@npc_owned_tags.connect(SIGNAL('doubleClicked(QModelIndex)')) {
			self.spend
		}
		@button_unspend.connect(SIGNAL(:clicked)) {
			self.unspend
		}
		@npc_spent_tags.connect(SIGNAL('doubleClicked(QModelIndex)')) {
			self.unspend
		}
		@button_transfer.connect(SIGNAL(:clicked)) {
			self.transfer
		}


		#
		# Define Layout 
		#
		layout_owned_tags.add_widget(@npc_owned_tags)
		layout_spent_tags.add_widget(@npc_spent_tags)
		layout_npc_log.add_widget(@npc_log)

		@layout.add_widget(Qt::Label.new('NPC'),0,0)
		@layout.add_widget(@npc_active,0,1,1,4)
		#@layout.add_widget(Qt::Label.new('Transfer To'),1,0)
		#@layout.add_widget(@npc_recipient,1,1,1,4)
		@layout.add_widget(gb_owned_tags, 1,0,5,2)
		@layout.add_widget(@button_spend,1,2)
		@layout.add_widget(@button_unspend,2,2)
		@layout.add_widget(@button_transfer,3,2)
		@layout.add_widget(@npc_recipient,4,2)
		@layout.add_widget(gb_spent_tags, 1,3,5,2)
		@layout.add_widget(gb_npc_log,6,0,1,5)

		@layout.setRowStretch(5,7)
		@layout.setRowStretch(6,3)


		self.update
	end

	def update
		@npc_active.clear
		@npc_recipient.clear

		@npc_active.add_items get_npc_list
		@npc_recipient.add_items get_npc_list
		
		self.update_tags
	end

	def update_tags
		@npc_owned_tags.clear
		@npc_owned_tags.add_items(
		     @database.lookup_npc_tags(npc_name, false)
		)
		
		@npc_spent_tags.clear
		@npc_spent_tags.add_items(
		     @database.lookup_npc_tags(npc_name, true)
		)

		@npc_log.plainText = @database.lookup_log_for_npc(npc_name)
	end

	def spend
		@database.spend_nth_tag(npc_name, @npc_owned_tags.current_row)
		self.update_tags
		@parent.update_others(:records)
	end

	def unspend
		@database.unspend_nth_tag(npc_name, @npc_spent_tags.current_row)
		self.update_tags
		@parent.update_others(:records)
	end

	def transfer
		@database.transfer_nth_tag(npc_name, target_npc_name, @npc_owned_tags.current_row)
		self.update_tags
		@parent.update_others(:records)
	end

	# Local lookup functions:
	def npc_name
		@npc_active.current_text
	end
	def target_npc_name
		@npc_recipient.current_text
	end

	def get_npc_list
		@database.get_npc_list
	end

	private :get_npc_list
end

if __FILE__ == $0
	class TestDatabase
		def get_npc_list
			['Test NPC 1', 'Test NPC 2']
		end
	end
	require_relative 'database'
	class TestRecords < Qt::Widget
		attr_reader :database
		def initialize
			super(nil)
			#@database = TestDatabase.new()
			@database = GrabBagDatabase.new()
			layout = Qt::VBoxLayout.new(self)
			layout.add_widget(RecordsTab.new(self))
		end
	end
	app = Qt::Application.new ARGV
	frame = TestRecords.new
	frame.show
	app.exec
end
