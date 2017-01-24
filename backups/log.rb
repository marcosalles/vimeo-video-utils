class Log
	require "logger"
	require_relative "configs"

	def self.logger
		if @logger.nil?
			@logger = Logger.new(Configs.logFile)
			@logger.formatter = proc do |severity, datetime, progname, msg|
				timestamp = "#{datetime.utc.strftime("%Y.%m.%d %T")}"
				level = "#{severity[0,3]}"
				thread = "  >> #{Thread.current[:id]} >> " unless Thread.current[:id].nil?
				"#{timestamp} - #{level}: #{thread}#{msg}\n"
			end
		end
		@logger
	end

	def info message
		log message, "INFO"
	end
	def error message
		log message, "ERROR"
	end
	def debug message
		log message, "DEBUG"
	end

	def log message, severity
		timestamp = "#{Time.now.utc.strftime("%Y.%m.%d %T")}"
		level = "#{severity[0,3]}"
		thread = "  >> #{Thread.current[:id]} >> " unless Thread.current[:id].nil?
		puts "#{timestamp} - #{level}: #{thread}#{message}"
	end
end
