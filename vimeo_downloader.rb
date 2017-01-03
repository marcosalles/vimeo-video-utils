# encoding: utf-8

class VimeoDownloader
	require "net/http"
	require "net/https"
	require "open-uri"
	require "fileutils"
	require_relative "configs"
	# require_relative "albums"
	require_relative "album_parser"
	# require_relative "videos"
	require_relative "video_parser"
	require_relative "log"

	def initialize
		@host = "https://api.vimeo.com"
		@userId = Configs.userId
		@secret = Configs.userSecret
		@root = Configs.downloadDirectory
		@log = Log.logger
	end

	def downloadVideo courseName, videoId, link
		begin
			@log.info "  #{Thread.current[:id]}>> Downloading video[#{videoId}] with quality[#{link[:quality]}] and fileSize[#{link[:size]/(1024*1024)}Mb]."
			ext = link[:uri].downcase.strip.gsub(" ", "-").gsub(/.*\./, "")
			dirName = "#{@root}/#{courseName}"
			fileName = "#{videoId}-#{link[:quality]}.#{ext}"
			path = "#{dirName}/#{fileName}"
			if link[:size] == File.size?(path)
				@log.info "  #{Thread.current[:id]}>> File already downloaded: #{path}"
				return true
			end
			FileUtils::mkdir_p dirName
			download = open(link[:uri])
			@log.info "  #{Thread.current[:id]}>> Downloaded #{path}"
			IO.copy_stream(download, path)
			return true
		rescue
			return false
		end
	end

	def getVideoInfo videoId
		VideoParser.videoAsJson(requestWithPath("/users/#{@userId}/videos/#{videoId}"))
		# VideoParser.videoAsJson(Videos.one)
	end

	def getAlbumVideos albumId, page
		VideoParser.collectionAsJson(requestWithPath("/albums/#{albumId}/videos", page))
	end

	def getUserAlbums page
		AlbumParser.collectionAsJson(requestWithPath("/users/#{@userId}/albums", page))
	end

	private
	def uriWithPath path, page
		uri = "#{@host}#{path}?per_page=100"
		uri += "&page=#{page}" unless page.nil?
		URI.parse(uri)
	end

	def requestWithPath path, page = nil
		uri = uriWithPath path, page
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		@log.info "  #{Thread.current[:id]}>> Making request to [#{uri.to_s}].."
		request = Net::HTTP::Get.new(uri.to_s)
		request.add_field "Authorization", "bearer #{@secret}"
		http.request request
	end

end
