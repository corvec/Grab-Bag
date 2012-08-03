require 'rubygems'
require 'Qt'

class ConfigGUI < Qt::Widget
	attr :config

	def initialize(parent, database, to_update = nil)
		super(parent)

		@database = database
		@to_update = to_update

		#
		# Define objects
		#
		@layout = Qt::VBoxLayout.new(self)
		defaults = {
			'Event' => @database.event_name, # Default to modify current event
			'Content File' => @database.gen_file,
			'NPC Count' => @database.npc_count,
			'Max Draws Per NPC' => @database.max_draws
		}
		@config = Hash.new()

		#
		# Connect actions
		#

		button_generate = Qt::PushButton.new('Generate',self)
		button_generate.connect(SIGNAL(:clicked)) {
			self.generate_new_grabbag
		}

		#
		# Define layout
		#

		form = Qt::FormLayout.new()

		defaults.each do |label, val|
			@config[label] = Qt::LineEdit.new(val.to_s)
			@config[label].input_mask = '999' if val.is_a? Integer
			form.add_row(Qt::Label.new(label,self), @config[label])
		end


		@layout.add_layout(form)
		@layout.add_widget(button_generate)
	end

	def generate_new_grabbag
		@database.gen_file  = @config['Content File'].text
		@database.max_draws = @config['Max Draws Per NPC'].text.to_i
		@database.npc_count = @config['NPC Count'].text.to_i
		@database.event_name= @config['Event'].text
		
		total_draws = @database.npc_count * @database.max_draws

		@database.initialize_bag(total_draws)

		@to_update.update unless @to_update.nil?
		self.close
	end


end


if __FILE__ == $0
	class TestConfig < Qt::Widget
		def initialize
			super(nil)
			db = GrabBagDatabase.new
			layout = Qt::VBoxLayout.new(self)
			layout.add_widget(ConfigTab.new(self,db))
		end
	end
	app = Qt::Application.new ARGV
	frame = TestConfig.new()
	#frame = ConfigTab.new(TestConfig.new)
	frame.show
	app.exec
end
