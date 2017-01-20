# encoding: utf-8

class GlacierUploader
	require "aws-sdk"
	require_relative "configs"

	def initialize
		@client = Aws::Glacier::Client.new
	end

	def upload file, fileName
		@client.upload_archive(
			body: file,
			vault_name: Configs.storageRoot,
			archive_description: fileName
		)
	end
end
