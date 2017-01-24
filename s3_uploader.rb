# encoding: utf-8

class S3Uploader
	require "aws-sdk"

	def initialize
		@client = Aws::S3::Client.new
	end

	def upload file, fileName, bucket
		@client.put_object(
			body: file,
			bucket: bucket,
			key: fileName
		)
	end
end
