require 'rubygems'
require 'Qt'

class TestFrame < Qt::Widget
	attr_accessor :event

	def initialize(parent=nil)
		super(parent)
		self.do_stuff
	end

	def do_stuff
		@event = "Example Event"
		@layout = Qt::VBoxLayout.new(self)
		@layout.add_widget(Qt::Label.new(@event))
		puts @event
	end

end

if __FILE__ == $0
	app = Qt::Application.new ARGV
	frame = TestFrame.new
	frame.show
	app.exec
end
