# encoding: utf-8

class GlacierUploader
	require "aws-sdk"

	def initialize
		@client = Aws::Glacier::Client.new
	end

	def upload file, fileName, vault
		@client.upload_archive(
			body: file,
			vault_name: vault,
			archive_description: fileName
		)
	end
end
