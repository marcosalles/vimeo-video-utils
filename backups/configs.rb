# encoding: utf-8

class Configs
	def self.vimeoSecret
		""
	end

	def self.s3Quality
		["hd", "sd", "source", "mobile"]
	end

	def self.glacierQuality
		["source", "hd", "sd", "mobile"]
	end

	def self.requestThreshold
		200
	end

	def self.threadThreshold
		20
	end

	def self.downloadDirectory
		"../downloads"
	end

	def self.awsId
		""
	end

	def self.awsSecret
		""
	end

	def self.awsRegion
		"us-east-1"
	end

	def self.storageRoot
		""
	end

	def self.logFile
		"../backup.log"
	end

	def self.uploadFiles
		false
	end

end
