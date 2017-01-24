# encoding: utf-8

class AmazonDAO
	require_relative "log"
	require_relative "configs"
	require_relative "amazon_uploader"

	def initialize
		@log = Log.logger
		@s3 = AmazonUploader.new Configs.awsId, Configs.awsSecret, Configs.awsRegion, "S3"
		@glacier = AmazonUploader.new Configs.awsId, Configs.awsSecret, Configs.awsRegion, "Glacier"
	end

	def uploadToS3 absolutePath, fileName, bucket
		@log.info "Uploading #{fileName} to S3.."
		@s3.upload absolutePath, fileName, bucket
		@log.info "Uploaded #{fileName} successfully to S3!"
	end

	def uploadToGlacier absolutePath, fileName, vault
		@log.info "Uploading #{fileName} to Glacier.."
		@glacier.upload absolutePath, fileName, vault
		@log.info "Uploaded #{fileName} successfully do Glacier!"
	end

end