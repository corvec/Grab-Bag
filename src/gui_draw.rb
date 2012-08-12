require_relative "gui_email"

class DrawTab < Qt::Widget
	def initialize(parent, database)
		super(parent)

		@parent = parent
		@database = database

		#
		# Define objects
		#
		@layout = Qt::GridLayout.new(self)

		@npc_name = Qt::ComboBox.new(self)

		@button_draw_once = Qt::PushButton.new("Draw Once", self)
		@button_draw_x = Qt::PushButton.new("Draw", self)
		@button_copy = Qt::PushButton.new("Copy to Clipboard",self)
		@button_email = Qt::PushButton.new("Email Draws",self)
		@x_to_draw = Qt::LineEdit.new("4",self)
		@list_of_draws = Qt::ListWidget.new(self)
		@log_widget = Qt::TextEdit.new(self)
		@log_widget.acceptRichText = false
		@log_widget.tabChangesFocus = true
		@log_widget.tabStopWidth = 20

		#
		# Connect Actions
		#
		@button_draw_once.connect(SIGNAL(:clicked)) {
			self.draw(@npc_name.current_text, 1)
		}

		@button_draw_x.connect(SIGNAL(:clicked)) {
			self.draw(@npc_name.current_text, @x_to_draw.text.to_i)
		}

		@button_copy.connect(SIGNAL(:clicked)) {
			Qt::Application.clipboard.set_text(@database.lookup_npc_draws(@npc_name.current_text).join("\r"))
		}

		@button_email.connect(SIGNAL(:clicked)) {
			self.email
		}

		@npc_name.connect(SIGNAL('currentIndexChanged(int)')) {
			self.update_listofdraws
		}

		@list_of_draws.connect(SIGNAL('doubleClicked(QModelIndex)')) {
			undrawn = @database.undraw(@npc_name.current_text, @list_of_draws.current_row)
			unless undrawn
				@parent.dialog("Error with Undraw","Could not remove item, as it has been affected since it was drawn.")
			else
				@parent.update_others :draw
				self.update_listofdraws
			end
		}

		#
		# Define Layout
		#

		gb_list_of_draws = Qt::GroupBox.new("NPC's Draws This Event",self)
		layout_list = Qt::VBoxLayout.new(gb_list_of_draws)
		layout_list.add_widget(@list_of_draws)

		gb_log = Qt::GroupBox.new("Event Log",self)
		layout_log = Qt::VBoxLayout.new(gb_log)
		layout_log.add_widget(@log_widget)


		@layout.add_widget(Qt::Label.new('NPC'),0,0)
		@layout.add_widget(@npc_name,0,1,1,2)
		@layout.add_widget(gb_list_of_draws,0,3,4,1)
		@layout.add_widget(@button_draw_once,1,0)
		@layout.add_widget(@button_draw_x,1,1)
		@layout.add_widget(@x_to_draw,1,2)
		@layout.add_widget(@button_copy,2,0,1,3)
		@layout.add_widget(@button_email,3,0,1,3)
		@layout.add_widget(gb_log,4,0,1,5)

		@layout.setRowStretch(3,5)
		@layout.setRowStretch(4,5)

		#
		# Update
		#
		self.update
	end

	def draw(npc_name, num_of_draws)
		begin
			@database.draw(npc_name, @database.event_name, num_of_draws)
		rescue Exception => e
			@parent.dialog('Cannot Draw',e.message)
		else
			self.update_listofdraws()
		end
	end

	def email
		emailer = Emailer.new(@parent, @npc_name.current_text,@database,:event)
		emailer.show
	end

	def update
		@npc_name.clear
		@npc_name.add_items(@database.get_npc_list)

		self.update_listofdraws
	end

	def update_listofdraws
		val = @database.lookup_log_for_event
		@log_widget.plainText = val

		@list_of_draws.clear
		@list_of_draws.add_items(@database.lookup_npc_draws(@npc_name.current_text))
	end

end
