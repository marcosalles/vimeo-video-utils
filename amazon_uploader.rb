# encoding: utf-8

class AmazonUploader
	require "aws-sdk"
	require "fileutils"
	require_relative "s3_uploader"
	require_relative "glacier_uploader"

	def initialize awsId, awsSecret, awsRegion, storageUnit
		Aws.config.update({
			region: awsRegion,
			credentials: Aws::Credentials.new(awsId, awsSecret)
		})

		@uploader = Object.const_get("#{storageUnit}Uploader").new
	end

	def upload absoluteFilePath, fileName, vaultOrBucket
		@uploader.upload IO.binread(absoluteFilePath), fileName, vaultOrBucket
	end

	private

	def uploadAllFilesFromTo dir, vaultOrBucket
		files = Dir.glob("#{dir}/**/*").select{ |e| File.file? e }
		files.each do |absoluteFilePath|
			fileName = absoluteFilePath.gsub("#{dir}", "")
			@uploader.upload IO.binread(absoluteFilePath), fileName, vaultOrBucket
		end
	end

end