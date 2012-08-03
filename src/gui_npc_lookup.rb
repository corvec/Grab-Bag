class NPCLookupTab < Qt::Widget
	def initialize(parent, database)
		super(parent)

		@parent   = parent
		@database = database

		#
		# Define objects
		#

		@layout = Qt::GridLayout.new(self)

		@lookup = Qt::ComboBox.new(self)

		@npc_name = Qt::LineEdit.new(self)
		@npc_chapter = Qt::LineEdit.new(self)
		@npc_email = Qt::LineEdit.new(self)

		button_add_npc = Qt::PushButton.new("Add or Update NPC", self)
		button_rename_npc = Qt::PushButton.new("Rename NPC", self)
		button_delete_npc = Qt::PushButton.new("Delete NPC", self)

		#
		# Connect actions
		#

		@lookup.connect(SIGNAL('currentIndexChanged(int)')) {
			npc = @lookup.current_text
			@npc_name.text    = npc
			if npc == '' or npc.nil?
				@npc_chapter.text = ''
				@npc_email.text = ''
			else
				@npc_chapter.text = @database.lookup_npc_chapter(npc)
				@npc_email.text = @database.lookup_npc_email(npc)
			end
		}

		button_add_npc.connect(SIGNAL(:clicked)) {
			@database.add_or_update_npc(@npc_name.text, @npc_chapter.text, @npc_email.text)
			@parent.update
		}
		button_rename_npc.connect(SIGNAL(:clicked)) {
			begin
				new_name = @npc_name.text
				@database.rename_npc(@lookup.current_text, new_name)
				@parent.update
				@lookup.current_index = 1 + @database.get_npc_list.index(new_name)
			rescue
				@parent.dialog("Error with Rename","Could not rename NPC as he or she has already drawn grab bag items")
			end
		}
		button_delete_npc.connect(SIGNAL(:clicked)) {
			begin
				# puts "Attempting to delete NPC: '#{@lookup.current_text}' (#{@npc_name.text})"
				if @lookup.current_text != "" and @lookup.current_text == @npc_name.text
					@database.delete_npc(@lookup.current_text) 
					@parent.update
				else
					@parent.dialog("Error with Delete","Could not delete NPC: Either an NPC is not selected or it is ambiguous as to which NPC you wish to delete.")
				end
			rescue
				@parent.dialog("Error with Delete","Could not delete NPC as he or she has already drawn grab bag items")
			end
		}

		#
		# Define layout
		#
		gb_details = Qt::GroupBox.new(self)
		details_layout = Qt::FormLayout.new(gb_details)
		details_layout.add_row(Qt::Label.new("Name"),@npc_name)
		details_layout.add_row(Qt::Label.new("Chapter"),@npc_chapter)
		details_layout.add_row(Qt::Label.new("Email"),@npc_email)
		gb_details.set_layout(details_layout)

		@layout.add_widget(Qt::Label.new('Look up'),0,0)
		@layout.add_widget(@lookup,0,1)
		@layout.add_widget(gb_details,1,0,1,2)
		@layout.add_widget(button_add_npc,2,0,1,2)
		@layout.add_widget(button_rename_npc,4,0)
		@layout.add_widget(button_delete_npc,4,1)


		self.update
	end

	def update
		@lookup.clear
		@lookup.add_items([''])
		@lookup.add_items(@database.get_npc_list)
	end

end
