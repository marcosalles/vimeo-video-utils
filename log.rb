require "logger"

class Log
	def self.logger
		if @logger.nil?
		 	@logger = Logger.new("../download.log")
			@logger.formatter = proc do |severity, datetime, progname, msg|
			  "#{datetime.utc.strftime("%Y.%m.%d %T")}: #{msg}\n"
			end
		end
		@logger
	end
end
