class Log
	require "logger"
	require_relative "configs"

	def self.logger
		if @logger.nil?
		 	@logger = Logger.new(Configs.logFile)
			@logger.formatter = proc do |severity, datetime, progname, msg|
			  "#{datetime.utc.strftime("%Y.%m.%d %T")} - #{severity[0,3]}: #{msg}\n"
			end
		end
		@logger
	end

	def info message
		log message, "inf"
	end
	def error message
		log message, "err"
	end
	def debug message
		log message, "deb"
	end

	def log message, severity
		puts "#{severity}: #{message}"
	end
end
