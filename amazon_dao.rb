# encoding: utf-8

class AmazonDAO
	require_relative "configs"
	require_relative "amazon_uploader"

	def initialize
		@s3 = AmazonUploader.new Configs.awsId, Configs.awsSecret, Configs.awsRegion, "S3"
		@glacier = AmazonUploader.new Configs.awsId, Configs.awsSecret, Configs.awsRegion, "Glacier"
	end

	def uploadToS3 absolutePath, fileName, bucket
		@s3.upload absolutePath, fileName, bucket
	end

	def uploadToS3 absolutePath, fileName, vault
		@glacier.upload absolutePath, fileName, vault
	end

end