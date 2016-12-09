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

	def initialize
		@host = "https://api.vimeo.com"
		@userId = Configs.userId
		@secret = Configs.userSecret
		@root = "files"
	end

	def downloadVideo albumName, videoId, link
		dirName = "#{@root}/#{albumName}"
		fileName = "#{videoId}-#{link[:quality]}.mp4"
		path = "#{dirName}/#{fileName}"
		if link[:size] == File.size?(path)
			puts "\tFile already downloaded: #{path}"
			return true
		end
		FileUtils::mkdir_p dirName
		download = open(link[:uri])
		puts "\tDownloaded #{path}\n"
		IO.copy_stream(download, path)
		true
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
		puts "Making request to [#{uri.to_s}]..\n"
		request = Net::HTTP::Get.new(uri.to_s)
		request.add_field "Authorization", "bearer #{@secret}"
		http.request request
	end

end
