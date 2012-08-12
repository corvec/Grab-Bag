require 'net/smtp'

class Mailer



	def initialize name = 'NERO Indiana', address = 'neroindiana@gmail.com', smtp_host = 'smtp.gmail.com', smtp_domain = 'gmail.com'
		@name = name
		@address = address
		@smtp_host = smtp_host
		@smtp_port = 465
		@smtp_domain = smtp_domain
		@smtp_user = @address
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
	mail = Mailer.new
	puts "Enter your password: "
	pw = gets.chomp
	mail.send("Test Email", "Corey Kump", "Corey.Kump@gmail.com", "This is a test email.\nThis is the second line.\nThis is the third line.", pw)
end
