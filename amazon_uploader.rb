# encoding: utf-8

class AmazonUploader
	require "aws-sdk"
	require "fileutils"
	require_relative "configs"
	require_relative "s3_uploader"
	require_relative "glacier_uploader"

	def initialize
		Aws.config.update({
			region: Configs.region,
			credentials: Aws::Credentials.new(Configs.awsId, Configs.awsSecret)
		})

		@uploader = S3Uploader.new if Configs.storageUnit == "s3"
		@uploader = GlacierUploader.new if Configs.storageUnit == "glacier"
	end

	def uploadAllFiles
		dir = "#{Configs.downloadDirectory}/"
		files = Dir.glob("#{dir}**/*").select{ |e| File.file? e }
		files.each do |originalFile|
			file = originalFile.gsub("#{dir}", "")
			# @uploader.upload IO.binread(originalFile), file
		end
	end

	def upload file, fileName
		@uploader.upload file, fileName
	end
end
