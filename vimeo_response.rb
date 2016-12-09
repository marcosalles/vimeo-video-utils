class VimeoResponse
	def initialize
		@header = {}
		@body = nil
	end

	def [] key
		@header[key.downcase]
	end

	def []= key, value
		@header[key.downcase] = value
	end

	def body
		@body
	end

	def body= value
		@body = value
	end
end
