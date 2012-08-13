require 'rubygems'
require 'Qt'
require 'net/smtp'


class Emailer < Qt::Widget
	attr :config
	@@password = ""
	
	# TODO: Store these in the database and load them here
	@@db_init = false
	@@save_password = false
	@@name = ''
	@@address = ''
	@@smtp_host = ''
	@@smtp_port = 465
	@@smtp_domain = ''
	@@smtp_user = ''

	def initialize(app, npc, database, type_of_email)
		super(nil)
		@app = app
		@database = database

		unless @@db_init
			self.db_import
		end
		
		# TODO: A message template should be stored in the database, too:
		message = case type_of_email
		when :event
			"#{npc},\r\n\r\nYour draws were: \r\n\r\n   - #{@database.lookup_npc_draws(npc).join("\r\n   - ")}\r\n\r\nThese tags can be traded to other players or you can redeem them yourself. Any tag can be redeemed for 25 goblins instead. Let me know what you decide to do. Our NPC Rewards are described at www.neroindy.com/npc-rewards.html\r\n\r\nThanks,\r\nCorey T Kump\r\nNERO Indiana"
		when :full_records
			"#{npc},\r\n\r\nYou have the following unspent tags:\r\n\r\n   - #{@database.lookup_npc_tags(npc,false).join("\r\n   - ")}\r\n\r\nThese tags can be traded to other players or you can redeem them yourself. Any tag can be redeemed for 25 goblins instead. Let me know what you decide to do. Our NPC Rewards are described at www.neroindy.com/npc-rewards.html\r\n\r\nThanks,\r\nCorey T Kump\r\nNERO Indiana"
		end

		subject = case type_of_email
			when :event
				"#{@@name} #{@database.event_name} Grab Bag Draws"
			when :full_records
				"#{@@name} Unspent Grab Bag Tags"
		end

		#
		# Define objects
		#
		@layout = Qt::VBoxLayout.new(self)
		defaults = {
			'Sender Name' => @@name,
			'Sender Address' => @@address,
			'SMTP Host' => @@smtp_host,
			'SMTP Port' => @@smtp_port,
			'SMTP Domain' => @@smtp_domain,
			'SMTP User' => @@smtp_user,
			'Recipient Name' => npc,
			'Recipient Email' => @database.lookup_npc_email(npc),
			'Subject' => subject,
			'Body' => message,
			'Password' => @@password,
			'Save Password' => @@save_password
		}
		@config = Hash.new()

		#
		# Connect actions
		#

		button_send = Qt::PushButton.new('Send Email',self)
		button_send.connect(SIGNAL(:clicked)) {
			begin
				self.send_email
			rescue
				@app.dialog("Email Failed","Email failed to send")
			end
			@app.dialog("Email Sent","Email sent successfully")
			self.close
		}
		button_save_settings = Qt::PushButton.new('Save Settings',self)
		button_save_settings.connect(SIGNAL(:clicked)) {
			db_export
		}

		#
		# Define layout
		#

		form = Qt::FormLayout.new()

		defaults.each do |label, val|
			@config[label] = case label
							 when "Body"
								 te = Qt::TextEdit.new()
								 te.set_text(val.to_s)
								 te
							 when "Save Password"
								 cb = Qt::CheckBox.new()
								 cb.setChecked val
								 cb
							 else
								 Qt::LineEdit.new(val.to_s)
			end
			@config[label].input_mask = '999' if val.is_a? Integer
			@config[label].echo_mode = Qt::LineEdit::Password if label == "Password"
			form.add_row(Qt::Label.new(label,self), @config[label])
		end


		@layout.add_layout(form)
		@layout.add_widget(button_send)
		@layout.add_widget(button_save_settings)
	end

	def db_import
		@@db_init = true
		email_info = @database.lookup_email_info
		unless email_info.nil?
			@@name = email_info[:name]
			@@address = email_info[:address]
			@@smtp_host = email_info[:smtp_host]
			@@smtp_port = email_info[:smtp_port]
			@@smtp_domain = email_info[:smtp_domain]
			@@smtp_user = email_info[:smtp_user]
			@@save_password = email_info[:save_password]
		end
	end

	def db_export
		if @config['Save Password'].is_checked
			@@password = @config['Password'] 
			@@save_password = true
		else
			@@password = ""
			@@save_password = false
		end


		@@name = @config[ 'Sender Name'].text
		@@address = @config['Sender Address'].text
		@@smtp_host = @config['SMTP Host'].text
		@@smtp_port = @config['SMTP Port'].text.to_i
		@@smtp_domain = @config['SMTP Domain'].text
		@@smtp_user = @config['SMTP User'].text

		@database.store_email_info @@name, @@address, @@smtp_host, @@smtp_port, @@smtp_domain, @@smtp_user, @@save_password
		
	end

	def send_email
		db_export

		self.send(@config['Subject'].text,
					  @config['Recipient Name'].text,
					  @config['Recipient Email'].text,
					  @config['Body'].plainText,
					  @config['Password'].text)
	end

	def send subject, recipient_name, recipient_address, body, password
		#The subject and the message
		t = Time.now

		#The date/time should look something like: Thu, 03 Jan 2006 12:33:22 -0700
		msg_date = t.strftime("%a, %d %b %Y %H:%M:%S +0800")

		#Compose the message for the email
		msg = <<END_OF_MESSAGE
Date: #{msg_date}
From: #{@name} <#{@from_mail}>
To: #{recipient_name} <#{recipient_address}>
Subject: #{subject}
  
#{body}
END_OF_MESSAGE

		smtp = Net::SMTP.new(@smtp_host, @smtp_port)
		smtp.enable_ssl
		begin
			smtp.start(@smtp_domain, @smtp_user, password, :login)

			smtp.send_message msg, @smtp_user, recipient_address
		rescue Exception => e
			puts e
		ensure
			smtp.finish
		end
	end

end


if __FILE__ == $0
	require_relative 'database'
	class TestEmail < Qt::Widget
		def initialize
			super(nil)
			db = GrabBagDatabase.new
			layout = Qt::VBoxLayout.new(self)
			layout.add_widget(Emailer.new(self, 'Amber Gill', db, :full_records))
		end
	end
	app = Qt::Application.new ARGV
	frame = TestEmail.new()
	#frame = ConfigTab.new(TestConfig.new)
	frame.show
	app.exec
end
