# encoding: utf-8

class S3Uploader
	require "aws-sdk"
	require "fileutils"
	require_relative "configs"

	def initialize
		@client = Aws::S3::Client.new
	end

	def upload file, fileName
		@client.put_object(
			body: file,
			bucket: Configs.storageRoot,
			key: fileName
		)
	end
end
