# encoding: utf-8

class VimeoDAO
	require "net/http"
	require "net/https"
	require "open-uri"
	require "fileutils"
	require_relative "log"
	require_relative "configs"
	require_relative "video_parser"

	def initialize
		@log = Log.logger
		@root = Configs.downloadDirectory
		@secret = Configs.vimeoSecret
	end

	def getVideoInfo id
		VideoParser.videoAsJson requestTo(uriWithPath("/me/videos/#{id}"))
	end

	def downloadForS3 video, info
		Configs.s3Quality.each do |s3Quality|
			info[:downloadLinks].each do |link|
				if s3Quality.eql? link[:quality]
					return downloadVideo video, link
				end
			end
		end
		return nil
	end

	def downloadForGlacier video, info
		Configs.glacierQuality.each do |glacierQuality|
			info[:downloadLinks].each do |link|
				if glacierQuality.eql? link[:quality]
					return downloadVideo video, link
				end
			end
		end
		return nil
	end


	private

	def fileNameFor video, link
		ext = link[:uri].downcase.strip.gsub(" ", "-").gsub(/.*\./, "")
		"#{@root}/#{video[:path]}/#{video[:id]}-#{link[:quality]}.#{ext}"
	end

	def downloadVideo video, link
		begin
			path = fileNameFor(video, link)
			@log.info "Downloading video[#{video[:id]}] with quality[#{link[:quality]}] and fileSize[#{link[:size]/(1024*1024)}Mb]."
			if link[:size] == File.size?(path)
				@log.info "File already downloaded: #{path}"
				return path
			end
			FileUtils::mkdir_p "#{@root}/#{video[:path]}"
			download = open(link[:uri])
			@log.info "Downloaded #{path}"
			IO.copy_stream(download, path)
			return path
		rescue
			@log.error "*** Download for #{path} failed!"
		end
		return nil
	end

	def uriWithPath path, page = nil
		uri = "https://api.vimeo.com#{path}"
		uri += "?per_page=100&page=#{page}" unless page.nil?
		URI.parse(uri)
	end

	def requestTo uri
		http = Net::HTTP.new uri.host, uri.port
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		@log.info "Making request to [#{uri.to_s}].."
		request = Net::HTTP::Get.new uri.to_s
		request.add_field "Authorization", "bearer #{@secret}"
		http.request request
	end

end
