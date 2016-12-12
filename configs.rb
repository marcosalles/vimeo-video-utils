class Configs
	def userId
		""
	end

	def userSecret
		""
	end

	def self.videoQuality
		["hd", "sd", "source"]
	end

	def self.requestThreshold
		275
	end

	def self.threadThreshold
		20
	end

	def self.downloadDirectory
		"videos"
	end
end
