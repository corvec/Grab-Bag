#!/usr/bin/env ruby

require_relative 'gui'

if __FILE__ == $0
	if not ARGV.include? "--test"
		app = Qt::Application.new ARGV
		frame = GrabBagGUI.new
		frame.show
		app.exec
	else
		test
	end
end
