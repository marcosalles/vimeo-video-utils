# encoding: utf-8

class Configs
	def self.vimeoSecret
		""
	end

	def self.videoQuality
		return ["source", "hd", "sd", "mobile"] if self.storageUnit == "glacier"
		["hd", "sd", "source", "mobile"]
	end

	def self.requestThreshold
		275
	end

	def self.threadThreshold
		20
	end

	def self.downloadDirectory
		"../downloads/#{self.storageUnit}"
	end

	def self.awsId
		""
	end

	def self.awsSecret
		""
	end

	def self.region
		""
	end

	def self.storageUnit
		"s3"
		# "glacier"
	end

	def self.storageRoot
		""
	end

end
